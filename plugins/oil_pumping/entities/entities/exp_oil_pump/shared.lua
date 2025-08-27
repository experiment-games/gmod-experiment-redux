local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Oil Pump"
ENT.Category = "Experiment Redux"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.IsOilPump = true
ENT.AutomaticFrameAdvance = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", "OwnerID")
	self:NetworkVar("Int", "OilAmount")
	self:NetworkVar("Int", "ScrapAmount")
	self:NetworkVar("Bool", "IsBroken")
	self:NetworkVar("Bool", "IsRunning")
	self:NetworkVar("Bool", "IsDisabled")
	self:NetworkVar("Entity", "AnimatedProp")
end

function ENT:GetOwnerName(client)
	local ownerID = self:GetOwnerID()

	if (ownerID == -1) then
		return false, false
	end

	local ownerName = CLIENT and L "someone" or L("someone", client)
	local character = ix.char.loaded[ownerID]
	local isOwner = false

	if (not client and CLIENT) then
		client = LocalPlayer()
	end

	if (character) then
		local ourCharacter = client:GetCharacter()

		if (ourCharacter and character and ourCharacter:DoesRecognize(character)) then
			ownerName = character:GetName()

			isOwner = ourCharacter:GetID() == character:GetID()
		end
	end

	return ownerName, isOwner
end

function ENT:GetOwnerCharacter()
	local ownerID = self:GetOwnerID()
	if (ownerID == -1) then
		return nil
	end

	return ix.char.loaded[ownerID]
end

function ENT:IsOwner(client)
	if (not IsValid(client) or not client:IsPlayer()) then
		return false
	end

	local character = client:GetCharacter()

	if (not character) then
		return false
	end

	return character:GetID() == self:GetOwnerID()
end
