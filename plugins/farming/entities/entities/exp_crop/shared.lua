local PLUGIN = PLUGIN

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Category = "Experiment Redux"
ENT.PrintName = "Crop"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Int", "CropStage")
	self:NetworkVar("Bool", "IsWatered")
	self:NetworkVar("Bool", "IsFertilized")
	self:NetworkVar("Bool", "IsRotten")
	self:NetworkVar("String", "ItemID")
end

function ENT:GetItemTable()
	return ix.item.list[self:GetItemID()]
end
