DEFINE_BASECLASS("base_ai")

ENT.Base = "base_ai"
ENT.Type = "ai"
ENT.PrintName = "Experiment NPC"
ENT.Author = "Experiment Redux"
ENT.Category = "Experiment Redux"

ENT.Editable = true
ENT.Spawnable = false
ENT.AdminOnly = true

ENT.IsPassiveNPC = true

function ENT:SetupDataTables()
	self:NetworkVar("String", "DisplayName")
	self:NetworkVar("String", "Description")
	self:NetworkVar("String", "NpcId")
end

function ENT:SetAnim()
	if (self.expCachedIdleSequence) then
		return self:ResetSequence(self.expCachedIdleSequence)
	end

	local sequenceList = self:GetSequenceList()

	if (not sequenceList) then
		-- May happen on invalid model
		return
	end

	for k, v in ipairs(self:GetSequenceList()) do
		if (v:lower():find("idle") and v ~= "idlenoise") then
			self.expCachedIdleSequence = k
			return self:ResetSequence(k)
		end
	end

	if (self:GetSequenceCount() > 1) then
		self:ResetSequence(4)
	end
end
