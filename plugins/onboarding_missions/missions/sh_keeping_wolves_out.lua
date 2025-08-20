local PLUGIN = PLUGIN

PLUGIN.MISSION_2_TRACKER = Schema.progression.RegisterTracker({
	scope = PLUGIN.uniqueID,

	uniqueID = PLUGIN.uniqueID .. "#mission2",

	name = "Keeping the Wolves Out",

	completedKey = PLUGIN.PROGRESSION_MISSION_2_COMPLETED,

	isInProgress = PLUGIN.PROGRESSION_MISSION_2_ACCEPTED,

	showOnHUD = true,
})

PLUGIN.MISSION_2_TRACKER_GOAL_1 = PLUGIN.MISSION_2_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_2_USE_NANO_TECH_ITEM,

	name = "Use the 'Newbie Nano Tech' item",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return true
	end,
})

PLUGIN.MISSION_2_TRACKER_GOAL_2 = PLUGIN.MISSION_2_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_2_VIEW_NANO_BUFF,

	name = "View the 'Newbie' Nano Buff",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return PLUGIN.MISSION_2_TRACKER_GOAL_1:CheckProgress()
	end,
})

PLUGIN.MISSION_2_TRACKER_GOAL_3 = PLUGIN.MISSION_2_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_2_CONTINUE,

	-- TODO: Somehow get the name of the npc
	name = "Continue your conversation with the NPC",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return PLUGIN.MISSION_2_TRACKER_GOAL_2:CheckProgress()
	end
})

PLUGIN.MISSION_2_TRACKER_GOAL_4 = PLUGIN.MISSION_2_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_2_USE_DOOR_PROTECTOR,

	name = "Use the Door Protector",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return PLUGIN.MISSION_2_TRACKER_GOAL_3:CheckProgress()
	end
})

PLUGIN.MISSION_2_TRACKER_GOAL_5 = PLUGIN.MISSION_2_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_2_LOCK_DOOR_WITH_KEYS,

	name = "Lock the Door with Keys",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return PLUGIN.MISSION_2_TRACKER_GOAL_3:CheckProgress()
	end
})

PLUGIN.MISSION_2_TRACKER_GOAL_6 = PLUGIN.MISSION_2_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_2_RETURN,

	-- TODO: Somehow get the name of the npc
	name = "Return to the NPC",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return PLUGIN.MISSION_2_TRACKER_GOAL_5:CheckProgress()
	end
})
