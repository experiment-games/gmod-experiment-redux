local PLUGIN = PLUGIN

PLUGIN.MISSION_3_TRACKER = Schema.progression.RegisterTracker({
	scope = PLUGIN.uniqueID,

	uniqueID = PLUGIN.uniqueID .. "#mission3",

	name = "From Scrap to Bolts",

	completedKey = PLUGIN.PROGRESSION_MISSION_3_COMPLETED,

	isInProgress = PLUGIN.PROGRESSION_MISSION_3_ACCEPTED,

	showOnHUD = true,
})

PLUGIN.MISSION_3_TRACKER_GOAL_1 = PLUGIN.MISSION_3_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_3_INFORMATION,

	-- TODO: Somehow get the name of the npc
	name = "Talk to the NPC about making bolts",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return true
	end,
})

PLUGIN.MISSION_3_TRACKER_GOAL_2 = PLUGIN.MISSION_3_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_3_BUY_BEER,

	name = "Buy a beer from The Business",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return PLUGIN.MISSION_3_TRACKER_GOAL_1:CheckProgress()
	end,
})

PLUGIN.MISSION_3_TRACKER_GOAL_3 = PLUGIN.MISSION_3_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_3_DRINK_BEER,

	name = "Drink the beer",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return PLUGIN.MISSION_3_TRACKER_GOAL_2:CheckProgress()
	end,
})

PLUGIN.MISSION_3_TRACKER_GOAL_3_POST = PLUGIN.MISSION_3_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_3_DRINK_BEER_POST,

	-- TODO: Somehow get the name of the npc
	name = "Talk to the NPC",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return PLUGIN.MISSION_3_TRACKER_GOAL_3:CheckProgress()
			and not Schema.progression.Check(
				PLUGIN.uniqueID,
				PLUGIN.PROGRESSION_MISSION_3_PLACE_BCU_GOT_SCRAP,
				true
			)
	end,
})

PLUGIN.MISSION_3_TRACKER_GOAL_4 = PLUGIN.MISSION_3_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_3_PLACE_BCU,

	name = "Place your BCU in your secured room",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return PLUGIN.MISSION_3_TRACKER_GOAL_3:CheckProgress()
			and Schema.progression.Check(
				PLUGIN.uniqueID,
				PLUGIN.PROGRESSION_MISSION_3_PLACE_BCU_GOT_SCRAP,
				true
			)
	end,
})

PLUGIN.MISSION_3_TRACKER_GOAL_5 = PLUGIN.MISSION_3_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_3_RECHARGE_BCU,

	name = "Recharge your BCU with scrap",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return PLUGIN.MISSION_3_TRACKER_GOAL_4:CheckProgress()
	end,
})

PLUGIN.MISSION_3_TRACKER_GOAL_6 = PLUGIN.MISSION_3_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_3_SCAVENGE_FOR_SCRAP,

	name = "Find more scrap by scavenging",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return PLUGIN.MISSION_3_TRACKER_GOAL_5:CheckProgress()
	end,
})

PLUGIN.MISSION_3_TRACKER_GOAL_7 = PLUGIN.MISSION_3_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_3_WAIT_FOR_BCU_PRODUCTION,

	name = "Wait for BCU to produce bolts and withdraw them",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return PLUGIN.MISSION_3_TRACKER_GOAL_6:CheckProgress()
	end,
})

PLUGIN.MISSION_3_TRACKER_GOAL_8 = PLUGIN.MISSION_3_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MISSION_3_RETURN_TO_NPC,

	-- TODO: Somehow get the name of the npc
	name = "Return to the NPC",

	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,

	isVisible = function(goal)
		return PLUGIN.MISSION_3_TRACKER_GOAL_7:CheckProgress()
	end,
})

if (SERVER) then
	hook.Add("OnBusinessItemPurchased", "expOnboardingMission3BuyBeer", function(client, itemTable, price, entity)
		if (
				itemTable.uniqueID == "beer"
				and PLUGIN.MISSION_3_TRACKER_GOAL_1:CheckProgress(client)
				and not PLUGIN.MISSION_3_TRACKER_GOAL_2:CheckProgress(client)
			) then
			PLUGIN.MISSION_3_TRACKER_GOAL_2:Change(client, true)
		end
	end)

	hook.Add("OnPlayerDrinkAlcohol", "expOnboardingMission3DrinkBeer", function(client, item)
		if (
				item.uniqueID == "beer"
				and PLUGIN.MISSION_3_TRACKER_GOAL_2:CheckProgress(client)
				and not PLUGIN.MISSION_3_TRACKER_GOAL_3:CheckProgress(client)
			) then
			PLUGIN.MISSION_3_TRACKER_GOAL_3:Change(client, true)
		end
	end)

	hook.Add("OnGeneratorPlaced", "expOnboardingMission3PlaceBCU", function(client, entity, item)
		if (PLUGIN.MISSION_3_TRACKER_GOAL_3:CheckProgress(client) and not PLUGIN.MISSION_3_TRACKER_GOAL_4:CheckProgress(client)) then
			PLUGIN.MISSION_3_TRACKER_GOAL_4:Change(client, true)
		end
	end)

	hook.Add("PlayerRechargedGenerator", "expOnboardingMission3RechargeBCU", function(client, entity, scrapAmount)
		if (PLUGIN.MISSION_3_TRACKER_GOAL_4:CheckProgress(client) and not PLUGIN.MISSION_3_TRACKER_GOAL_5:CheckProgress(client)) then
			PLUGIN.MISSION_3_TRACKER_GOAL_5:Change(client, true)
		end
	end)

	-- Commented, because instead of finding the item, we want to check that they scrap the item into scrap
	-- hook.Add("InventoryItemAdded", "expOnboardingMission3Scavenge", function(oldInventory, targetInventory, item)
	-- 	if (not targetInventory or not oldInventory) then
	-- 		return
	-- 	end

	-- 	if (not IsValid(oldInventory.entity) or not oldInventory.entity.IsScavengingSource) then
	-- 		return
	-- 	end

	-- 	local client = targetInventory:GetOwner()

	-- 	if (PLUGIN.MISSION_3_TRACKER_GOAL_5:CheckProgress(client) and not PLUGIN.MISSION_3_TRACKER_GOAL_6:CheckProgress(client)) then
	-- 		PLUGIN.MISSION_3_TRACKER_GOAL_6:Change(client, true)
	-- 	end
	-- end)
	hook.Add("OnItemScrapped", "expOnboardingMission3Scavenge", function(client, item, scrapMaterials)
		if (
				scrapMaterials["scrap"] and scrapMaterials["scrap"] > 0
				and PLUGIN.MISSION_3_TRACKER_GOAL_5:CheckProgress(client)
				and not PLUGIN.MISSION_3_TRACKER_GOAL_6:CheckProgress(client)
			) then
			PLUGIN.MISSION_3_TRACKER_GOAL_6:Change(client, true)
		end
	end)

	hook.Add("PlayerWithdrewFromGenerator", "expOnboardingMission3WithdrawBolts", function(client, entity, amount)
		if (PLUGIN.MISSION_3_TRACKER_GOAL_6:CheckProgress(client) and not PLUGIN.MISSION_3_TRACKER_GOAL_7:CheckProgress(client)) then
			PLUGIN.MISSION_3_TRACKER_GOAL_7:Change(client, true)
		end
	end)
end
