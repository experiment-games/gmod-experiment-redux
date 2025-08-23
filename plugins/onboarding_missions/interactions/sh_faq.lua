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
			"! I'm here to assist with common questions. How can I help you today?",
			"Welcome, " ..
			player:Name() ..
			". I've got answers to frequently asked questions. What's on your mind?",
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

-- FAQ Response Options
INTERACTION_GREETING:RegisterResponse({
	answer = "How do I get to my inventory?",
	next = "inventory_help",
})

INTERACTION_GREETING:RegisterResponse({
	answer = "How do I equip my weapon and load it with ammo?",
	next = "weapon_equip_help",
})

INTERACTION_GREETING:RegisterResponse({
	answer = "How can I raise my weapon?",
	next = "weapon_raise_help",
})

INTERACTION_GREETING:RegisterResponse({
	answer = "How do I unequip my weapon?",
	next = "weapon_unequip_help",
})

INTERACTION_GREETING:RegisterResponse({
	answer = "Can I unload ammo?",
	next = "ammo_unload_help",
})

INTERACTION_GREETING:RegisterResponse({
	answer = "Thanks, I'm good for now.",
	next = "farewell",
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
	next = "anything_else",
})

INTERACTION_INVENTORY:RegisterResponse({
	answer = "Can you help me with something else?",
	next = "greeting",
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
	next = "anything_else",
})

INTERACTION_WEAPON_EQUIP:RegisterResponse({
	answer = "What about other weapon questions?",
	next = "greeting",
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
	next = "anything_else",
})

INTERACTION_WEAPON_RAISE:RegisterResponse({
	answer = "Any other weapon tips?",
	next = "greeting",
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
	next = "anything_else",
})

INTERACTION_WEAPON_UNEQUIP:RegisterResponse({
	answer = "I have more questions.",
	next = "greeting",
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
	next = "anything_else",
})

INTERACTION_AMMO_UNLOAD:RegisterResponse({
	answer = "Any other tips?",
	next = "greeting",
})

--[[
    Anything Else Interaction
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
			". Feel free to come back if you need help with anything else.",
			"Happy to help, " ..
			player:Name() ..
			". Good luck out there!",
			"Take care, " ..
			player:Name() ..
			". Don't hesitate to ask if you have more questions later.",
			"Glad I could assist you. Have a great day, " .. player:Name() .. "!"
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
