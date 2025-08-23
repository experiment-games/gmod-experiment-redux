local PLUGIN = PLUGIN

PLUGIN.MISSION_4_TRACKER = Schema.progression.RegisterTracker({
	scope = PLUGIN.uniqueID,

	uniqueID = PLUGIN.uniqueID .. "#mission4",

	name = "Invest in Survival",

	completedKey = PLUGIN.PROGRESSION_MISSION_4_COMPLETED,

	isInProgress = PLUGIN.PROGRESSION_MISSION_4_ACCEPTED,

	showOnHUD = true,
})

PLUGIN.MISSION_4_TRACKER_GOAL_1 = PLUGIN.MISSION_4_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_4_BUY_PERK,

	name = "Buy any perk",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return true
	end,
})

PLUGIN.MISSION_4_TRACKER_GOAL_2 = PLUGIN.MISSION_4_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_4_RETURN,

	name = "Return to Eliana Wagner",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return true
	end,
})

if (SERVER) then
	hook.Add("PlayerPerkBought", "expOnboardingMission4BuyPerk", function(client, perkTable)
		if (PLUGIN.MISSION_4_TRACKER:IsInProgress(client) and not PLUGIN.MISSION_4_TRACKER_GOAL_1:CheckProgress(client)) then
			PLUGIN.MISSION_4_TRACKER_GOAL_1:Change(client, true)
		end
	end)
end
