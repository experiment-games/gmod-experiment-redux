Schema.cinematics = ix.util.GetOrCreateCommonLibrary("cinematics", nil, {
	playerScenes = {},

	REMOVE_FROM_SCENE_ID = "!REMOVE!",
})

util.AddNetworkString("ixCinematicFadeIn")
util.AddNetworkString("ixCinematicFadeOut")
util.AddNetworkString("ixCinematicFadeComplete")
util.AddNetworkString("ixCinematicSetBlackWhite")
util.AddNetworkString("ixCinematicShowText")
util.AddNetworkString("ixCinematicEnterScene")
util.AddNetworkString("ixCinematicLeaveScene")

function Schema.cinematics.GetCinematicSpawns(cinematicSpawnID)
	local spawns = {}

	for _, entity in ipairs(ents.FindByClass("exp_cinematic_spawn")) do
		if (entity:GetSequenceID() == cinematicSpawnID) then
			spawns[#spawns + 1] = entity
		end
	end

	return spawns
end

--- @param client Player
--- @param sceneID string
--- @param fadeIn? boolean|number
--- @return boolean
function Schema.cinematics.PutPlayerInScene(client, sceneID, fadeIn)
	local scene = Schema.cinematics.Find(sceneID)
	if (not scene) then
		ix.util.SchemaErrorNoHalt("Scene not found: " .. sceneID)
		return false
	end

	-- End any existing scene
	if (Schema.cinematics.playerScenes[client]) then
		Schema.cinematics.RemovePlayerFromScene(client)
	end

	-- Set up new scene
	Schema.cinematics.playerScenes[client] = {
		scene = scene,
		startTime = CurTime()
	}

	-- Spawn player at cinematic spawn if specified
	if (scene.cinematicSpawnID) then
		if (fadeIn == nil) then
			fadeIn = true -- Default to true if not specified
		end

		Schema.cinematics.SpawnPlayerAtCinematic(client, scene.cinematicSpawnID, fadeIn)
	end

	-- Call server-side scene enter
	if (scene.OnEnterServer) then
		scene:OnEnterServer(client)
	end

	-- Notify client to enter scene
	net.Start("ixCinematicEnterScene")
	net.WriteString(sceneID)
	net.Send(client)

	hook.Run("PlayerEnteredScene", client, sceneID)
	return true
end

function Schema.cinematics.IsPlayerInScene(client, sceneID)
	local sceneData = Schema.cinematics.playerScenes[client]
	if (not sceneData) then
		return false
	end

	return sceneData.scene.uniqueID == sceneID
end

function Schema.cinematics.RemovePlayerFromScene(client)
	local sceneData = Schema.cinematics.playerScenes[client]
	if (not sceneData) then
		return
	end

	local scene = sceneData.scene

	if (scene.OnLeaveServer) then
		scene:OnLeaveServer(client)
	end

	Schema.cinematics.playerScenes[client] = nil

	-- Reset visual effects
	net.Start("ixCinematicSetBlackWhite")
	net.WriteBool(false)
	net.Send(client)

	-- Notify client to leave scene
	net.Start("ixCinematicLeaveScene")
	net.Send(client)

	hook.Run("PlayerLeftScene", client, scene.uniqueID)
end

function Schema.cinematics.RemovePlayerFromSceneFadeOut(client, fadeTime, blackPeriod, callback)
	local sceneData = Schema.cinematics.playerScenes[client]

	if (not sceneData) then
		if (callback) then
			callback()
		end
		return false
	end

	fadeTime = fadeTime or Schema.cinematics.CINEMATIC_FADE_TIME
	blackPeriod = blackPeriod or Schema.cinematics.CINEMATIC_BLACK_GRACE_DURATION

	-- Store removal data for when fade completes
	Schema.cinematics.pendingRemovals = Schema.cinematics.pendingRemovals or {}
	Schema.cinematics.pendingRemovals[client] = {
		callback = callback,
		sceneID = sceneData.scene.uniqueID
	}

	-- Start fade out with callback
	net.Start("ixCinematicFadeOut")
	net.WriteFloat(fadeTime)
	net.WriteBool(true)                                  -- has callback
	net.WriteFloat(blackPeriod)
	net.WriteString(Schema.cinematics.REMOVE_FROM_SCENE_ID) -- Special identifier for removal
	net.Send(client)

	return true
end

function Schema.cinematics.TransitionPlayerToScene(client, newSceneID, fadeTime, blackPeriod)
	local newScene = Schema.cinematics.Get(newSceneID)
	if (not newScene) then
		ix.util.SchemaErrorNoHalt("Scene not found for transition: " .. newSceneID)
		return false
	end

	fadeTime = fadeTime or Schema.cinematics.CINEMATIC_FADE_TIME
	blackPeriod = blackPeriod or Schema.cinematics.CINEMATIC_BLACK_GRACE_DURATION

	-- Store transition data
	Schema.cinematics.pendingTransitions = Schema.cinematics.pendingTransitions or {}
	Schema.cinematics.pendingTransitions[client] = newSceneID

	net.Start("ixCinematicFadeOut")
	net.WriteFloat(fadeTime)
	net.WriteBool(true) -- has callback
	net.WriteFloat(blackPeriod)
	net.WriteString(newSceneID)
	net.Send(client)

	return true
end

--- Spawns a player at a cinematic spawn point, optionally with a fade in or specified fade in time.
--- @param client Player
--- @param cinematicSpawnID string
--- @param fadeIn boolean|number
--- @return boolean
function Schema.cinematics.SpawnPlayerAtCinematic(client, cinematicSpawnID, fadeIn)
	local spawns = Schema.cinematics.GetCinematicSpawns(cinematicSpawnID)

	if (#spawns == 0) then
		ix.util.SchemaErrorNoHalt("No cinematic spawns found for: " .. cinematicSpawnID)
		return false
	end

	local spawn = spawns[math.random(1, #spawns)]
	local position = spawn:GetPos()
	local angles = spawn:GetAngles()

	client:SetPos(position)
	client:SetEyeAngles(angles)
	client:SetLocalVelocity(Vector(0, 0, 0))

	if (isnumber(fadeIn) or fadeIn ~= false) then
		local fadeTime = isnumber(fadeIn) and fadeIn or Schema.cinematics.CINEMATIC_FADE_TIME

		net.Start("ixCinematicFadeIn")
		net.WriteFloat(fadeTime)
		net.Send(client)
	end

	return true
end

function Schema.cinematics.SetPlayerBlackAndWhite(client, enabled)
	net.Start("ixCinematicSetBlackWhite")
	net.WriteBool(enabled)
	net.Send(client)
end

function Schema.cinematics.ShowCinematicText(client, text, duration)
	duration = duration or Schema.cinematics.CINEMATIC_TEXT_DURATION

	net.Start("ixCinematicShowText")
	net.WriteString(text)
	net.WriteFloat(duration)
	net.Send(client)
end

function Schema.cinematics.GetPlayerScene(client)
	local sceneData = Schema.cinematics.playerScenes[client]

	if (sceneData) then
		return sceneData.scene.uniqueID
	end

	return nil
end

hook.Add("Think", "expCinematicsThink", function()
	-- Call OnServerThink for all players in scenes
	for client, sceneData in pairs(Schema.cinematics.playerScenes) do
		if (IsValid(client) and sceneData.scene.OnServerThink) then
			sceneData.scene:OnServerThink(client)
		end
	end
end)

hook.Add("PlayerDisconnected", "expCinematicsPlayerDisconnected", function(client)
	Schema.cinematics.RemovePlayerFromScene(client)

	if (Schema.cinematics.pendingTransitions) then
		Schema.cinematics.pendingTransitions[client] = nil
	end

	if (Schema.cinematics.pendingRemovals) then
		Schema.cinematics.pendingRemovals[client] = nil
	end
end)

-- Server-side network message receiver for transition/removal completion
net.Receive("ixCinematicFadeComplete", function(len, client)
	local sceneID = net.ReadString()

	-- Handle scene removal
	if (sceneID == Schema.cinematics.REMOVE_FROM_SCENE_ID) then
		if (Schema.cinematics.pendingRemovals and Schema.cinematics.pendingRemovals[client]) then
			local removalData = Schema.cinematics.pendingRemovals[client]
			Schema.cinematics.pendingRemovals[client] = nil

			-- Remove player from scene
			Schema.cinematics.RemovePlayerFromScene(client)

			-- Execute callback if provided
			if (removalData.callback) then
				removalData.callback()
			end
		end

		return
	end

	-- Handle scene transition
	if (Schema.cinematics.pendingTransitions and Schema.cinematics.pendingTransitions[client]) then
		Schema.cinematics.pendingTransitions[client] = nil
		Schema.cinematics.PutPlayerInScene(client, sceneID)
	end
end)
