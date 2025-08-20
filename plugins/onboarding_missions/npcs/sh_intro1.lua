local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

-- NPC Configuration
NPC.name = "Liam Vanderberg"
NPC.description = "A frail-looking man with a kind smile."
NPC.model = "models/hl2rp/citizens/male_10.mdl"
NPC.skin = 2
NPC.bodygroups = {
	[1] = 12, -- Odessa vest
	[2] = 7, -- Rebel pants with holsters
	[3] = 2, -- Fingerless gloves
	[4] = 2, -- Green beanie
}
NPC.voicePitch = 101

--[[
    Main FAQ Interaction Set
--]]

local INTERACTION_SET = NPC:RegisterInteractionSet({
	uniqueID = "liam_faq",

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
			"Well hello there, " ..
			player:Name() ..
			". *adjusts his worn beanie* I've been around these parts long enough to know a thing or two. What can this old fool help you with today?",
			"*looks up with tired but kind eyes* Oh, " ..
			player:Name() ..
			"! Don't mind the weathered face - I've seen better days, but I'm still kicking. Got any questions for an old timer like me?",
			"Ah, another soul looking for guidance. *chuckles dryly* Name's Liam, and despite what my appearance might suggest, I know my way around this place. What's troubling you, " ..
			player:Name() .. "?",
			"*straightens up slightly* " ..
			player:Name() ..
			", is it? I may look like I've been through the wringer - and believe me, I have - but there's still some wisdom left in this old noggin. How can I assist you?"
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
			"*nods knowingly* Ah yes, the inventory. Been fumbling around looking for your belongings, have you? " ..
			"*taps his temple with a gnarled finger* I remember when I first started carrying gear around here - took me ages to figure out the simple stuff.\n\n" ..
			"Listen carefully now: <span class=\"highlight\">Press " ..
			bindScore ..
			" once to toggle your inventory open and closed</span>. It'll be the first thing that pops up - can't miss it. " ..
			"Now here's a little trick I learned the hard way: if you want to keep that inventory open while you're doing other things, " ..
			"just <span class=\"highlight\">hold down " ..
			bindScore .. " and it'll stay open as long as you're holding it</span>.\n\n" ..
			"*chuckles softly* Simple once you know it, but Lord knows I spent half a day trying to figure that out when I was starting."
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
			"*straightens up and his expression grows more serious* Weapons, eh? *sighs heavily* Been handling firearms longer than I care to remember. " ..
			"Some lessons you learn the hard way, others... well, let me save you the trouble.\n\n" ..
			"First things first: <span class=\"highlight\">get to your inventory by pressing " ..
			bindScore .. "</span>. Find that weapon of yours in there - should be easy enough to spot. " ..
			"<span class=\"highlight\">Right-click on the weapon and select 'Equip'</span> from the menu that pops up.\n\n" ..
			"Now for the ammunition - and listen close because this is important - <span class=\"highlight\">find your ammo in the inventory, right-click on it, " ..
			"and select 'Load'</span>. Don't go trying to force things or you'll end up with problems.\n\n" ..
			"*looks down at his worn hands* Trust me on this one - I've made enough mistakes with weapons to know the proper way by now."
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
			"*his eyes grow distant for a moment* Raising your weapon... *shakes his head slowly* That's something I hoped I'd never have to teach anyone again. " ..
			"But these are hard times, and sometimes you need to be ready.\n\n" ..
			"First, you'll need to <span class=\"highlight\">switch to your weapon using " ..
			bindInvNext .. " and " .. bindInvPrevious .. "</span> - mess with those until you've got it selected. " ..
			"Then, when you need to be ready for trouble, <span class=\"highlight\">hold down the " ..
			bindReload .. " key to raise your weapon up</span>. " ..
			"Once it's raised you can let go of the key - it'll stay up until you either lower it or switch to something else.\n\n" ..
			"*looks directly at you with weary but serious eyes* Just... be careful with that thing, will you? " ..
			"I've seen too much trouble come from folks who weren't careful enough."
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_WEAPON_RAISE:RegisterResponse({
	answer = "I'll be careful. Thank you for the warning.",
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

		return "*nods approvingly* Smart question. Sometimes the best thing you can do is put the weapon away. " ..
			"*manages a small, sad smile* Wish more folks thought like that.\n\n" ..
			"Here's the thing - when you equip a weapon, it doesn't disappear from your inventory. It just gets marked with a little green indicator " ..
			"to show you it's currently equipped. Pretty handy system once you get used to it.\n\n" ..
			"To unequip it, just <span class=\"highlight\">press " ..
			bindScore .. " to open your inventory, find the weapon with the green marker, right-click on it, " ..
			"and select 'Unequip'</span>. Simple as that.\n\n" ..
			"*adjusts his vest absently* Sometimes the most important thing to know about a weapon is how to put it down properly."
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_WEAPON_UNEQUIP:RegisterResponse({
	answer = "Wise words. Thank you.",
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
			"*rubs his chin thoughtfully* Unloading ammo... now that's a practical skill. Sometimes you need to reorganize, " ..
			"sometimes you've got the wrong type loaded. *nods knowingly* Been there myself more times than I can count.\n\n" ..
			"It's a bit different from the regular inventory - you'll need to go to what they call the 'You' screen. " ..
			"<span class=\"highlight\">Press " ..
			bindScore ..
			" to open your inventory, then click on the 'You' tab</span>. That'll show you more detailed information about yourself and your gear.\n\n" ..
			"Look for the 'Equipped Ammunition' section - you'll see little icons for each type of ammo you've got loaded up. " ..
			"<span class=\"highlight\">Simply click on the ammo you want to unload and it'll go right back into your main inventory</span>.\n\n" ..
			"*chuckles softly* Took me a while to find that one. Sometimes the most useful features are hiding in plain sight."
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
			"*gives a weathered but warm smile* Glad I could help, " ..
			player:Name() .. ". Is there anything else this old timer can assist you with?",
			"Hope that cleared things up for you. *adjusts his beanie* Got any other questions rattling around in your head?",
			"*nods with satisfaction* Always feels good to help someone avoid the mistakes I made. Anything else you need to know?",
			"There you go - one less thing to worry about. *looks at you kindly* What else can I help you figure out?"
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
			"*tips his beanie slightly* Take care of yourself out there, " ..
			player:Name() ..
			". And remember - when in doubt, ask questions. Better to look foolish for a moment than to make a costly mistake.",
			"Safe travels, " ..
			player:Name() ..
			". *gives a gentle nod* You know where to find me if you need any more help from this old coot.",
			"*manages a genuine smile despite his tired features* Always a pleasure to help someone get their bearings. Don't be a stranger now, " ..
			player:Name() .. ".",
			"Off you go then. *waves slightly* Remember what I taught you, and you'll do just fine. Come back anytime you need guidance."
		}
		return table.Random(farewells)
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false -- Only accessed via response
	end,
})

INTERACTION_FAREWELL:RegisterResponse({
	answer = "Goodbye, Liam.",
})
