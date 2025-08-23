local PLUGIN = PLUGIN

PLUGIN.MISSION_1_TRACKER = Schema.progression.RegisterTracker({
	scope = PLUGIN.uniqueID,

	uniqueID = PLUGIN.uniqueID .. "#mission1",

	name = "Getting Started",

	completedKey = PLUGIN.PROGRESSION_MISSION_1_COMPLETED,

	isInProgress = PLUGIN.PROGRESSION_MISSION_1_ACCEPTED,

	showOnHUD = true,

	cannotAbandon = true
})

PLUGIN.MISSION_1_TRACKER_GOAL = PLUGIN.MISSION_1_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_1_COMPLETED,

	name = function(tracker)
		local npcName = "that NPC nearby where you spawned"
		local markedNPCs = Schema.entityMarker.GetMarkedEntities()

		for _, entity in ipairs(markedNPCs) do
			if (entity:GetClass() == "exp_npc" and entity:GetNpcId():StartsWith("intro")) then
				npcName = entity:GetDisplayName()
				break
			end
		end

		return string.format("Talk to %s", npcName)
	end,

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,
})
