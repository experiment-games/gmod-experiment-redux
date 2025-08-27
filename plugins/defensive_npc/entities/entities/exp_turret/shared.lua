local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Experiment Turret"
ENT.Category = "Experiment Redux"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.IsDefensiveTurret = true

-- Configuration
ENT.DisabledDuration = 30 -- Seconds before turret respawns after being destroyed
ENT.MaxHealth = 500
ENT.DetectionRange = 500
ENT.EngageRange = 800
ENT.ThinkInterval = 0.1
ENT.UpdateTargetInterval = 1

function ENT:SetupDataTables()
	self:NetworkVar("Bool", "Disabled")
	self:NetworkVar("Bool", "PlayerDisabled")
	self:NetworkVar("String", "TurretType")
	self:NetworkVar("Int", "OwnerID")
	self:NetworkVar("Int", "TurretMode")
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

function ENT:GetModeDisplayName(client)
	local mode = self:GetTurretMode()
	local modeNames = {
		[PLUGIN.TURRET_MODES.DEFEND_ALL] = L("turretModeDefendAll", client),
		[PLUGIN.TURRET_MODES.DEFEND_OWNER] = L("turretModeDefendOwner", client),
		[PLUGIN.TURRET_MODES.DEFEND_ALLIANCE] = L("turretModeDefendAlliance", client),
		[PLUGIN.TURRET_MODES.DEFEND_AREA_OWNER] = L("turretModeDefendAreaOwner", client),
		[PLUGIN.TURRET_MODES.DEFEND_AREA_ALLIANCE] = L("turretModeDefendAreaAlliance", client)
	}

	return modeNames[mode] or "Unknown"
end
