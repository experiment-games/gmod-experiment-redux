local PLUGIN = PLUGIN

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/mosi/fnv/props/workstations/chemistrylab.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:Wake()
		phys:EnableMotion(false)
	end

	self.stationID = self:EntIndex()
end

function ENT:Use(activator, caller)
	if (not IsValid(caller) or not caller:IsPlayer()) then
		return
	end

	local character = caller:GetCharacter()
	if (not character) then
		return
	end

	local process = PLUGIN:GetStationProcess(self.stationID)

	if (process and process.completed) then
		-- Allow retrieval of completed items
		PLUGIN:CompleteStationProcess(self.stationID)
		self:SetInUse(false)
		caller:Notify("Items retrieved!")
		return
	elseif (PLUGIN:IsStationBusy(self.stationID)) then
		caller:Notify(L("stationInUse", caller))
		return
	end

	self:OpenCraftingMenu(caller)
end

function ENT:OpenCraftingMenu(player)
	net.Start("expChemistryStationMenu")
	net.WriteEntity(self)
	net.Send(player)
end

function ENT:StartDistillation(player, itemID)
	if (PLUGIN:IsStationBusy(self.stationID)) then
		return false
	end

	local item = ix.item.instances[itemID]
	if (not item or not item.craftingDistillation) then
		return false
	end

	self:SetInUse(true)
	self:SetProcessType("distillation")
	self:SetProcessStartTime(CurTime())
	self:SetProcessDuration(item.craftingDistillation.time)

	PLUGIN:ProcessDistillation(self.stationID, itemID, player:UserID())
	return true
end

function ENT:StartCombination(player, selectedItems, recipe)
	if (PLUGIN:IsStationBusy(self.stationID)) then
		return false
	end

	self:SetInUse(true)
	self:SetProcessType("combination")
	self:SetProcessStartTime(CurTime())
	self:SetProcessDuration(recipe.craftingTime or 30)

	PLUGIN:ProcessCombination(self.stationID, selectedItems, recipe, player:UserID())
	return true
end
