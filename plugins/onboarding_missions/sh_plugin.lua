local PLUGIN = PLUGIN

PLUGIN.name = "Onboarding Missions"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Adds several missions to help new players get started."

-- Mission Constants
PLUGIN.PROGRESSION_MISSION_1_ACCEPTED = "mission1_accepted"
PLUGIN.PROGRESSION_MISSION_1_COMPLETED = "mission1_completed"

PLUGIN.PROGRESSION_MISSION_2_ACCEPTED = "mission2_accepted"
PLUGIN.PROGRESSION_MISSION_2_COMPLETED = "mission2_completed"
PLUGIN.PROGRESSION_MISSION_2_USE_NANO_TECH_ITEM = "mission2_goal1"
PLUGIN.PROGRESSION_MISSION_2_VIEW_NANO_BUFF = "mission2_goal2"
PLUGIN.PROGRESSION_MISSION_2_CONTINUE = "mission2_goal3"
PLUGIN.PROGRESSION_MISSION_2_USE_DOOR_PROTECTOR = "mission2_goal4"
PLUGIN.PROGRESSION_MISSION_2_LOCK_DOOR_WITH_KEYS = "mission2_goal5"
PLUGIN.PROGRESSION_MISSION_2_RETURN = "mission2_goal6"

PLUGIN.PROGRESSION_MISSION_3_ACCEPTED = "mission3_accepted"
PLUGIN.PROGRESSION_MISSION_3_COMPLETED = "mission3_completed"
PLUGIN.PROGRESSION_MISSION_3_INFORMATION = "mission3_goal1"
PLUGIN.PROGRESSION_MISSION_3_BUY_BEER = "mission3_goal2"
PLUGIN.PROGRESSION_MISSION_3_DRINK_BEER = "mission3_goal3"
PLUGIN.PROGRESSION_MISSION_3_PLACE_BCU_GOT_SCRAP = "mission3_goal4.1"
PLUGIN.PROGRESSION_MISSION_3_PLACE_BCU = "mission3_goal4.2"
PLUGIN.PROGRESSION_MISSION_3_RECHARGE_BCU = "mission3_goal5"
PLUGIN.PROGRESSION_MISSION_3_SCAVENGE_FOR_SCRAP = "mission3_goal6"
PLUGIN.PROGRESSION_MISSION_3_WAIT_FOR_BCU_PRODUCTION = "mission3_goal7"
PLUGIN.PROGRESSION_MISSION_3_RETURN_TO_NPC = "mission3_goal8"
PLUGIN.PROGRESSION_MISSION_3_DRINK_SHARED = "mission3_drink_shared"

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
	end
end
