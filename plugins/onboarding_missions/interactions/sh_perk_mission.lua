local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

local INTERACTION_SET_MISSION4 = NPC:RegisterInteractionSet({
	uniqueID = "onboarding_mission4",

	serverCheckShouldStart = function(interactionSet, player, npcEntity)
		-- Only start if Mission 3 is completed
		return PLUGIN.MISSION_3_TRACKER:IsCompleted(player)
	end,
})

--[[
	Starts Mission 4 - Invest in Survival
--]]
local INTERACTION_START_MISSION4 = INTERACTION_SET_MISSION4:RegisterInteraction({
	uniqueID = "startMission4",

	text = function()
		local npcNameMission2 = Schema.progression.Get(PLUGIN.uniqueID, "npc") or "That guy you talked to earlier"

		return "*straightens posture and nods approvingly* "
			.. "Now THIS is more like it. "
			.. npcNameMission2
			.. " told me you can handle the basics, and that earns you my respect. "
			.. "*places hands on hips confidently* "
			.. "But surviving out there? That takes more than just knowing how to lock a door and operate a BCU.<br><br>"
			.. "*leans forward slightly, speaking with intensity* "
			.. "What you need now are Perks "
			.. "- permanent augmentations to our programming that will keep you alive when everything else fails. "
			.. "*gestures emphatically* "
			.. "Are you ready to invest in your survival, "
			.. "or are you going to keep playing it safe until someone puts you in the ground?"
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_3_TRACKER:IsCompleted(player)
			and not PLUGIN.MISSION_4_TRACKER:IsInProgress(player)
	end,
})

INTERACTION_START_MISSION4:RegisterResponse({
	answer = "Tell me more about these Perks.",
	next = "explain_perks",
	serverOnChoose = function(response, player, npcEntity)
		PLUGIN.MISSION_4_TRACKER:Start(player)
	end,
})

INTERACTION_START_MISSION4:RegisterResponse({
	answer = "I'm ready to invest in survival.",
	next = "explain_perks",
	serverOnChoose = function(response, player, npcEntity)
		PLUGIN.MISSION_4_TRACKER:Start(player)
	end,
})

INTERACTION_START_MISSION4:RegisterResponse({
	answer = "I need to think about this.",
})

--[[
	Explains what Perks are and their benefits
--]]
local INTERACTION_EXPLAIN_PERKS = INTERACTION_SET_MISSION4:RegisterInteraction({
	uniqueID = "explain_perks",

	text = "*clasps hands behind back and paces slightly* "
		.. "Perks are what we call permanent augmentations to our programming. "
		.. "Think of them as upgrades to your very existence here. "
		.. "*stops and points decisively* "
		.. "These provide benefits ranging from an implanted chip that gives you discounts at 'The Business' - "
		.. "*taps temple with finger* "
		.. "to a headplate that gives you a small chance to take no damage at all when shot in the head.<br><br>"
		.. "*crosses arms and speaks seriously* "
		.. "Now, I won't lie to you - Perks are expensive. We're talking anywhere from 3,000 to 20,000 bolts. "
		.. "*gestures with open palm* "
		.. "But once you've saved up those bolts, it's worth every single one for investing in your survival.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false
	end,
})

INTERACTION_EXPLAIN_PERKS:RegisterResponse({
	answer = "What do you mean by 'augmentations to our programming'?",
	next = "explain_immortality",
})

INTERACTION_EXPLAIN_PERKS:RegisterResponse({
	answer = "How do I buy a perk?",
	next = "how_to_buy",
})

INTERACTION_EXPLAIN_PERKS:RegisterResponse({
	answer = "That's a lot of bolts...",
	next = "worth_investment",
})

--[[
	Explains the lore behind their immortality and augmentations
--]]
local INTERACTION_EXPLAIN_IMMORTALITY = INTERACTION_SET_MISSION4:RegisterInteraction({
	uniqueID = "explain_immortality",

	text = "*expression grows darker, gestures become more sharp and pointed* "
		.. "If you hadn't noticed by now, we've been 'blessed' with involuntary immortality. "
		.. "*makes air quotes sarcastically* "
		.. "That damned Nemesis AI keeps rebuilding us every time we die.<br><br>"
		.. "*waves hand dismissively* "
		.. "The immortality comes from some kind of DNA manipulation that I don't understand in the slightest - "
		.. "*leans forward intensely* "
		.. "and frankly, I don't care to understand it.<br><br>"
		.. "*straightens up and speaks with conviction* "
		.. "But what I DO know is this: it grants us access to augmentations that increase our chances of survival "
		.. "*clenches fist* "
		.. "and of winning the fights we choose to pick. That's knowledge worth having.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false
	end,
})

INTERACTION_EXPLAIN_IMMORTALITY:RegisterResponse({
	answer = "That's... unsettling.",
	next = "explain_perks",
})

INTERACTION_EXPLAIN_IMMORTALITY:RegisterResponse({
	answer = "How do I buy a perk?",
	next = "how_to_buy",
})

INTERACTION_EXPLAIN_IMMORTALITY:RegisterResponse({
	answer = "I understand now.",
	next = "explain_perks",
})

--[[
	Explains how to purchase perks
--]]
local INTERACTION_HOW_TO_BUY = INTERACTION_SET_MISSION4:RegisterInteraction({
	uniqueID = "how_to_buy",

	text = function(interaction, player, npcEntity)
		local bindKey = Schema.util.LookupBinding("+showscores", true)

		return "*points upward with authority* " ..
			"<span class=\"highlight\">Open the menu by pressing " ..
			bindKey .. ". Then navigate to the Perks section.</span>" ..
			"*makes decisive gesturing motions* " ..
			"Search through the available options or choose a perk that suits your survival strategy, " ..
			"then confirm the purchase.<br><br>" ..
			"*crosses arms and speaks sternly* " ..
			"It'll set you back a large sum of bolts, so pick wisely. " ..
			"*leans in slightly* " ..
			"Don't come crying to me if you waste your bolts on something useless. " ..
			"Think strategically about what will keep you alive longest."
	end,

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false
	end,
})

INTERACTION_HOW_TO_BUY:RegisterResponse({
	answer = "What do you recommend?",
	next = "perk_recommendations",
})

INTERACTION_HOW_TO_BUY:RegisterResponse({
	answer = "I need to save up more bolts first.",
	next = "worth_investment",
})

INTERACTION_HOW_TO_BUY:RegisterResponse({
	answer = "I'll go buy a perk now.",
})

--[[
	Emphasizes that the investment is worth it
--]]
local INTERACTION_WORTH_INVESTMENT = INTERACTION_SET_MISSION4:RegisterInteraction({
	uniqueID = "worth_investment",

	text = "*spreads arms wide, then brings them together decisively* "
		.. "Look, I get it. That amount of bolts feels like a mountain to climb right now. "
		.. "*points directly at player* "
		.. "But let me tell you something - every bolt you spend on a good perk is a bolt invested in NOT dying.<br><br>"
		.. "*paces with determination* "
		.. "You think those bolts are going to help you when someone's shooting at your head? "
		.. "*taps temple again* "
		.. "But a headplate perk? That might just save your life when it counts.<br><br>"
		.. "*stops and faces player directly* "
		.. "Stop thinking short-term. Start thinking survival.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false
	end,
})

INTERACTION_WORTH_INVESTMENT:RegisterResponse({
	answer = "How do I buy a perk again?",
	next = "how_to_buy",
})

INTERACTION_WORTH_INVESTMENT:RegisterResponse({
	answer = "You're right. I'll work towards buying one.",
})

--[[
	Gives perk recommendations
--]]
local INTERACTION_PERK_RECOMMENDATIONS = INTERACTION_SET_MISSION4:RegisterInteraction({
	uniqueID = "perk_recommendations",

	text = "*rubs chin thoughtfully, then gestures with conviction* "
		.. "For someone just starting out? I'd recommend focusing on survival fundamentals first. "
		.. "*counts on fingers* "
		.. "Damage reduction perks or economic advantages like the Business discount chip.<br><br>"
		.. "*leans forward with intensity* "
		.. "Avoid the flashy combat perks until you've mastered staying alive. "
		.. "*straightens up and crosses arms* "
		.. "What good is extra weapon damage if you're dead before you can use it?<br><br>"
		.. "*points decisively* "
		.. "But ultimately, YOU need to decide what fits your survival strategy. I can't hold your hand forever.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return false
	end,
})

INTERACTION_PERK_RECOMMENDATIONS:RegisterResponse({
	answer = "How do I access the perks menu again?",
	next = "how_to_buy",
})

INTERACTION_PERK_RECOMMENDATIONS:RegisterResponse({
	answer = "That makes sense. Thank you.",
})

--[[
	Mission incomplete - player hasn't bought a perk yet
--]]
local INTERACTION_MISSION_INCOMPLETE = INTERACTION_SET_MISSION4:RegisterInteraction({
	uniqueID = "mission_incomplete",

	text = "*looks at player expectantly, then crosses arms* "
		.. "Well? I don't see any new augmentations on you. "
		.. "*taps foot impatiently* "
		.. "You came back here without investing in a single perk? "
		.. "*gestures with mild frustration* "
		.. "I gave you the knowledge, I told you how to do it - now it's time for action.<br><br>"
		.. "*leans forward sternly* "
		.. "Stop wasting time and go make that investment in your survival. "
		.. "Come back when you've actually bought a perk and proven you're serious about staying alive.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_4_TRACKER:IsInProgress(player)
			and not PLUGIN.MISSION_4_TRACKER_GOAL_1:CheckProgress(player)
	end,
})

INTERACTION_MISSION_INCOMPLETE:RegisterResponse({
	answer = "What are perks again?",
	next = "explain_perks",
})

INTERACTION_MISSION_INCOMPLETE:RegisterResponse({
	answer = "I'll go buy one now.",
})

INTERACTION_MISSION_INCOMPLETE:RegisterResponse({
	answer = "I'm still saving up for a perk. Catch you later.",
})

--[[
	Mission complete - player has bought a perk
--]]
local function completeMission4(response, player, npcEntity)
	PLUGIN.MISSION_4_TRACKER:Complete(player)

	local character = player:GetCharacter()
	local moneyToGive = 500

	character:GiveMoney(moneyToGive)

	npcEntity:PrintChat("Here's a little something for your efforts. Bye!")
end

local INTERACTION_MISSION_COMPLETE = INTERACTION_SET_MISSION4:RegisterInteraction({
	uniqueID = "mission_complete",

	text = "*nods with clear approval and uncrosses arms* "
		.. "NOW I'm impressed. You've made a smart investment in your survival capabilities. "
		.. "*gestures approvingly* "
		.. "That perk will serve you well - it's the difference between the people who thrive here "
		.. "and the ones who keep dying over and over again.<br><br>"
		.. "*reaches into pocket* "
		.. "You've earned this reward, and more importantly, you've earned my respect. "
		.. "*straightens posture with pride* "
		.. "I can see you're serious about surviving in this place. "
		.. "Keep making smart decisions like this, "
		.. "and you might just become one of the survivors who makes it long-term in this place.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_4_TRACKER:IsInProgress(player)
			and PLUGIN.MISSION_4_TRACKER_GOAL_1:CheckProgress(player)
			and not PLUGIN.MISSION_4_TRACKER:IsCompleted(player)
	end,
})

INTERACTION_MISSION_COMPLETE:RegisterResponse({
	answer = "Thank you for the guidance.",
	serverOnChoose = completeMission4,
})

INTERACTION_MISSION_COMPLETE:RegisterResponse({
	answer = "I appreciate the respect I've earned.",
	serverOnChoose = completeMission4,
})

--[[
	Post-mission interactions for completed players
--]]
local INTERACTION_POST_MISSION = INTERACTION_SET_MISSION4:RegisterInteraction({
	uniqueID = "post_mission",

	text = "*nods respectfully* "
		.. "Good to see you again. You've proven you understand the importance of investing in survival. "
		.. "*gestures with measured approval* "
		.. "Keep building on that foundation - there are always more perks to acquire, more ways to improve your odds.<br><br>"
		.. "*crosses arms confidently* "
		.. "You're on the right path now. Don't let anyone convince you otherwise.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return PLUGIN.MISSION_4_TRACKER:IsCompleted(player)
	end,
})

INTERACTION_POST_MISSION:RegisterResponse({
	answer = "Any other advice?",
	next = "perk_recommendations",
})

INTERACTION_POST_MISSION:RegisterResponse({
	answer = "Thanks for everything.",
})
