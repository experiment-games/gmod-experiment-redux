local PLUGIN = PLUGIN

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

ix.util.AddResourceSingleFile("materials/sprites/redglow8.vmt")

function ENT:Initialize()
	self:SetModel("models/props_lab/citizenradio.mdl")

	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetHealth(25)
	self:SetSolid(SOLID_VPHYSICS)

	local physicsObject = self:GetPhysicsObject()

	if (IsValid(physicsObject)) then
		physicsObject:Wake()
		physicsObject:EnableMotion(true)
	end
end

function ENT:SetupRadio(client, item)
	self:SetItemID(item.uniqueID)
	self.expClient = client
	self.expItemID = item.id

	self:SetFrequency(item:GetData("frequency", "101.1"))

	if (item.OnEntityCreated) then
		item:OnEntityCreated(self)
	end
end

function ENT:ChangeFrequency(frequency)
	local itemID = self.expItemID
	local itemTable = ix.item.instances[itemID]

	itemTable:SetData("frequency", frequency)
	self:SetFrequency(frequency)
	-- self:EmitSound("ambient/levels/prison/radio_random12.wav")
end

function ENT:OnDuplicated(entTable)
	local client = entTable.expClient
	local itemID = entTable.expItemID
	local itemTable = ix.item.instances[itemID]

	ix.item.Instance(0, itemTable.uniqueID, itemTable.data, 1, 1, function(item)
		self:SetupRadio(client, item)
	end)
end

function ENT:OnTakeDamage(damageInfo)
	self:SetHealth(math.max(self:Health() - damageInfo:GetDamage(), 0))

	if (self:Health() <= 0) then
		self:RemoveWithEffect()
	end
end

function ENT:Toggle()
	if (self:GetTurnedOff()) then
		self:SetTurnedOff(false)
	else
		self:SetTurnedOff(true)
	end
end

function ENT:OnOptionSelected(client, option, data)
	if (option == L("pickup", client)) then
		local character = client:GetCharacter()
		local inventory = character:GetInventory()
		inventory:Add(self.expItemID)
		self:Remove()
	elseif (option == L("setFrequency", client)) then
		if (Schema.util.Throttle("SetFrequency", 2, client)) then
			client:Notify("You must wait a moment before setting the frequency again!")
			return
		end

		local frequency = data
		local success, fault = PLUGIN:ValidateFrequency(frequency)

		if (not success) then
			return client:Notify(fault)
		end

		self:ChangeFrequency(frequency)
		hook.Run("PlayerSetFrequency", client, frequency, radio)

		client:Notify("You have set the frequency to " .. frequency .. ".")
	elseif (option == L("turnOff", client)) then
		self:SetTurnedOff(true)
	elseif (option == L("turnOn", client)) then
		self:SetTurnedOff(false)
	end
end
