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

local INTERACTION_SET = NPC:RegisterInteractionSet({
	uniqueID = "onboarding_mission",

	serverCheckShouldStart = function(interactionSet, player, npcEntity)
		return PLUGIN.MISSION_1_TRACKER:IsInProgress(player)
	end,
})

--[[
	Completes mission 1 and starts mission 2
--]]
local INTERACTION_START_MISSION2 = INTERACTION_SET:RegisterInteraction({
	uniqueID = "startMission2",

	text =
		"*chuckles* You look like you think you're new here. Don't worry, we've all been there. "
		.. "Not like I was born here, but I know the ropes. *gestures around* "
		.. "Just keep your head down and stay out of trouble, alright?"
		.. " *leans in slightly* "
		.. "And don't worry too much about death not being the end here. You'll get used to it.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_1_TRACKER:IsInProgress(player)
			and not PLUGIN.MISSION_2_TRACKER:IsInProgress(player)
	end,

	serverOnStart = function(interaction, player, npcEntity)
		PLUGIN.MISSION_1_TRACKER:Complete(player)
		PLUGIN.MISSION_2_TRACKER:Start(player)
	end,
})

INTERACTION_START_MISSION2:RegisterResponse({
	answer = "What do I do now?",
	next = "mission_2_instructions",
})

INTERACTION_START_MISSION2:RegisterResponse({
	answer = "I need to go now.",
})

--[[
	Explains Mission 2
--]]
local INTERACTION_MISSION2_INSTRUCTIONS = INTERACTION_SET:RegisterInteraction({
	uniqueID = "mission_2_instructions",

	text =
		"Alright, listen up. I've got something important for you. *pulls out a small device* "
		.. "This here is a Nano-Tech Injector. It's going to help you survive in this place.<br>"
		.. "Just use it on yourself, and you'll get a Nano Buff that will protect you from harm. "
		.. "*hands over the injector* "
		.. "Why don't you give it a try?<br>"
		.. "<span class=\"highlight\">Use the 'Newbie Nano-Tech Injector' item in your inventory to activate it.</span>",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		local character = player:GetCharacter()

		-- TODO: This means (like Runescape) we have a drop-trick. Do we want this?
		return PLUGIN.MISSION_2_TRACKER:IsInProgress(player)
			and not PLUGIN.MISSION_2_TRACKER_GOAL_1:CheckProgress(player)
			and not character:GetInventory():HasItem("newbie_nano_tech")
	end,

	serverOnStart = function(interaction, player, npcEntity)
		local character = player:GetCharacter()
		local itemUniqueID = "newbie_nano_tech"

		if (not character:GetInventory():Add(itemUniqueID, 1)) then
			ix.util.SchemaErrorNoHalt(
				"Should not happen, but player",
				player:GetName(),
				"could not receive item",
				itemUniqueID, "for mission 2."
			)
		end
	end,
})

INTERACTION_MISSION2_INSTRUCTIONS:RegisterResponse({
	answer = "What are Nano Buffs?",
	next = "mission_2_nano_buffs",
})

INTERACTION_MISSION2_INSTRUCTIONS:RegisterResponse({
	answer = "Thanks, I'll try it out.",
})

--[[
	Continues with expectation that item is yet to be used
--]]
local INTERACTION_MISSION2_NOT_USED_YET = INTERACTION_SET:RegisterInteraction({
	uniqueID = "mission_2_not_used_yet",

	text = "You haven't used the Nano-Tech Injector yet. It's important for your survival here.<br>"
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
local INTERACTION_MISSION2_NANO_BUFFS = INTERACTION_SET:RegisterInteraction({
	uniqueID = "mission_2_nano_buffs",

	text =
		"Nano Buffs are special enhancements that give you various abilities and protections. "
		.. "The one you'll get from the injector is a basic survival buff.<br>"
		..
		"You can <span class=\"highlight\">check your active Nano Buffs in the 'You' menu under the Nano Buffs tab.</span><br>"
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

-- TODO: Tutorial overlay explains how to use the item (explains Inventory mechanics again)
-- TODO: Tutorial overlay explains where to see Nano Buffs in 'You' menu (explains Nano Buffs)
-- TODO: Player continues conversation with NPC (must show as task goal on HUD)
-- TODO: NPC explains that staying behind a locked door is quite safe, until someone blasts their way in, but it should do for now.
-- TODO: NPC gives player 'Door Protector' item
-- TODO: Player gets Mission Goal to go setup 'Door Protector' on a door (teaches door mechanics)
-- TODO: Player gets Mission Goal to lock door using 'Keys' weapon (teaches door mechanics)
-- TODO: We should give the player a temporary nano buff that prevents their door from getting shot open and prevents their BCU from being destroyed, so they can complete this mission quite safely.
-- TODO: Player returns to NPC to complete mission and get a small reward
-- TODO: Auto-start follow-up introduction mission 3 (From Scrap to Bolts)
