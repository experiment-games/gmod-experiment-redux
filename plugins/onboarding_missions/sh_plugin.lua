local PLUGIN = PLUGIN

PLUGIN.name = "Onboarding Missions"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Adds several missions to help new players get started."

--[[
	Mission Constants

	These are short on purpose as to not fill up the 'data' column of a character with
	excessive verbosity. Risk of conflicts is low, since these progressions are scoped
	to this plugin ("onboarding_missions").
--]]

PLUGIN.PROGRESSION_SPAWN_SELECTION_EXPLAINED = "sse"

PLUGIN.PROGRESSION_MISSION_1_ACCEPTED = "m1a"
PLUGIN.PROGRESSION_MISSION_1_COMPLETED = "m1c"

PLUGIN.PROGRESSION_MISSION_2_ACCEPTED = "m2a"
PLUGIN.PROGRESSION_MISSION_2_COMPLETED = "m2c"
PLUGIN.PROGRESSION_MISSION_2_USE_NANO_TECH_ITEM = "m2g1"
PLUGIN.PROGRESSION_MISSION_2_VIEW_NANO_BUFF = "m2g2"
PLUGIN.PROGRESSION_MISSION_2_CONTINUE = "m2g3"
PLUGIN.PROGRESSION_MISSION_2_USE_DOOR_PROTECTOR = "m2g4"
PLUGIN.PROGRESSION_MISSION_2_LOCK_DOOR_WITH_KEYS = "m2g5"
PLUGIN.PROGRESSION_MISSION_2_RETURN = "m2g6"

PLUGIN.PROGRESSION_MISSION_3_ACCEPTED = "m3a"
PLUGIN.PROGRESSION_MISSION_3_COMPLETED = "m3c"
PLUGIN.PROGRESSION_MISSION_3_INFORMATION = "m3g1"
PLUGIN.PROGRESSION_MISSION_3_BUY_BEER = "m3g2"
PLUGIN.PROGRESSION_MISSION_3_DRINK_BEER = "m3g3"
PLUGIN.PROGRESSION_MISSION_3_DRINK_BEER_POST = "m3g3.1"
PLUGIN.PROGRESSION_MISSION_3_PLACE_BCU_GOT_SCRAP = "m3g4.1"
PLUGIN.PROGRESSION_MISSION_3_PLACE_BCU = "m3g4.2"
PLUGIN.PROGRESSION_MISSION_3_RECHARGE_BCU = "m3g5"
PLUGIN.PROGRESSION_MISSION_3_SCAVENGE_FOR_SCRAP = "m3g6"
PLUGIN.PROGRESSION_MISSION_3_WAIT_FOR_BCU_PRODUCTION = "m3g7"
PLUGIN.PROGRESSION_MISSION_3_RETURN_TO_NPC = "m3g8"
PLUGIN.PROGRESSION_MISSION_3_DRINK_SHARED = "m3g9"

PLUGIN.PROGRESSION_MISSION_4_ACCEPTED = "m4a"
PLUGIN.PROGRESSION_MISSION_4_COMPLETED = "m4c"
PLUGIN.PROGRESSION_MISSION_4_BUY_PERK = "m4g1"
PLUGIN.PROGRESSION_MISSION_4_RETURN = "m4g2"

ix.util.IncludeDir(PLUGIN.folder .. "/missions", true)

if (not SERVER) then
	return
end

function PLUGIN:GetNearestIntroNPC(position)
	local nearbyEntities = ents.FindInSphere(position, 2000)
	local nearestIntroNPC = nil
	local nearestDistance = math.huge

	for _, entity in ipairs(nearbyEntities) do
		if (entity:GetClass() ~= "exp_npc") then
			continue
		end

		if (not entity:GetNpcId():StartsWith("intro")) then
			continue
		end

		local distance = entity:GetPos():DistToSqr(position)

		if (distance < nearestDistance) then
			nearestDistance = distance
			nearestIntroNPC = entity
		end
	end

	return nearestIntroNPC
end

function PLUGIN:PlayerSpawnedAtSpawnPoint(client)
	local accepted = PLUGIN.MISSION_1_TRACKER:IsInProgress(client)
	local completed = PLUGIN.MISSION_1_TRACKER:IsCompleted(client)

	if (accepted and completed) then
		return
	end

	-- If they haven't accepted the mission yet, point them to go to the nearest intro NPC.
	local nearestIntroNPC = self:GetNearestIntroNPC(client:GetPos())

	if (not nearestIntroNPC) then
		ix.util.SchemaErrorNoHalt(
			"No nearby intro NPC found for " .. client:GetName()
			.. " at " .. tostring(client:GetPos())
		)
		return
	end

	Schema.entityMarker.MarkForPlayer(client, nearestIntroNPC)

	-- Give them the mission
	if (not accepted) then
		PLUGIN.MISSION_1_TRACKER:Start(client)

		-- Don't show the spawn select tutorial again
		Schema.progression.Change(
			client,
			PLUGIN.uniqueID,
			PLUGIN.PROGRESSION_SPAWN_SELECTION_EXPLAINED,
			true
		)
	end
end
