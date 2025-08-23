--- Client library that exposes functions to interact with NPCs.
--- It also has all functions a `CommonLibrary` has.
--- @class Schema.npc : CommonLibrary
Schema.npc = ix.util.GetOrCreateCommonLibrary("npc", function() return ix.util.NewMetaObject(Schema.meta.npc) end)

Schema.npc.NO_HEALTH = -1
Schema.npc.MAX_EDICT_BITS = 13

ix.chat.Register("npc", {
	CanSay = function(self, speaker, text)
		return not IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text, anonymous, data)
		local format = data.yelling and "%s yells \"%s\"" or "%s says \"%s\""

		chat.AddText(Color(255, 255, 255), format:format(data.name, text))
	end,
})

--- Checks if a player has completed an interaction, optionally within a scope (e.g: belonging to a quest/npc)
--- @param client Player
--- @param interaction any
--- @param scope? any
--- @return boolean
function Schema.npc.HasCompletedInteraction(client, interaction, scope)
	local character = client:GetCharacter()

	if (character) then
		local completed = character:GetData("npcInteractions", {})

		if (scope) then
			if (completed[interaction] and completed[interaction][scope]) then
				return true
			end
		else
			if (completed[interaction]) then
				return true
			end
		end
	end

	return false
end

--- Returns whether the player can manage NPC's and interactions
--- @param player Player
--- @return boolean
--- @realm shared
function Schema.npc.HasManagePermission(player)
	return ix.command.HasAccess(player, "NpcSpawn")
end

--- @realm shared
function Schema.npc.GetRandomVoiceSet(model)
	local randomVoiceLines = {
		"vo/npc/male01/excuseme01.wav",
		"vo/npc/male01/excuseme01.wav",
		"vo/npc/male01/excuseme01.wav",
		"vo/npc/male01/question19.wav",
		"vo/npc/male01/hi01.wav",
		"vo/npc/male01/hi01.wav",
		"vo/npc/male01/hi01.wav",
		"vo/npc/male01/hi01.wav",
		"vo/npc/male01/hi02.wav",
		"vo/npc/male01/hi02.wav",
		"vo/npc/male01/hi02.wav",
		"vo/npc/male01/hi02.wav",
		"vo/npc/male01/hi02.wav",
		"vo/npc/male01/hi02.wav",
		"vo/npc/male01/doingsomething.wav",
		"vo/npc/male01/answer18.wav"
	}

	if (model:find("female", nil, true) ~= nil) then
		for i = 1, #randomVoiceLines do
			randomVoiceLines[i] = randomVoiceLines[i]:gsub("male", "female")
		end
	end

	return randomVoiceLines
end
