local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

--[[
    Main FAQ Interaction Set
--]]

local INTERACTION_SET = NPC:RegisterInteractionSet({
	uniqueID = "faq",

	serverCheckShouldStart = function(interactionSet, player, npcEntity)
		return true -- Always allow interaction
	end,
})

--[[
    Main Greeting Interaction
--]]

local INTERACTION_GREETING = INTERACTION_SET:RegisterInteraction({
	uniqueID = "greeting",

	text = function(interaction, player, npcEntity)
		local greetings = {
			"Hello there, " ..
			player:Name() ..
			". I can help you with some basic questions about getting around. What would you like to know?",
			"Greetings, " ..
			player:Name() ..
			"! If you have any questions about surviving here, I'm here to help. What do you want to ask?",
			"Hi " ..
			player:Name() ..
			"! Need some guidance? I can help explain the basics. What would you like to learn about?"
		}
		return table.Random(greetings)
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return true -- Always available as the main greeting
	end,
})

-- Main Response Options
INTERACTION_GREETING:RegisterResponse({
	answer = "I have a question about weapons",
	next = "weapons_menu",
})

INTERACTION_GREETING:RegisterResponse({
	answer = "My question is about what is going on here",
	next = "situation_menu",
})

INTERACTION_GREETING:RegisterResponse({
	answer = "My question is about something else",
	next = "other_menu",
})

INTERACTION_GREETING:RegisterResponse({
	answer = "Thanks, I'm good for now.",
	next = "farewell",
})

--[[
    Weapons Menu Interaction
--]]

local INTERACTION_WEAPONS_MENU = INTERACTION_SET:RegisterInteraction({
	uniqueID = "weapons_menu",

	text = function(interaction, player, npcEntity)
		return "Ah, weapons! Essential for survival in this place. What specifically would you like to know about weapons?"
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_WEAPONS_MENU:RegisterResponse({
	answer = "How do I get to my inventory?",
	next = "inventory_help",
})

INTERACTION_WEAPONS_MENU:RegisterResponse({
	answer = "How do I equip my weapon and load it with ammo?",
	next = "weapon_equip_help",
})

INTERACTION_WEAPONS_MENU:RegisterResponse({
	answer = "How can I raise my weapon?",
	next = "weapon_raise_help",
})

INTERACTION_WEAPONS_MENU:RegisterResponse({
	answer = "How do I unequip my weapon?",
	next = "weapon_unequip_help",
})

INTERACTION_WEAPONS_MENU:RegisterResponse({
	answer = "Can I unload ammo?",
	next = "ammo_unload_help",
})

INTERACTION_WEAPONS_MENU:RegisterResponse({
	answer = "I have a question about a different topic",
	next = "greeting",
})

--[[
    Situation Menu Interaction
--]]

local INTERACTION_SITUATION_MENU = INTERACTION_SET:RegisterInteraction({
	uniqueID = "situation_menu",

	text = function(interaction, player, npcEntity)
		return "The situation here? Well, it's... complicated. This city isn't what it used to be. What would you like to know?"
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_SITUATION_MENU:RegisterResponse({
	answer = "What is up with all those monitors around here?",
	next = "monitors_explanation",
})

INTERACTION_SITUATION_MENU:RegisterResponse({
	answer = "How did I just spawn into existence?",
	next = "spawning_explanation",
})

INTERACTION_SITUATION_MENU:RegisterResponse({
	answer = "I have a question about a different topic",
	next = "greeting",
})

--[[
    Other Menu Interaction
--]]

local INTERACTION_OTHER_MENU = INTERACTION_SET:RegisterInteraction({
	uniqueID = "other_menu",

	text = function(interaction, player, npcEntity)
		return "Of course! There's plenty more to know about surviving in this place. What else can I help you with?"
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_OTHER_MENU:RegisterResponse({
	answer = "What happens when I die?",
	next = "death_explanation",
})

INTERACTION_OTHER_MENU:RegisterResponse({
	answer = "What is the Locker Rot Virus?",
	next = "locker_rot_explanation",
})

INTERACTION_OTHER_MENU:RegisterResponse({
	answer = "I have a question about a different topic",
	next = "greeting",
})

--[[
    Monitors Explanation Interaction
--]]

local INTERACTION_MONITORS = INTERACTION_SET:RegisterInteraction({
	uniqueID = "monitors_explanation",

	text = function(interaction, player, npcEntity)
		return "Those monitors? Oh they belong to the AI that has laid its dominion over this city. " ..
			"It calls itself Nemesis AI. I don't really recall how it all began, but from what I've heard " ..
			"it was supposedly not always as violent as it is now."
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_MONITORS:RegisterResponse({
	answer = "That's unsettling. Tell me more about the situation.",
	next = "situation_menu",
})

INTERACTION_MONITORS:RegisterResponse({
	answer = "I see. Can you help me with something else?",
	next = "greeting",
})

--[[
    Spawning Explanation Interaction
--]]

local INTERACTION_SPAWNING = INTERACTION_SET:RegisterInteraction({
	uniqueID = "spawning_explanation",

	text = function(interaction, player, npcEntity)
		return "Isn't that a question we'd all like answered! I wouldn't be able to tell you how, " ..
			"but I can tell you that the AI has something to do with it for sure."
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_SPAWNING:RegisterResponse({
	answer = "The AI is behind this too? What else should I know?",
	next = "situation_menu",
})

INTERACTION_SPAWNING:RegisterResponse({
	answer = "Interesting. Can you help me with other questions?",
	next = "greeting",
})

--[[
    Death Explanation Interaction
--]]

local INTERACTION_DEATH = INTERACTION_SET:RegisterInteraction({
	uniqueID = "death_explanation",

	text = function(interaction, player, npcEntity)
		return "Strangely in this place there is no escaping, not even in death. However there are consequences. " ..
			"You'll lose weapons you had on you, and perhaps some items and bolts too.\n\n" ..
			"We've found that any armor or clothes you were wearing don't get lost though. " ..
			"Somehow they get teleported away and when we spawn again they get put back on us. Strange huh?"
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_DEATH:RegisterResponse({
	answer = "That's both reassuring and disturbing. What else should I know?",
	next = "other_menu",
})

INTERACTION_DEATH:RegisterResponse({
	answer = "Good to know. Can you help me with something else?",
	next = "greeting",
})

--[[
    Locker Rot Explanation Interaction
--]]

local INTERACTION_LOCKER_ROT = INTERACTION_SET:RegisterInteraction({
	uniqueID = "locker_rot_explanation",

	text = function(interaction, player, npcEntity)
		return "Hmm, that is something you don't want to have happen to you. However if you draw attention to yourself, " ..
			"Nemesis AI will most definitely infect your locker with it.\n\n" ..
			"The Locker Rot Virus infects items in your locker. While it is active a different locker will be setup with the anti-virus. " ..
			"You'll have to run around the city with your possibly expensive items on you to the locker with the anti-virus.\n\n" ..
			"During this event, Nemesis AI will rile up the others in town to try and steal those items from you. " ..
			"It's a pain in the ass is what it is, but it keeps things exciting."
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_LOCKER_ROT:RegisterResponse({
	answer = "That sounds terrifying! What else should I be aware of?",
	next = "other_menu",
})

INTERACTION_LOCKER_ROT:RegisterResponse({
	answer = "I'll try to stay under the radar. Any other tips?",
	next = "greeting",
})

--[[
    Inventory Help Interaction
--]]

local INTERACTION_INVENTORY = INTERACTION_SET:RegisterInteraction({
	uniqueID = "inventory_help",

	text = function(interaction, player, npcEntity)
		local bindScore = Schema.util.LookupBinding("+showscores", true)

		return
			"To access your inventory, you'll need to use the scores key. " ..
			"<span class=\"highlight\">Press " ..
			bindScore ..
			" once to toggle your inventory open and closed</span>.\n\n" ..
			"Here's a useful tip: if you want to keep the inventory open while doing other tasks, " ..
			"<span class=\"highlight\">hold down " ..
			bindScore .. " and it will stay open as long as you keep the key pressed</span>.\n\n" ..
			"This makes it easy to manage your items while moving around or interacting with the environment."
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_INVENTORY:RegisterResponse({
	answer = "That's very helpful, thank you!",
	next = "weapons_anything_else",
})

INTERACTION_INVENTORY:RegisterResponse({
	answer = "Can you help me with something else about weapons?",
	next = "weapons_menu",
})

--[[
    Weapon Equip Help Interaction
--]]

local INTERACTION_WEAPON_EQUIP = INTERACTION_SET:RegisterInteraction({
	uniqueID = "weapon_equip_help",

	text = function(interaction, player, npcEntity)
		local bindScore = Schema.util.LookupBinding("+showscores", true)

		return
			"Equipping weapons and loading ammunition is straightforward once you know the steps.\n\n" ..
			"First, <span class=\"highlight\">open your inventory by pressing " ..
			bindScore .. "</span>. Locate the weapon you want to equip. " ..
			"<span class=\"highlight\">Right-click on the weapon and select 'Equip'</span> from the context menu.\n\n" ..
			"To load ammunition: <span class=\"highlight\">find your ammo in the inventory, right-click on it, " ..
			"and select 'Load'</span>. The ammunition will be loaded into your equipped weapon.\n\n" ..
			"Make sure you have the correct ammunition type for your weapon, as different weapons require different ammo."
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_WEAPON_EQUIP:RegisterResponse({
	answer = "I understand. Thank you for the guidance.",
	next = "weapons_anything_else",
})

INTERACTION_WEAPON_EQUIP:RegisterResponse({
	answer = "What about other weapon questions?",
	next = "weapons_menu",
})

--[[
    Weapon Raise Help Interaction
--]]

local INTERACTION_WEAPON_RAISE = INTERACTION_SET:RegisterInteraction({
	uniqueID = "weapon_raise_help",

	text = function(interaction, player, npcEntity)
		local bindInvNext = Schema.util.LookupBinding("invnext", true)
		local bindInvPrevious = Schema.util.LookupBinding("invprev", true)
		local bindReload = Schema.util.LookupBinding("reload", true)

		return
			"To raise your weapon into a ready position, follow these steps:\n\n"
			.. "First, <span class=\"highlight\">switch to your weapon using "
			.. bindInvNext
			.. " and " .. bindInvPrevious
			.. "</span> to cycle through your items until the weapon is selected.\n\n"
			.. "Then, <span class=\"highlight\">hold down the "
			.. bindReload .. " key to raise your weapon</span>. "
			.. "Once raised, you can release the key and the weapon will remain in the ready position.\n\n"
			.. "The weapon will stay raised until you lower it manually or switch to a different item."
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_WEAPON_RAISE:RegisterResponse({
	answer = "Got it. Thank you for the explanation.",
	next = "weapons_anything_else",
})

INTERACTION_WEAPON_RAISE:RegisterResponse({
	answer = "Any other weapon tips?",
	next = "weapons_menu",
})

--[[
    Weapon Unequip Help Interaction
--]]

local INTERACTION_WEAPON_UNEQUIP = INTERACTION_SET:RegisterInteraction({
	uniqueID = "weapon_unequip_help",

	text = function(interaction, player, npcEntity)
		local bindScore = Schema.util.LookupBinding("+showscores", true)

		return "Unequipping weapons is simple once you understand how the system works.\n\n" ..
			"When you equip a weapon, it remains in your inventory but gets marked with a green indicator " ..
			"to show that it's currently equipped.\n\n" ..
			"To unequip it: <span class=\"highlight\">press " ..
			bindScore .. " to open your inventory, find the weapon with the green marker, right-click on it, " ..
			"and select 'Unequip'</span>.\n\n" ..
			"The weapon will remain in your inventory but will no longer be equipped for use."
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_WEAPON_UNEQUIP:RegisterResponse({
	answer = "That makes sense. Thank you.",
	next = "weapons_anything_else",
})

INTERACTION_WEAPON_UNEQUIP:RegisterResponse({
	answer = "I have more weapon questions.",
	next = "weapons_menu",
})

--[[
    Ammo Unload Help Interaction
--]]

local INTERACTION_AMMO_UNLOAD = INTERACTION_SET:RegisterInteraction({
	uniqueID = "ammo_unload_help",

	text = function(interaction, player, npcEntity)
		local bindScore = Schema.util.LookupBinding("+showscores", true)

		return
			"Unloading ammunition requires accessing a different section of your interface.\n\n" ..
			"<span class=\"highlight\">Press " ..
			bindScore ..
			" to open your inventory, then click on the 'You' tab</span>. This displays detailed information about your character and equipped items.\n\n" ..
			"Look for the 'Equipped Ammunition' section, which shows icons for each type of ammunition you have loaded. " ..
			"<span class=\"highlight\">Click on the ammunition you want to unload and it will return to your main inventory</span>.\n\n" ..
			"This is useful for reorganizing your ammunition or switching to different ammo types."
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_AMMO_UNLOAD:RegisterResponse({
	answer = "That's exactly what I needed to know!",
	next = "weapons_anything_else",
})

INTERACTION_AMMO_UNLOAD:RegisterResponse({
	answer = "Any other weapon tips?",
	next = "weapons_menu",
})

--[[
    Weapons Anything Else Interaction
--]]

local INTERACTION_WEAPONS_ANYTHING_ELSE = INTERACTION_SET:RegisterInteraction({
	uniqueID = "weapons_anything_else",

	text = function(interaction, player, npcEntity)
		local responses = {
			"I hope that weapon information was helpful, " ..
			player:Name() .. ". Is there anything else about weapons you'd like to know?",
			"Glad I could help with that weapon question. Any other weapon-related queries?",
			"That should help you handle your weapons better. What else would you like to learn about weapons?",
			"Weapons can be tricky at first. Any other weapon questions, " .. player:Name() .. "?"
		}
		return table.Random(responses)
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_WEAPONS_ANYTHING_ELSE:RegisterResponse({
	answer = "Yes, I have more weapon questions.",
	next = "weapons_menu",
})

INTERACTION_WEAPONS_ANYTHING_ELSE:RegisterResponse({
	answer = "No, but I have other questions.",
	next = "greeting",
})

INTERACTION_WEAPONS_ANYTHING_ELSE:RegisterResponse({
	answer = "No, that's all for now. Thank you!",
	next = "farewell",
})

--[[
    General Anything Else Interaction
--]]

local INTERACTION_ANYTHING_ELSE = INTERACTION_SET:RegisterInteraction({
	uniqueID = "anything_else",

	text = function(interaction, player, npcEntity)
		local responses = {
			"I hope that information was helpful, " ..
			player:Name() .. ". Is there anything else you'd like to know?",
			"Glad I could assist you. Do you have any other questions?",
			"That should help you get started. What else would you like to learn about?",
			"I'm here to help with any other questions you might have, " .. player:Name() .. "."
		}
		return table.Random(responses)
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_ANYTHING_ELSE:RegisterResponse({
	answer = "Yes, I have more questions.",
	next = "greeting",
})

INTERACTION_ANYTHING_ELSE:RegisterResponse({
	answer = "No, that's all for now. Thank you!",
	next = "farewell",
})

--[[
    Farewell Interaction
--]]

local INTERACTION_FAREWELL = INTERACTION_SET:RegisterInteraction({
	uniqueID = "farewell",

	text = function(interaction, player, npcEntity)
		local farewells = {
			"You're welcome, " ..
			player:Name() ..
			". Feel free to come back if you need help with anything else. Stay safe out there.",
			"Happy to help, " ..
			player:Name() ..
			". Good luck surviving in this place!",
			"Take care, " ..
			player:Name() ..
			". Don't hesitate to ask if you have more questions later. And watch out for Nemesis AI.",
			"Glad I could assist you. Have a great day, " .. player:Name() .. "! Try to keep a low profile."
		}
		return table.Random(farewells)
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_FAREWELL:RegisterResponse({
	answer = "Goodbye.",
})
