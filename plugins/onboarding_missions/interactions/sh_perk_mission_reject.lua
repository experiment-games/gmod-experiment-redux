local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

--[[
	Rejects conversation if Mission 3 is not completed
--]]
local INTERACTION_REJECT_EARLY = NPC:RegisterInteractionSet({
	uniqueID = "reject_early_mission4",

	serverCheckShouldStart = function(interactionSet, player, npcEntity)
		-- Reject if Mission 3 is not completed
		return not PLUGIN.MISSION_3_TRACKER:IsCompleted(player)
	end,
})

local INTERACTION_NOT_READY = INTERACTION_REJECT_EARLY:RegisterInteraction({
	uniqueID = "not_ready",

	text = "*crosses arms and fixes you with a stern look* "
		.. "Listen up, rookie. I don't waste my time on people who aren't ready to take this seriously. "
		.. "*gestures dismissively* "
		.. "Come back when you've proven you can handle the basics. Until then, you're not worth my attention.<br><br>"
		.. "*turns slightly away, then glances back* "
		.. "And don't even think about wasting my time until you've mastered the fundamentals of survival here.",

	serverCheckShouldStart = function(interaction, player, npcEntity)
		return not PLUGIN.MISSION_3_TRACKER:IsCompleted(player)
	end,
})

INTERACTION_NOT_READY:RegisterResponse({
	answer = "I understand.",
})

INTERACTION_NOT_READY:RegisterResponse({
	answer = "I'll be back when I'm ready.",
})
