local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

-- NPC Configuration
NPC.name = "Emilio Sanchez"
NPC.description = "This young man has a friendly demeanor, dressed in a casual outfit."
NPC.model = "models/hl2rp/citizens/male_12.mdl"
NPC.skin = 8
NPC.bodygroups = {
	[1] = 3, -- Off-white shirt with green accents
	[2] = 1, -- Blackgray jeans
	[3] = 0, -- No gloves
	[4] = 0, -- No hat
	[5] = 0, -- No glasses
}
NPC.voicePitch = 102

--[[
	Lore and Speaking style for Emilio Sanchez:
	- Friendly, yet assertive
	- Speaks with a slight accent, adding charm to his words
	- Uses hand gestures for emphasis
	- Maintains eye contact to engage listeners
	- Occasionally leans in closer to convey sincerity
--]]

--[[

    Onboarding Mission Interaction Set

--]]

local INTERACTION_SET_MISSION2 = NPC:RegisterInteractionSet({
	uniqueID = "onboarding_mission",

	serverCheckShouldStart = function(interactionSet, player, npcEntity)
		return PLUGIN.MISSION_1_TRACKER:IsInProgress(player)
			and not PLUGIN.MISSION_2_TRACKER:IsCompleted(player)
	end,
})

--[[
	Completes mission 1 and starts mission 2
--]]
local INTERACTION_START_MISSION2 = INTERACTION_SET_MISSION2:RegisterInteraction({
	uniqueID = "startMission2",

	text =
		"*chuckles* You look like you think you're new here. Don't worry, we've all been there. "
		.. "Not like I was born here, but I know the ropes. *gestures around* "
		.. "Just keep your head down and stay out of trouble, alright?<br><br>"
		.. " *leans in slightly* "
		.. "And don't worry too much about death not being the end here. You'll get used to it.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_1_TRACKER:IsInProgress(player)
			and not PLUGIN.MISSION_2_TRACKER:IsInProgress(player)
	end,
})

INTERACTION_START_MISSION2:RegisterResponse({
	answer = "What do I do now?",
	next = "mission_2_instructions",
	serverOnChoose = function(response, player, npcEntity)
		PLUGIN.MISSION_1_TRACKER:Complete(player)
		PLUGIN.MISSION_2_TRACKER:Start(player)
	end,
})

INTERACTION_START_MISSION2:RegisterResponse({
	answer = "I need to go now.",
})

--[[
	Explains Mission 2
--]]
local INTERACTION_MISSION2_INSTRUCTIONS = INTERACTION_SET_MISSION2:RegisterInteraction({
	uniqueID = "mission_2_instructions",

	text =
		"Alright, listen up. I've got something important for you. *pulls out a small device* "
		.. "This here is a Nano-Tech Injector. It's going to help you survive in this place.<br><br>"
		.. "Just use it on yourself, and you'll get a Nano Buff that will protect you from harm. "
		.. "*hands over the injector* "
		.. "Why don't you give it a try?<br><br>"
		.. "<span class=\"highlight\">Use the 'Newbie Nano-Tech Injector' item in your inventory to activate it.</span>",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		local character = player:GetCharacter()

		-- TODO: This means (like Runescape) we have a drop-trick. Do we want this?
		return PLUGIN.MISSION_2_TRACKER:IsInProgress(player)
			and not PLUGIN.MISSION_2_TRACKER_GOAL_1:CheckProgress(player)
			and not character:GetInventory():HasItem("newbie_nano_tech")
	end,
})

INTERACTION_MISSION2_INSTRUCTIONS:RegisterResponse({
	answer = "What are Nano Buffs?",
	next = "mission_2_nano_buffs",
})

INTERACTION_MISSION2_INSTRUCTIONS:RegisterResponse({
	answer = "Thanks, I'll try it out.",

	serverOnChoose = function(response, player, npcEntity)
		local character = player:GetCharacter()
		local itemUniqueID = "newbie_nano_tech"

		if (not character:GetInventory():Add(itemUniqueID, 1)) then
			ix.util.SchemaErrorNoHalt(
				"Should not happen, but player",
				player:GetName(),
				"could not receive item",
				itemUniqueID, "for mission 2."
			)

			player:Notify(
				"You do not have space in your inventory for the Nano-Tech Injector. Please make some space and talk to the NPC again."
			)

			return
		end
	end,
})

--[[
	Continues with expectation that item is yet to be used
--]]
local INTERACTION_MISSION2_NOT_USED_YET = INTERACTION_SET_MISSION2:RegisterInteraction({
	uniqueID = "mission_2_not_used_yet",

	text = "You haven't used the Nano-Tech Injector yet. It's important for your survival here.<br><br>"
		.. "<span class=\"highlight\">Use the 'Newbie Nano-Tech Injector' item in your inventory to activate it.</span>",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_2_TRACKER:IsInProgress(player)
			and not PLUGIN.MISSION_2_TRACKER_GOAL_1:CheckProgress(player)
	end,
})

INTERACTION_MISSION2_NOT_USED_YET:RegisterResponse({
	answer = "What are Nano Buffs?",
	next = "mission_2_nano_buffs",
})

INTERACTION_MISSION2_NOT_USED_YET:RegisterResponse({
	answer = "I'll use it now.",
})

--[[
	Explains Nano Buffs
--]]
local INTERACTION_MISSION2_NANO_BUFFS = INTERACTION_SET_MISSION2:RegisterInteraction({
	uniqueID = "mission_2_nano_buffs",

	text =
		"Nano Buffs are special enhancements that give you various abilities and protections. "
		.. "The one you'll get from the injector is a basic survival buff.<br><br>"
		..
		"You can <span class=\"highlight\">check your active Nano Buffs in the 'You' menu under the Nano Buffs tab.</span><br><br>"
		.. "There is positive and negative buffs, so beware of the negative ones!"
		.. "Remember, these buffs are temporary, so use them wisely and don't fret for too long about the negative ones.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_2_TRACKER:IsInProgress(player)
			and not PLUGIN.MISSION_2_TRACKER_GOAL_1:CheckProgress(player)
	end,
})

INTERACTION_MISSION2_NANO_BUFFS:RegisterResponse({
	answer = "Got it, thanks.",
})

--[[
	Continues with expectation that item has been used but not yet viewed
--]]
local INTERACTION_MISSION2_USED = INTERACTION_SET_MISSION2:RegisterInteraction({
	uniqueID = "mission_2_used",

	text = "Great! You've used the Nano-Tech Injector you should check your buffs now.<br><br>"
		.. "<span class=\"highlight\">Open the 'You' menu and go to the Nano Buffs tab to view your active buffs.</span>",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_2_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_2_TRACKER_GOAL_1:CheckProgress(player)
			and not PLUGIN.MISSION_2_TRACKER_GOAL_2:CheckProgress(player)
	end,
})

INTERACTION_MISSION2_USED:RegisterResponse({
	answer = "What are Nano Buffs?",
	next = "mission_2_nano_buffs",
})

INTERACTION_MISSION2_USED:RegisterResponse({
	answer = "I'll check them now.",
})

--[[
	Continues with expectation that item has been used and the player has viewed their buffs
--]]
local INTERACTION_MISSION2_USED_AND_VIEWED = INTERACTION_SET_MISSION2:RegisterInteraction({
	uniqueID = "mission_2_used_and_viewed",

	text = "Great! You're now familiar with checking your Nano buffs. "
		.. "However, that knowledge alone is not enough to survive out there. "
		.. "You need to make sure you're safe, and that means finding a secure spot to stay in.<br><br>"
		.. "*rummages through supplies* Ah, here it is! Take this 'Door Protector' item. It'll help you secure a room.<br><br>"
		..
		"<span class=\"highlight\">Find a room with a door you can lock, and use the 'Door Protector' item to secure it.</span>"
		.. "<br><br>"
		.. "After that, make sure to lock the door using the 'Keys' weapon you have equipped already.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_2_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_2_TRACKER_GOAL_2:CheckProgress(player)
			and not PLUGIN.MISSION_2_TRACKER_GOAL_3:CheckProgress(player)
	end,
})

INTERACTION_MISSION2_USED_AND_VIEWED:RegisterResponse({
	answer = "Is a Door Protector really necessary?",
	next = "mission_2_door_protectors",
})

INTERACTION_MISSION2_USED_AND_VIEWED:RegisterResponse({
	answer = "That sounds easy enough.",

	serverOnChoose = function(response, player, npcEntity)
		local character = player:GetCharacter()
		local itemUniqueID = "door_protector"

		if (not character:GetInventory():Add(itemUniqueID, 1)) then
			ix.util.SchemaErrorNoHalt(
				"Should not happen, but player",
				player:GetName(),
				"could not receive item",
				itemUniqueID, "for mission 2."
			)

			player:Notify(
				"You do not have space in your inventory for the Door Protector. Please make some space and talk to the NPC again."
			)

			return
		end

		-- TODO: We should give the player a temporary nano buff that prevents their door from getting shot open and prevents their BCU from being destroyed, so they can complete this mission quite safely.

		PLUGIN.MISSION_2_TRACKER_GOAL_3:Change(player, true)
	end,
})

--[[
	Explains the door protector in more detail
--]]
local INTERACTION_MISSION2_DOOR_PROTECTORS = INTERACTION_SET_MISSION2:RegisterInteraction({
	uniqueID = "mission_2_door_protectors",

	text =
		"The Door Protector is a simple device that helps secure a door against unwanted entry. "
		.. "It's not foolproof, but it adds an extra layer of security to keep you safe.<br><br>"
		..
		"Just find a room with a door you can lock, and use the 'Door Protector' item from your inventory on the door. "
		.. "Then, make sure to lock the door using the 'Keys' weapon you have equipped already.<br><br>"
		.. "Once you've done that, you'll have a relatively safe spot to retreat to if things get dangerous out there.<br><br>"
		.. "Take note however that doors may still be breached by determined attackers, so always stay vigilant.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_2_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_2_TRACKER_GOAL_2:CheckProgress(player)
			and not PLUGIN.MISSION_2_TRACKER_GOAL_3:CheckProgress(player)
	end,
})

INTERACTION_MISSION2_DOOR_PROTECTORS:RegisterResponse({
	answer = "Got it, thanks.",
	checkCanChoose = function(response, player, npcEntity)
		return PLUGIN.MISSION_2_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_2_TRACKER_GOAL_3:CheckProgress(player)
			and not PLUGIN.MISSION_2_TRACKER_GOAL_4:CheckProgress(player)
	end,
	next = "mission_2_used_and_viewed",
})

--[[
	Continues with expectation that item is yet to be used
--]]
local INTERACTION_MISSION2_NOT_USED_DOOR_PROTECTOR_YET = INTERACTION_SET_MISSION2:RegisterInteraction({
	uniqueID = "mission_2_not_used_door_protector_yet",

	text =
		"*looks around* You haven't used the Door Protector yet. You should really try to find a door to secure.<br><br>"
		.. "Once you've found a room with a door you can lock, "
		.. "<span class=\"highlight\">use the 'Door Protector' item from your inventory on the door.</span>",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_2_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_2_TRACKER_GOAL_3:CheckProgress(player)
			and not PLUGIN.MISSION_2_TRACKER_GOAL_4:CheckProgress(player)
	end,
})

INTERACTION_MISSION2_NOT_USED_DOOR_PROTECTOR_YET:RegisterResponse({
	answer = "What are Door Protectors?",
	next = "mission_2_door_protectors",
})

INTERACTION_MISSION2_NOT_USED_DOOR_PROTECTOR_YET:RegisterResponse({
	answer = "I'll find a door to use it on.",
})

--[[
	Continues with expectation that item is used, but the door is not locked
--]]
local INTERACTION_MISSION2_USED_DOOR_PROTECTOR = INTERACTION_SET_MISSION2:RegisterInteraction({
	uniqueID = "mission_2_used_door_protector",

	text =
		"Good job using the Door Protector. Now, I had a mate run by your place and check it out. "
		.. "He said it looks pretty secure, but you forgot to lock the door!<br><br>"
		.. "Make sure to use the 'Keys' weapon to lock the door once you've set up the Door Protector.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_2_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_2_TRACKER_GOAL_4:CheckProgress(player)
			and not PLUGIN.MISSION_2_TRACKER_GOAL_5:CheckProgress(player)
	end,
})

INTERACTION_MISSION2_USED_DOOR_PROTECTOR:RegisterResponse({
	answer = "Hnngh... I guess I'll get to it.",
})

INTERACTION_MISSION2_USED_DOOR_PROTECTOR:RegisterResponse({
	answer = "Fine",
})

--[[
	When the player returns to complete the mission, we give them a bit of money
--]]
local function claimReward2(response, player, npcEntity)
	PLUGIN.MISSION_2_TRACKER:Complete(player)

	local character = player:GetCharacter()
	local moneyToGive = 100

	character:GiveMoney(moneyToGive)

	PLUGIN.MISSION_3_TRACKER:Start(player)
end

local INTERACTION_MISSION2_COMPLETE = INTERACTION_SET_MISSION2:RegisterInteraction({
	uniqueID = "mission_2_complete",

	text =
		"Ah, I see you've secured your spot. Good job! You're getting the hang of this place already.<br><br>"
		.. "Here, take this small reward. It's not much, but it's a start.<br><br>"
		.. "*hands over some bolts*"
		.. "Keep it up, and you'll stay alive here for a while.<br><br>"
		.. "Come back and see me if you need more help, I've got something else that might interest you.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_2_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_2_TRACKER_GOAL_5:CheckProgress(player)
			and not PLUGIN.MISSION_2_TRACKER:IsCompleted(player)
	end,
})

INTERACTION_MISSION2_COMPLETE:RegisterResponse({
	answer = "Thanks for the reward!",
	serverOnChoose = claimReward2,
})

INTERACTION_MISSION2_COMPLETE:RegisterResponse({
	answer = "I appreciate it.",
	serverOnChoose = claimReward2,
})

--[[
    Mission 3: From Scrap to Bolts Interaction Set
--]]

local INTERACTION_SET_MISSION3 = NPC:RegisterInteractionSet({
	uniqueID = "mission_3_scrap_to_bolts",

	serverCheckShouldStart = function(interactionSet, player, npcEntity)
		return PLUGIN.MISSION_2_TRACKER:IsCompleted(player)
			and not PLUGIN.MISSION_3_TRACKER:IsCompleted(player)
	end,
})

--[[
	Starts Mission 3
--]]
local function startMission3(response, player, npcEntity)
	PLUGIN.MISSION_3_TRACKER_GOAL_1:Change(player, true)

	local beerItemTable = ix.item.Get("beer")

	local character = player:GetCharacter()
	character:GiveMoney(beerItemTable.price * (beerItemTable.shipmentSize or 1))
end

local INTERACTION_START_MISSION3 = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_start",

	text =
		"*looks around and leans in closer* "
		.. "Listen, you've got the basics down, but surviving here means more than just staying safe. "
		.. "You need to make some real bolts if you want to afford anything decent from The Business.<br><br>"
		.. "I've got something helpful, but it'll require your patience. A beer will help make the time go faster. "
		.. "*hands you some bolts* "
		.. "Buy some beers from 'The Business' - it's a store that sells all kinds of useful items... "
		.. "I wish everything there were as cheap as the beer.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_3_TRACKER:IsInProgress(player)
			and not PLUGIN.MISSION_3_TRACKER_GOAL_1:CheckProgress(player)
	end,
})

INTERACTION_START_MISSION3:RegisterResponse({
	answer = "What kind of useful items?",
	next = "mission_3_shop_items",
})

INTERACTION_START_MISSION3:RegisterResponse({
	answer = "I'll go buy that beer.",
	serverOnChoose = startMission3,
})

--[[
	Explains shop items and rants about The Business
--]]
local INTERACTION_MISSION3_SHOP_ITEMS = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_shop_items",

	text =
		"*gestures wildly* Oh where do I even start? They've got weapons, armor, medical supplies, tools... "
		.. "even fancy gadgets that'll make your life easier. But the prices! *scoffs* "
		.. "The Business acts like they own this place. Well, I guess they practically do.<br><br>"
		.. "They control most of the trade around here, set the prices however they want. "
		.. "Used to be independent traders, but The Business bought them out or... convinced them to leave.<br><br>"
		.. "Still, we need what they're selling, so we play their game.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- no direct start, only come here when a response directs us here
	end,
})

INTERACTION_MISSION3_SHOP_ITEMS:RegisterResponse({
	answer = "Sounds like a monopoly.",
	next = "mission_3_monopoly_talk",
})

INTERACTION_MISSION3_SHOP_ITEMS:RegisterResponse({
	answer = "I'll go buy that beer now.",
	serverOnChoose = startMission3,
})

--[[
	More lore about The Business
--]]
local INTERACTION_MISSION3_MONOPOLY_TALK = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_monopoly_talk",

	text =
		"*nods grimly* Exactly what it is. They came here claiming they'd bring order and prosperity. "
		.. "Sure, they brought order... their order. And prosperity? Well, they're certainly prospering.<br><br>"
		.. "But enough about them. You need to focus on building your own wealth. "
		.. "Go get that beer, and we'll talk about how to make some real bolts.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- no direct start, only come here when a response directs us here
	end,
})

INTERACTION_MISSION3_MONOPOLY_TALK:RegisterResponse({
	answer = "I'll get that beer.",
	serverOnChoose = startMission3,
})

--[[
	Waiting for player to buy beer
--]]
local INTERACTION_MISSION3_BUY_BEER = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_buy_beer",

	text =
		"Go on, buy that beer from The Business. It's just down the way from here. "
		.. "Don't take too long - we've got important things to discuss.<br><br>"
		.. "<span class=\"highlight\">Find The Business shop and buy a beer.</span>",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_3_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_3_TRACKER_GOAL_1:CheckProgress(player)
			and not PLUGIN.MISSION_3_TRACKER_GOAL_2:CheckProgress(player)
	end,
})

INTERACTION_MISSION3_BUY_BEER:RegisterResponse({
	answer = "What kind of useful items does The Business sell?",
	next = "mission_3_shop_items",
})

INTERACTION_MISSION3_BUY_BEER:RegisterResponse({
	answer = "How do I use shops?",
	next = "mission_3_shop_help",
})

INTERACTION_MISSION3_BUY_BEER:RegisterResponse({
	answer = "I'll be right back.",
})

--[[
	Shop mechanics help
--]]
local INTERACTION_MISSION3_SHOP_HELP = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_shop_help",

	text = function()
		local useBind = Schema.util.LookupBinding("+use", true)

		return "Simple enough. Walk up to one of those robotic shop keepers, "
			.. "<span class=\"highlight\">look at them and press " .. useBind .. ".</span>"
			.. "You'll see a list of items for sale with their prices. "
			.. "Just click on what you want to buy and confirm. "
			.. "They should sell it to you as long as you have enough bolts."
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- no direct start, only come here when a response directs us here
	end,
})

INTERACTION_MISSION3_SHOP_HELP:RegisterResponse({
	answer = "Got it, thanks.",
})

--[[
	Player bought beer, now drink it
--]]
local INTERACTION_MISSION3_DRINK_BEER = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_drink_beer",

	text =
		"Good, you got the beer! Now drink it up, it'll help pass the time while we talk business.<br><br>"
		.. "*coughs* Pun intended.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_3_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_3_TRACKER_GOAL_2:CheckProgress(player)
			and not PLUGIN.MISSION_3_TRACKER_GOAL_3:CheckProgress(player)
	end,
})

-- INTERACTION_MISSION3_DRINK_BEER:RegisterResponse({
-- 	answer = "How do I use items again?",
-- 	next = "mission_3_item_help",
-- })

INTERACTION_MISSION3_DRINK_BEER:RegisterResponse({
	answer = "Cheers!",
})

-- --[[
-- 	Item usage help
-- --]]
-- local INTERACTION_MISSION3_ITEM_HELP = INTERACTION_SET_MISSION3:RegisterInteraction({
-- 	uniqueID = "mission_3_item_help",

-- 	text =
-- 		"Right-click on the item in your inventory and select 'Use' or just double-click it. "
-- 		.. "Some items have different options when you right-click them.<br><br>"
-- 		.. "The beer should be straightforward - just consume it.",

-- 	serverCheckShouldStart = function(interaction, player, npcEntity)
-- 		return false -- no direct start, only come here when a response directs us here
-- 	end,
-- })

-- INTERACTION_MISSION3_ITEM_HELP:RegisterResponse({
-- 	answer = "Thanks for the reminder.",
-- })

--[[
	Player drank beer, now check if they have a safe place
--]]
local INTERACTION_MISSION3_SAFE_PLACE_CHECK = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_safe_place_check",

	text =
		"*relaxes slightly* Good, that's the spirit! Now, before we get into the serious business of making bolts, "
		.. "I need to know - do you have a safe place? An apartment or room with a door you can lock?<br><br>"
		.. "What I'm about to teach you involves valuable equipment, and you'll need somewhere secure to keep it.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_3_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_3_TRACKER_GOAL_3:CheckProgress(player)
			and not PLUGIN.MISSION_3_TRACKER_GOAL_4:CheckProgress(player)
			and not Schema.progression.Check(
				player,
				PLUGIN.uniqueID,
				PLUGIN.PROGRESSION_MISSION_3_PLACE_BCU_GOT_SCRAP,
				true
			)
	end,
})

INTERACTION_MISSION3_SAFE_PLACE_CHECK:RegisterResponse({
	answer = "Yes, I have a secured room.",
	next = "mission_3_explain_bcu",
})

INTERACTION_MISSION3_SAFE_PLACE_CHECK:RegisterResponse({
	answer = "No, I don't have anywhere safe.",
	next = "mission_3_no_safe_place",
})

--[[
	Player doesn't have safe place - redirect them
--]]
local INTERACTION_MISSION3_NO_SAFE_PLACE = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_no_safe_place",

	text =
		"*shakes head* Then you're not ready for this yet. "
		.. "Go find a room with a door, use a Door Protector on it, and lock it up tight. "
		.. "Come back when you've got a secure place to call your own.<br><br>"
		.. "I won't teach you about valuable equipment until you can keep it safe.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- no direct start, only come here when a response directs us here
	end,
})

INTERACTION_MISSION3_NO_SAFE_PLACE:RegisterResponse({
	answer = "Actually, I do have a safe place.",
	next = "mission_3_explain_bcu",
})

INTERACTION_MISSION3_NO_SAFE_PLACE:RegisterResponse({
	answer = "I'll find a safe place.",
})

--[[
	Explains BCU and bolt generation
--]]
local function goPlaceBcu(response, player, npcEntity)
	local character = player:GetCharacter()

	if (not character:GetInventory():Add("scrap", 2)) then
		ix.util.SchemaErrorNoHalt("Player", player:GetName(), "could not receive scrap for mission 3.")

		player:Notify(
			"You do not have space in your inventory for the scrap item. Please make some space and talk to the NPC again."
		)

		return
	end

	Schema.progression.Change(player, PLUGIN.uniqueID, PLUGIN.PROGRESSION_MISSION_3_PLACE_BCU_GOT_SCRAP, true)
end

local INTERACTION_MISSION3_EXPLAIN_BCU = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_explain_bcu",

	text =
		"Perfect! You should already have a Bolt Control Unit in your inventory. We call it a BCU for short. "
		.. "It's the key to generating steady income around here. The BCU converts scrap into bolts over time.<br><br>"
		.. "*hands you some scrap* "
		.. "Take the BCU to your secured room and place it somewhere safe. It'll start with zero power, "
		.. "so you'll need to recharge it with this scrap I'm giving you.<br><br>"
		.. "<span class=\"highlight\">Go to your secured room and place the BCU.</span><br><br>"
		.. "Once it's placed, interact with it and add the scrap to recharge it. "
		.. "You can find more scrap by scavenging around, which I can explain later if you like.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_3_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_3_TRACKER_GOAL_3:CheckProgress(player)
			and not PLUGIN.MISSION_3_TRACKER_GOAL_4:CheckProgress(player)
			and not Schema.progression.Check(
				player,
				PLUGIN.uniqueID,
				PLUGIN.PROGRESSION_MISSION_3_PLACE_BCU_GOT_SCRAP,
				true
			)
	end,
})

INTERACTION_MISSION3_EXPLAIN_BCU:RegisterResponse({
	answer = "How does the BCU work exactly?",
	next = "mission_3_bcu_details",
})

INTERACTION_MISSION3_EXPLAIN_BCU:RegisterResponse({
	answer = "I'll go place it now.",
	serverOnChoose = goPlaceBcu,
})

--[[
	BCU mechanics explanation
--]]
local INTERACTION_MISSION3_BCU_DETAILS = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_bcu_details",

	text =
		"The BCU is pretty straightforward. You feed it scrap, and it slowly converts that scrap into bolts. "
		.. "The more scrap you put in, the longer it runs.<br><br>"
		.. "Once it's running, you just wait. When it's done processing, you can withdraw the bolts it created. "
		.. "The basic BCU is slow, but you can upgrade it later for faster production and better efficiency.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- no direct start, only come here when a response directs us here
	end,
})

INTERACTION_MISSION3_BCU_DETAILS:RegisterResponse({
	answer = "Sounds useful. I'll set it up.",
	serverOnChoose = goPlaceBcu,
})

--[[
	Waiting for player to place BCU
--]]
local INTERACTION_MISSION3_PLACE_BCU = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_place_bcu",

	text =
		"Have you placed the BCU in your secured room yet? "
		.. "Make sure it's somewhere safe where other players can't easily access it.<br><br>"
		.. "<span class=\"highlight\">Place the BCU in your secured room.</span>",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_3_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_3_TRACKER_GOAL_3:CheckProgress(player)
			and not PLUGIN.MISSION_3_TRACKER_GOAL_4:CheckProgress(player)
	end,
})

INTERACTION_MISSION3_PLACE_BCU:RegisterResponse({
	answer = "Not yet, I'll go do that now.",
})

--[[
	BCU placed, now recharge it
--]]
local INTERACTION_MISSION3_RECHARGE_BCU = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_recharge_bcu",

	text =
		"Excellent! Now you need to recharge it with the scrap I gave you. "
		.. "Interact with the BCU and add the scrap to it. "
		.. "This will give it the power it needs to start producing bolts.<br><br>"
		.. "<span class=\"highlight\">Use the scrap to recharge your BCU.</span>",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_3_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_3_TRACKER_GOAL_4:CheckProgress(player)
			and not PLUGIN.MISSION_3_TRACKER_GOAL_5:CheckProgress(player)
	end,
})

INTERACTION_MISSION3_RECHARGE_BCU:RegisterResponse({
	answer = "I'll go recharge it.",
})

--[[
	BCU recharged, now get more scrap
--]]
local INTERACTION_MISSION3_GET_MORE_SCRAP = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_get_more_scrap",

	text =
		"Good! Your BCU should be running now. But you'll need more scrap to keep it going long-term. "
		.. "Time to learn about scavenging. Look around for scavenging points, they can be piles of rubbish, "
		.. "trash cans, or other interactive objects that look like they might contain useful items.<br><br>"
		.. "You might find more scrap, or other items you can break down into scrap.<br><br>"
		.. "<span class=\"highlight\">Find a scavenging point and scavenge for materials.</span><br><br>"
		.. "Once you've found a junk item, <span class=\"highlight\">right-click it in your inventory and select 'Scrap'.</span>",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_3_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_3_TRACKER_GOAL_5:CheckProgress(player)
			and not PLUGIN.MISSION_3_TRACKER_GOAL_6:CheckProgress(player)
	end,
})

INTERACTION_MISSION3_GET_MORE_SCRAP:RegisterResponse({
	answer = "Where can I find scavenging points?",
	next = "mission_3_scavenging_help",
})

INTERACTION_MISSION3_GET_MORE_SCRAP:RegisterResponse({
	answer = "I'll go look for some.",
})

--[[
	Scavenging help
--]]
local INTERACTION_MISSION3_SCAVENGING_HELP = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_scavenging_help",

	text =
		"Scavenging points are scattered around the area. Look for piles of debris, abandoned containers, "
		.. "or other interactive objects that look like they might contain useful items.<br><br>"
		.. "Just walk up to them and interact. You might find scrap directly, or other items that can be "
		.. "scrapped down into raw materials.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- no direct start, only come here when a response directs us here
	end,
})

INTERACTION_MISSION3_SCAVENGING_HELP:RegisterResponse({
	answer = "Thanks for the tip.",
})

--[[
	Player scavenged, now wait for production
--]]
local INTERACTION_MISSION3_WAIT_PRODUCTION = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_wait_production",

	text =
		"Perfect! You're getting the hang of this. Now comes the waiting game. "
		.. "Your BCU should be processing the scrap into bolts. Give it some time, then go back and "
		.. "check if it's produced any bolts yet.<br><br>"
		.. "When it's ready, interact with the BCU and withdraw the bolts it's created.<br><br>"
		.. "<span class=\"highlight\">Wait for your BCU to produce bolts, then withdraw them.</span>",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_3_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_3_TRACKER_GOAL_6:CheckProgress(player)
			and not PLUGIN.MISSION_3_TRACKER_GOAL_7:CheckProgress(player)
	end,
})

INTERACTION_MISSION3_WAIT_PRODUCTION:RegisterResponse({
	answer = "How long does it usually take?",
	next = "mission_3_production_time",
})

INTERACTION_MISSION3_WAIT_PRODUCTION:RegisterResponse({
	answer = "I'll check on it.",
})

--[[
	Production time explanation
--]]
local INTERACTION_MISSION3_PRODUCTION_TIME = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_production_time",

	text =
		"With a basic BCU, it takes a few minutes per bolt. Not the fastest, but it's reliable income "
		.. "that works even when you're offline doing other things.<br><br>"
		.. "As you earn more bolts, consider upgrading your BCU for faster production. "
		.. "Better units can produce bolts much quicker and more efficiently.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- no direct start, only come here when a response directs us here
	end,
})

INTERACTION_MISSION3_PRODUCTION_TIME:RegisterResponse({
	answer = "Good to know.",
})

--[[
	Player withdrew bolts, mission nearly complete
--]]
local function claimReward3(interaction, player, npcEntity)
	PLUGIN.MISSION_3_TRACKER:Complete(player)

	local character = player:GetCharacter()
	character:GiveMoney(100)
end

local INTERACTION_MISSION3_SUCCESS = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_success",

	text =
		"*grins widely* Excellent work! You've just earned your first self-made bolts. "
		.. "This is how you'll build real wealth around here - steady, reliable income from your BCU.<br><br>"
		.. "Remember to keep feeding it scrap, and consider upgrading it when you can afford to. "
		.. "The better your BCU, the faster you'll earn bolts.<br><br>",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_3_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_3_TRACKER_GOAL_7:CheckProgress(player)
			and not PLUGIN.MISSION_3_TRACKER:IsCompleted(player)
	end,
})

INTERACTION_MISSION3_SUCCESS:RegisterResponse({
	answer = "Thanks! I want to share this beer with you.",
	next = "mission_3_share_beer",
	serverOnChoose = claimReward3,
})

INTERACTION_MISSION3_SUCCESS:RegisterResponse({
	answer = "Thanks for teaching me!",
	next = "mission_3_final_advice",
	serverOnChoose = claimReward3,
})

--[[
	Player wants to share beer (reputation building)
--]]
local INTERACTION_MISSION3_SHARE_BEER = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_share_beer",

	text =
		"*eyes light up* Now that's the kind of gesture I appreciate! "
		.. "*takes the beer gratefully* You know, not many newcomers think to share their rewards. "
		.. "I'll remember this kindness.<br><br>"
		.. "You're going to do well here. Keep that generous spirit, but don't let anyone take advantage of it.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- no direct start, only come here when a response directs us here
	end,

	serverOnStart = function(interaction, player, npcEntity)
		local character = player:GetCharacter()
		local inventory = character:GetInventory()

		local beer = inventory:HasItem("beer")
		if (beer) then
			beer:Remove()
			Schema.progression.Change(player, PLUGIN.uniqueID, PLUGIN.PROGRESSION_MISSION_3_DRINK_SHARED, true)
		end
	end,
})

INTERACTION_MISSION3_SHARE_BEER:RegisterResponse({
	answer = "It's the least I can do.",
	next = "mission_3_final_advice",
})

--[[
	Final advice and encouragement
--]]
local INTERACTION_MISSION3_FINAL_ADVICE = INTERACTION_SET_MISSION3:RegisterInteraction({
	uniqueID = "mission_3_final_advice",

	text =
		"You've learned the basics of survival and earning around here. My advice? "
		.. "Upgrade that BCU as soon as you can afford it. The difference in production speed is worth every bolt.<br><br>"
		.. "Also, keep exploring. There are more advanced ways to make bolts, better equipment to find, "
		.. "and always more to learn about this place.<br><br>"
		.. "Stay safe out there, and remember - in this place, knowledge and preparation are your best weapons.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- no direct start, only come here when a response directs us here
	end,
})

INTERACTION_MISSION3_FINAL_ADVICE:RegisterResponse({
	answer = "I'll keep that in mind. Thanks for everything!",
})

-- TODO: Commented because for this to work it should be in a new interaction set (since INTERACTION_SET_MISSION3 ends after mission 3)

-- --[[
-- 	Generic post-mission interaction
-- --]]
-- local INTERACTION_MISSION3_POST_COMPLETE = INTERACTION_SET_MISSION3:RegisterInteraction({
-- 	uniqueID = "mission_3_post_complete",

-- 	text =
-- 		"*nods approvingly* Good to see you're still around and doing well. "
-- 		.. "How's that BCU treating you? Remember, upgrades are worth the investment when you can afford them.<br><br>"
-- 		.. "Keep scavenging, keep earning, and stay out of trouble with The Business... for now.",

-- 	serverCheckShouldStart = function(interaction, player, npcEntity)
-- 		return PLUGIN.MISSION_3_TRACKER:IsCompleted(player)
-- 	end,
-- })

-- INTERACTION_MISSION3_POST_COMPLETE:RegisterResponse({
-- 	answer = "Thanks for the advice.",
-- })

-- INTERACTION_MISSION3_POST_COMPLETE:RegisterResponse({
-- 	answer = "Any other tips for making bolts?",
-- 	next = "mission_3_bonus_tips",
-- })

-- --[[
-- 	Bonus tips for advanced players
-- --]]
-- local INTERACTION_MISSION3_BONUS_TIPS = INTERACTION_SET_MISSION3:RegisterInteraction({
-- 	uniqueID = "mission_3_bonus_tips",

-- 	text =
-- 		"*leans in conspiratorially* Well, since you're doing so well... "
-- 		.. "Keep an eye out for rare scrap types - some are worth much more than others. "
-- 		.. "And if you ever find blueprint fragments, hold onto them. "
-- 		.. "They can be used to craft better equipment or sold for serious bolts.<br><br>"
-- 		.. "Also, building relationships with other survivors can lead to trading opportunities. "
-- 		.. "Not everyone is out to get you... just most of them.",

-- 	serverCheckShouldStart = function(interaction, player, npcEntity)
-- 		return false -- no direct start, only come here when a response directs us here
-- 	end,
-- })

-- INTERACTION_MISSION3_BONUS_TIPS:RegisterResponse({
-- 	answer = "I'll keep that in mind.",
-- })
