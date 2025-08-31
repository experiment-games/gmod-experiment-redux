DEFINE_BASECLASS("base_ai")

ENT.Base = "base_ai"
ENT.Type = "ai"
ENT.PrintName = "Experiment Monster Base"
ENT.Author = "Experiment Redux"
ENT.Category = "Experiment Redux"

ENT.Editable = true
ENT.Spawnable = false
ENT.AdminOnly = true

ENT.IsMonster = true

ENT.AutomaticFrameAdvance = true

MONSTER_CHAT_SAY = 1
MONSTER_CHAT_YELL = 2
MONSTER_CHAT_WHISPER = 3

ix.chat.Register("monster", {
	CanSay = function(self, speaker, text)
		return not IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text, anonymous, data)
		local format = data.yelling and "%s yells \"%s\"" or "%s says \"%s\""

		chat.AddText(Color(255, 55, 100), format:format(data.name, text))
	end,
})

function ENT:SetupDataTables()
	self:NetworkVar("String", "DisplayName")
end

hook.Add("ShouldCollide", "expDontCollideMonsters", function(entity, otherEntity)
	if (entity:IsNPC() and otherEntity:IsNPC()) then
		return false
	end
end)
