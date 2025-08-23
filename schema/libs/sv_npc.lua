--- @class PlayerCurrentInteraction
--- @field npcEntity Entity The entity of the NPC the player is interacting with.
--- @field npc ExperimentNpc The NPC data of the npc
--- @field interactionSet InteractionSet The current interaction set the player and NPC are in.
--- @field interaction Interaction The current interaction the player and NPC are in.

--- Client library that exposes functions to interact with NPCs.
--- It also has all functions a `CommonLibrary` has.
--- @class Schema.npc : CommonLibrary
Schema.npc = ix.util.GetOrCreateCommonLibrary("npc", function() return ix.util.NewMetaObject(Schema.meta.npc) end)

util.AddNetworkString("expNpcInteractShow")
util.AddNetworkString("expNpcInteractResponse")

local WORKAROUND_FEET_OFFSET = Vector(0, 0, 4)

--- The file name where the NPC location data is saved (map specific).
--- @return string
function Schema.npc.GetMapSaveFile()
	return "npcs/" .. game.GetMap() .. ".json"
end

--- The file where dynamically created NPC data is saved.
--- @param uniqueID string
--- @return string
function Schema.npc.GetSaveFile(uniqueID)
	return "npcs/dynamic/" .. uniqueID .. ".json"
end

--- Saves dynamically created NPC data so it can be loaded again
--- after a map change or server restart.
--- @param npcData ExperimentNpc
function Schema.npc.Save(npcData)
	local file = Schema.npc.GetSaveFile(npcData.uniqueID)

	Schema.util.SaveSchemaData(file, npcData)
end

--- Destroys the dynamically created NPC data with the given uniqueID.
--- @param uniqueID string
function Schema.npc.Destroy(uniqueID)
	local file = Schema.npc.GetSaveFile(uniqueID)

	Schema.util.DeleteSchemaData(file)
end

--- Initialize dynamically created NPC data such that the interaction
--- sets, interactions and responses all get their metatables setup.
--- @param npcData ExperimentNpc
--- @return ExperimentNpc
function Schema.npc.RegisterDynamic(npcData)
	local interactionSets = npcData.interactionSets

	-- Don't confuse Register with this data
	npcData.interactionSets = nil

	npcData = Schema.npc.Register(npcData)

	if (not interactionSets) then
		return npcData
	end

	for _, interactionSet in ipairs(interactionSets) do
		local set = npcData:RegisterInteractionSet({
			uniqueID = interactionSet.uniqueID,
			conditions = interactionSet.conditions,
			isDynamic = true,
		})

		for _, interactionInfo in ipairs(interactionSet.interactions) do
			local interaction = set:RegisterInteraction({
				uniqueID = interactionInfo.uniqueID,
				text = interactionInfo.text,
				conditions = interactionInfo.conditions,
				effects = interactionInfo.effects,
				isDynamic = true,
			})

			for _, responseInfo in ipairs(interactionInfo.responses) do
				interaction:RegisterResponse({
					answer = responseInfo.answer,
					next = responseInfo.next,
					conditions = responseInfo.conditions,
					effects = responseInfo.effects,
					isDynamic = true,
				})
			end
		end
	end

	return npcData
end

--- Loads dynamically created NPC data.
--- @param uniqueID string
--- @return ExperimentNpc?
function Schema.npc.Load(uniqueID)
	local file = Schema.npc.GetSaveFile(uniqueID)
	local data = Schema.util.RestoreSchemaData(file, false)

	if (not data) then
		return
	end

	return data
end

--- Spawns an NPC entity at the specified position and angles.
--- @param npc ExperimentNpc
--- @param position Vector
--- @param angles Angle
--- @return Entity
function Schema.npc.SpawnEntity(npc, position, angles)
	local npcEntity = ents.Create("exp_npc")
	npcEntity:SetupNPC(npc)
	npcEntity:SetPos(position + Vector(0, 0, 16))
	npcEntity:SetAngles(angles)
	npcEntity:Spawn()
	npcEntity:Activate()

	-- Hack so their feet don't jitter on the ground on displacements
	timer.Simple(2, function()
		if (IsValid(npcEntity)) then
			npcEntity:SetPos(npcEntity:GetPos() - WORKAROUND_FEET_OFFSET)
		end
	end)

	return npcEntity
end

--- Starts the given interaction with the NPC entity, sending the data to the client.
--- For dynamically created interactions, the entire interaction set and interaction
--- data is sent (since the client doesn't have it).
--- @param client Player
--- @param npcEntity Entity
--- @param npc ExperimentNpc
--- @param interactionSet InteractionSet
--- @param interaction Interaction
function Schema.npc.StartInteraction(client, npcEntity, npc, interactionSet, interaction)
	client.expCurrentInteraction = {
		npcEntity = npcEntity,
		npc = npc,
		interactionSet = interactionSet,
		interaction = interaction,
	}

	interaction:CallServerOnStart(client, npcEntity)

	if (not interactionSet.isDynamic) then
		net.Start("expNpcInteractShow")
		net.WriteEntity(npcEntity)
		net.WriteString(interactionSet.uniqueID)
		net.WriteString(interaction.uniqueID)
		net.Send(client)
		return
	end

	-- Copy the intereaction, then filter out responses that don't pass conditions
	local responses = {}

	for _, response in ipairs(interaction:GetResponses()) do
		if (response:CheckCanChoose(client, npcEntity)) then
			responses[#responses + 1] = response
		end
	end

	interaction = table.Copy(interaction)
	interaction.responses = responses
	interaction.conditions = interaction.conditions or {}

	-- For dynamically created interactions, we need to send àll the data since
	-- the client code doesn't contain it.
	local data = {
		npcEntityIndex = npcEntity:EntIndex(),
		npc = npc,
		interaction = interaction,
	}

	Schema.chunkedNetwork.Send("NpcInteractShowDynamic", client, data)
end

--- Tries to start an interaction with the NPC entity.
--- @param client Player
--- @param npcEntity Entity
function Schema.npc.TryStartInteraction(client, npcEntity)
	local distance = client:EyePos():DistToSqr(npcEntity:GetPos())
	local interactRange = ix.config.Get("chatRange") ^ 2

	if (distance > interactRange) then
		client:Notify("You are too far away from this NPC to interact with them!")
		return
	end

	local npcId = npcEntity:GetNpcId()
	local npc = Schema.npc.Get(npcId)

	if (not npc) then
		ix.util.SchemaErrorNoHaltFormatted("Attempted to interact with an invalid NPC %s!", npcId)
		return
	end


	local interactionSet = npc:GetDesiredInteractionSet(client, npcEntity)

	if (not interactionSet) then
		interactionSet = hook.Run("OnNpcInteractionSetNotFound", client, npcEntity, npc)
	end

	if (not interactionSet) then
		print("No interaction set found!", client, npcEntity, npc)
		return
	end

	local interaction = interactionSet:GetDesiredInteraction(client, npcEntity)

	if (not interaction) then
		interaction = hook.Run("OnNpcInteractionNotFound", client, npcEntity, npc)
	end

	if (not interaction) then
		print("No interaction found!", client, npcEntity, npc)
		return
	end

	Schema.npc.StartInteraction(client, npcEntity, npc, interactionSet, interaction)
end

--- Goes through all NPC's on the map and saves their location, angle and
--- uniqueID to a file so they can be respawned after a map change or server
--- restart.
function Schema.npc.SaveNpcData()
	local npcData = {}

	for _, npc in ipairs(ents.FindByClass("exp_npc")) do
		if (npc:MapCreationID() > 0) then
			-- Don't save map npcs
			continue
		end

		npcData[#npcData + 1] = {
			uniqueID = npc:GetNpcId(),
			position = npc:GetPos() + WORKAROUND_FEET_OFFSET,
			angles = npc:GetAngles(),
		}
	end

	local file = Schema.npc.GetMapSaveFile()

	Schema.util.SaveSchemaData(file, {
		npcData = npcData,
	})
end

--- Spawns an NPC for the given player, using the player's target trace to
--- determine the position.
--- @param npc ExperimentNpc
--- @param player Player
--- @return Entity
function Schema.npc.SpawnForPlayer(npc, player)
	local trace = player:GetEyeTraceNoCursor()

	local angledTowardsPlayer = (player:GetPos() - trace.HitPos):Angle()
	angledTowardsPlayer.p = 0

	-- Spawn slightly above the ground so legs don't glitch
	local npcEntity = Schema.npc.SpawnEntity(npc, trace.HitPos + trace.HitNormal * 4, angledTowardsPlayer)

	Schema.npc.SaveNpcData()

	return npcEntity
end

--- Opens the NPC editor for the given player, using the given NPC entity.
--- If no NPC entity is given, the editor is opened with no data.
--- @param client Player
--- @param npcEntity Entity?
function Schema.npc.OpenEditor(client, npcEntity)
	if (not npcEntity) then
		Schema.chunkedNetwork.Send("NpcEditOpen", client, {})
		return
	end

	local npc = npcEntity:GetNpcData()

	local data = {
		entityIndex = npcEntity:EntIndex(),
		uniqueID = npc.uniqueID,
		name = npc.name,
		description = npc.description,
		model = npc.model,
		voicePitch = npc.voicePitch,
		interactionSets = npc.interactionSets,
	}
	Schema.chunkedNetwork.Send("NpcEditOpen", client, data)
end

net.Receive("expNpcInteractResponse", function(length, player)
	local responseIndex = net.ReadUInt(6)

	if (not player.expCurrentInteraction) then
		player:Notify("You are not currently interacting with an NPC!")
		return
	end

	local npcEntity = player.expCurrentInteraction.npcEntity
	local npc = player.expCurrentInteraction.npc

	if (not npc) then
		ix.util.SchemaErrorNoHaltFormatted("Attempted to interact with an invalid NPC (nil)!")
		return
	end

	local interactionSet = player.expCurrentInteraction.interactionSet

	if (not interactionSet) then
		ix.util.SchemaErrorNoHaltFormatted("Attempted to interact with an invalid NPC interaction set!")
		return
	end

	local interaction = player.expCurrentInteraction.interaction

	if (not interaction) then
		ix.util.SchemaErrorNoHaltFormatted("Attempted to interact with an invalid NPC interaction (%s)!",
			tostring(player.expCurrentInteraction.interaction))
		return
	end

	local response = interaction:GetResponseByIndex(responseIndex)

	if (not response) then
		ix.util.SchemaErrorNoHaltFormatted("Attempted to interact with an invalid NPC interaction response.\n")
		return
	end

	if (response:CheckCanChoose(player, npcEntity) == false) then
		player:Notify("You cannot choose this response!")
		return
	end

	local nextInteractionID = response:OnChooseNextInteraction(player, npcEntity)

	if (not nextInteractionID) then
		nextInteractionID = response:GetNextInteraction()
	end

	if (not nextInteractionID) then
		-- This point is reached when the player chose an option that has no 'next' member. The interface
		-- will automatically close after the grace period.
		if (npc.OnEnd) then
			npc:OnEnd(player, npcEntity)
		end

		player.expCurrentInteraction = nil

		return
	end

	local nextInteraction = interactionSet:GetInteraction(nextInteractionID)

	if (not nextInteraction) then
		ix.util.SchemaErrorNoHaltFormatted("Attempted to interact with an invalid NPC interaction. (%s)",
			tostring(nextInteractionID))
		return
	end

	Schema.npc.StartInteraction(player, npcEntity, npc, interactionSet, nextInteraction)
end)

hook.Add("InitializedSchema", "Schema.npc.LoadNpcData", function()
	local file = Schema.npc.GetMapSaveFile()
	local data = Schema.util.RestoreSchemaData(file, false)

	if (not data) then
		return
	end

	local npcData = data.npcData or {}

	for _, savedNpc in ipairs(npcData) do
		if (not savedNpc.uniqueID) then
			PrintTable(savedNpc)
			ix.util.SchemaErrorNoHaltFormatted("NPC data is missing a uniqueID!")
			continue
		end

		local npc = Schema.npc.Get(savedNpc.uniqueID)

		if (not npc) then
			local npcRegistration = Schema.npc.Load(savedNpc.uniqueID)

			if (npcRegistration) then
				npc = Schema.npc.RegisterDynamic(npcRegistration)
			end
		end

		if (not npc) then
			ix.util.SchemaErrorNoHaltFormatted("NPC data is missing and no dynamic data could be loaded for %s!",
				savedNpc.uniqueID)
			continue
		end

		Schema.npc.SpawnEntity(npc, savedNpc.position, savedNpc.angles)
	end
end)
