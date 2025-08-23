local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

local INTERACTION_SET_MISSION2 = NPC:RegisterInteractionSet({
	uniqueID = "onboarding_mission",

	serverCheckShouldStart = function(interactionSet, player, npcEntity)
		local npcNameAlreadyStarted = Schema.progression.Get(player, PLUGIN.uniqueID, "npc")

		return PLUGIN.MISSION_1_TRACKER:IsInProgress(player)
			and not PLUGIN.MISSION_2_TRACKER:IsCompleted(player)
			-- Do not allow the player to continue with a different NPC
			and (
				not npcNameAlreadyStarted
				or npcNameAlreadyStarted == npcEntity:GetDisplayName()
			)
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

	serverOnStart = function(interaction, player, npcEntity)
		Schema.progression.Change(player, PLUGIN.uniqueID, "npc", npcEntity:GetDisplayName())
		Schema.entityMarker.UnmarkForPlayer(player, npcEntity)
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
		.. "*hands over some bolts* "
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
