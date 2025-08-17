Schema.spawnPoints = ix.util.GetOrCreateLibrary("spawnPoints", {
	mapSpawns = {},
	spawns = {},

	spawnNearDeathRange = 4096,
	spawnNearDeathAfterSeconds = 60 * 5,
})

util.AddNetworkString("expSpawnSelectOpen")
util.AddNetworkString("expSpawnRequestSelect")
util.AddNetworkString("expSpawnSelectResponse")

function Schema.spawnPoints.AddMapSpawn(mapSpawn)
	if (not mapSpawn.name) then
		ix.util.SchemaError("Invalid map spawn point! Missing name!")
	end

	if (not mapSpawn.position) then
		ix.util.SchemaError("Invalid map spawn point! Missing position!")
	end

	if (not mapSpawn.angles) then
		ix.util.SchemaError("Invalid map spawn point! Missing angles!")
	end

	if (not mapSpawn.shouldNotSave) then
		mapSpawn.shouldNotSave = true
	end

	Schema.spawnPoints.mapSpawns[#Schema.spawnPoints.mapSpawns + 1] = mapSpawn
end

function Schema.spawnPoints.GetAvailableSpawns(client)
	local character = client:GetCharacter()
	local lastDeathPosition = character:GetData("lastDeathPosition")
	local lastDeathTime = character:GetData("lastDeathTime")
	local spawnNearDeathRange = Schema.spawnPoints.spawnNearDeathRange * Schema.spawnPoints.spawnNearDeathRange
	local canSpawnNearDeath = not lastDeathTime or
		(os.time() - lastDeathTime) > Schema.spawnPoints.spawnNearDeathAfterSeconds
	local safeCount = 0
	local spawns = {}

	for k, spawn in ipairs(Schema.spawnPoints.spawns) do
		local status = spawn.status or Schema.spawnPoints.spawnStatus.SAFE
		local unsafeUntil

		-- Filter out spawns where the player recently died.
		if (status == Schema.spawnPoints.spawnStatus.SAFE and (not canSpawnNearDeath and lastDeathPosition)) then
			local distance = spawn.position:DistToSqr(lastDeathPosition)

			if (distance < spawnNearDeathRange) then
				status = Schema.spawnPoints.spawnStatus.LOCKED
				unsafeUntil = CurTime() + (Schema.spawnPoints.spawnNearDeathAfterSeconds - (os.time() - lastDeathTime))
			end
		end

		-- TODO: Unsafe because of nearby players activity

		if (status == Schema.spawnPoints.spawnStatus.SAFE) then
			safeCount = safeCount + 1
		end

		spawns[k] = {
			position = spawn.position,
			angles = spawn.angles,
			name = spawn.name,
			status = status,
			unsafeUntil = unsafeUntil
		}
	end

	-- If everything is unsafe, unlock all spawns, setting CHAOS status.
	if (safeCount == 0) then
		for k, spawn in ipairs(spawns) do
			spawn.status = Schema.spawnPoints.spawnStatus.CHAOS
		end
	end

	return spawns
end

local teleportSounds = {
	"ambient/machines/teleport1.wav",
	"ambient/machines/teleport3.wav",
	"ambient/machines/teleport4.wav"
}

function Schema.spawnPoints.DoAnimatedSpawn(client, spawnPosition, spawnAngles)
	local hitNormal = Vector(0, 0, 1)
	local animationDuration = DEBUG_DISABLE_SPAWN_ANIM and 0 or 3
	local effectData
	local scale = 20

	client:SetPos(spawnPosition)

	local volume = math.Rand(0.8, 0.99)
	local pitch = math.random(75, 125)

	client:SetColor(Color(0, 0, 255, 75))
	client:EmitSound(
		"ambient/levels/labs/teleport_preblast_suckin1.wav",
		75,
		pitch,
		volume,
		CHAN_AUTO
	)

	net.Start("expSpawnSelectResponse")
	net.WriteUInt(Schema.spawnPoints.spawnResult.OK, 4)
	net.Send(client)

	for i = 1, 8 do
		timer.Simple(animationDuration - (i * .5), function()
			effectData = EffectData()
			effectData:SetOrigin(spawnPosition + VectorRand(100, 100) + Vector(0, 0, 400))
			effectData:SetScale(.1)
			effectData:SetMagnitude(2)
			effectData:SetNormal(hitNormal)
			util.Effect("Sparks", effectData)
		end)
	end

	timer.Simple(animationDuration, function()
		if (not IsValid(client)) then
			return
		end

		-- Move all players and NPC's that are in the way, out of the way. Knock out players.
		local entitiesAtSpawn = ents.FindInBox(spawnPosition + Vector(-64, -64, 0), spawnPosition + Vector(64, 64, 90))
		local awayFromSpawnAngles = (spawnAngles:Forward() * 1024) + (spawnAngles:Up() * 64)

		for _, entity in ipairs(entitiesAtSpawn) do
			if (entity == client) then
				continue
			end

			if (not entity:IsPlayer() and not entity:IsNPC()) then
				continue
			end

			entity:SetVelocity(awayFromSpawnAngles)

			if (entity:IsPlayer()) then
				entity:SetRagdolled(true, 5)
			end
		end

		-- Let players move, setting their position and angles again, restoring their normal color.
		client:Freeze(false)
		client:SetMoveType(MOVETYPE_WALK)
		client:SetEyeAngles(spawnAngles)
		client:SetNetVar("expChoosingSpawn", false)
		client:SetRenderMode(RENDERMODE_TRANSCOLOR)
		client:SetColor(Color(255, 255, 255, 255))

		-- Special sound and visual effects for other players to see.
		client:EmitSound(
			table.Random(teleportSounds),
			75,
			pitch,
			volume,
			CHAN_AUTO,
			0,
			34 -- "EXPLOSION RING 3" DSP
		)

		effectData = EffectData()
		effectData:SetOrigin(spawnPosition)
		effectData:SetRadius(scale * 4)
		effectData:SetNormal(hitNormal)
		util.Effect("AR2Explosion", effectData)

		effectData = EffectData()
		effectData:SetOrigin(spawnPosition)
		effectData:SetScale(scale)
		effectData:SetColor(20)
		util.Effect("camera_flash", effectData)

		effectData = EffectData()
		effectData:SetOrigin(spawnPosition)
		effectData:SetScale(scale * 50)
		effectData:SetNormal(hitNormal)
		util.Effect("ThumperDust", effectData)
	end)
end

hook.Add("LoadData", "expSpawnPointsLoadData", function()
	Schema.spawnPoints.spawns = Schema:GetData() or {}

	for _, spawn in ipairs(Schema.spawnPoints.mapSpawns) do
		Schema.spawnPoints.spawns[#Schema.spawnPoints.spawns + 1] = spawn
	end
end)

hook.Add("SaveData", "expSpawnPointsSaveData", function()
	local spawnsWithoutMap = {}

	for k, spawn in ipairs(Schema.spawnPoints.spawns) do
		if (spawn.shouldNotSave) then
			continue
		end

		spawnsWithoutMap[k] = spawn
	end

	Schema:SetData(spawnsWithoutMap)
end)

hook.Add("PostPlayerLoadout", "expSpawnPointsPostPlayerLoadout", function(client)
	local character = client:GetCharacter()

	if (not character or client:IsBot()) then
		return
	end

	if (#Schema.spawnPoints.spawns == 0) then
		ix.util.SchemaPrint("No spawn points have been set! Spawning without spawn selection.\n")
		return
	end

	local mapDetails = Schema.spawnPoints.GetMapDetails()

	if (client:GetNetVar("expChoosingSpawn", false)) then
		-- During initial character selection PlayerLoadout is called twice.
		return
	end

	local shouldShowSpawnSelection = hook.Run("ShouldShowSpawnSelection", client)

	if (shouldShowSpawnSelection == false) then
		return
	end

	-- When a player spawns, lock them so they can't move until they've selected a spawn point.
	client:SetPos(mapDetails and mapDetails.waitingPosition or vector_origin)
	client:SetEyeAngles(mapDetails and mapDetails.waitingAngles or angle_zero)
	client:SetColor(Color(255, 255, 255, 0))
	client:SetRenderMode(RENDERMODE_TRANSALPHA)
	client:SetNetVar("expChoosingSpawn", true)
	client:SetMoveType(MOVETYPE_NONE)
	client:Freeze(true)

	net.Start("expSpawnSelectOpen")
	net.WriteTable(Schema.spawnPoints.GetAvailableSpawns(client))
	net.Send(client)
end)

net.Receive("expSpawnRequestSelect", function(len, client)
	local index = net.ReadUInt(8)
	local spawn = Schema.spawnPoints.spawns[index]

	if (not spawn) then
		client:Notify("This spawn point is invalid!")
		net.Start("expSpawnSelectResponse")
		net.WriteUInt(Schema.spawnPoints.spawnResult.FAIL, 4)
		net.Send(client)
		return
	end

	local canSpawn, reason = hook.Run("PlayerCanSelectSpawnPoint", client, spawn, index)

	if (canSpawn == false) then
		client:Notify(reason or "You cannot spawn at this location!")
		net.Start("expSpawnSelectResponse")
		net.WriteUInt(Schema.spawnPoints.spawnResult.FAIL, 4)
		net.Send(client)
		return
	end

	Schema.spawnPoints.DoAnimatedSpawn(client, spawn.position, spawn.angles)
end)
