DEFINE_BASECLASS("exp_monster_base")

ENT.Base = "exp_monster_base"
ENT.Type = "ai"
ENT.PrintName = "Experiment Companion Base"
ENT.Author = "Experiment Redux"
ENT.Category = "Experiment Redux"

ENT.Spawnable = false
ENT.AdminOnly = true

ENT.IsCompanion = true

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Int", "ItemInstanceID")
	self:NetworkVar("String", "Command")
end
