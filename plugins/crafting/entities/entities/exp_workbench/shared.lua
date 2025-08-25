local PLUGIN = PLUGIN

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Category = "Experiment Redux"
ENT.PrintName = "Workbench"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("Bool", "InUse")
	self:NetworkVar("Float", "ProcessStartTime")
	self:NetworkVar("Float", "ProcessDuration")
end
