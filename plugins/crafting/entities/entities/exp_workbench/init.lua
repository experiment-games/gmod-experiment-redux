local PLUGIN = PLUGIN

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/mosi/fnv/props/workstations/reloadingbench.mdl")
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
	net.Start("expWorkbenchMenu")
	net.WriteEntity(self)
	net.SendToServer(player)
end

function ENT:StartCombination(player, selectedItems, recipe)
	if (PLUGIN:IsStationBusy(self.stationID)) then
		return false
	end

	self:SetInUse(true)
	self:SetProcessStartTime(CurTime())
	self:SetProcessDuration(recipe.craftingTime or 45) -- Workbench takes longer

	PLUGIN:ProcessCombination(self.stationID, selectedItems, recipe, player:UserID())
	return true
end
