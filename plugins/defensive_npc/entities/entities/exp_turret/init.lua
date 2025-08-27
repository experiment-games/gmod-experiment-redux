local PLUGIN = PLUGIN

include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

local CEILING_TURRET_EFFICIENT = 16
local FLOOR_TURRET_FAST_RETIRE = 128
local FLOOR_TURRET_CITIZEN_MODIFIED_FRIENDLY = 512

-- Network the mode change
util.AddNetworkString("ixTurretChangeMode")

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
	self:SetNoDraw(true)

	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetUseType(SIMPLE_USE)

	-- Initialize networked variables
	self:SetDisabled(false)
	self:SetPlayerDisabled(false)
	self:SetTurretMode(PLUGIN.TURRET_MODES.DEFEND_ALL) -- Default mode

	if (not self:GetTurretType()) then
		self:SetTurretType("floor") -- Default turret type
	end

	self:SetMaxHealth(self.MaxHealth)
	self:SetHealth(self.MaxHealth)

	-- Turret state
	self.currentTarget = nil
	self.lastThink = 0
	self.hostileTargets = {}
	self.lastHostileTime = {}
	self.areaTargets = {} -- For area defense modes

	-- Create the actual turret entity that does the shooting
	self:CreateTurretNPC()

	-- Set up physics
	local phys = self:GetPhysicsObject()

	if (IsValid(phys)) then
		phys:EnableMotion(false)
		phys:SetMass(1000)
	end
end

function ENT:CreateTurretNPC()
	-- Remove old turret if it exists
	if (IsValid(self.turretNPC)) then
		self.turretNPC:Remove()
	end

	local turretClass = "npc_turret_floor"

	if (self:GetTurretType() == "ceiling") then
		turretClass = "npc_turret_ceiling"
	end

	self.turretNPC = ents.Create(turretClass)
	self.turretNPC.OnOptionSelected = function(turret, ...)
		return self:OnOptionSelected(...)
	end
	self.turretNPC:SetPos(self:GetPos())
	self.turretNPC:SetAngles(self:GetAngles())
	self.turretNPC:SetParent(self)

	if (self:GetTurretType() == "ceiling") then
		self.turretNPC:SetKeyValue("spawnflags", CEILING_TURRET_EFFICIENT)
	end

	self.turretNPC:Spawn()
	self.turretNPC:Activate()
	self.turretNPC:Fire("Enable")
	self.turretNPC:SetSkin(1)
	self.turretNPC.expTurret = self -- Link back to this entity for targeting

	-- Don't be aggressive towards anything by default
	self.turretNPC:AddRelationship("player D_NU 99")

	for _, entity in ipairs(ents.FindInSphere(self:GetPos(), self.DetectionRange)) do
		self.turretNPC:AddEntityRelationship(entity, D_NU, 99)
	end

	self.turretNPC:CallOnRemove("RemoveTurretLogic", function(turretNPC)
		if (IsValid(self)) then
			self.turretNPC = nil
			self:Remove()
		end
	end)
end

function ENT:Think()
	local curTime = CurTime()

	if (curTime - self.lastThink < self.ThinkInterval) then
		return
	end

	self:NextThink(curTime + self.ThinkInterval)

	self.lastThink = curTime

	-- Handle disabled state
	if (self:GetDisabled()) then
		if (self.respawnTime and curTime >= self.respawnTime) then
			self:RespawnTurret()
		end

		return true
	end

	if (self:GetPlayerDisabled()) then
		return true
	end

	-- Turn the scanning back on if it was turned off for some reason
	if (not self.turretNPC:GetInternalVariable("m_bActive")) then
		self.turretNPC:Fire("Enable")
	end

	-- Keep the NPC scanning forever
	self.turretNPC:SetSaveValue("m_flLastSight", curTime + 100)

	if (not self.lastUpdateTarget or curTime - self.lastUpdateTarget >= self.UpdateTargetInterval) then
		self.lastUpdateTarget = curTime
		-- Clean up old targets
		self:CleanupHostileTargets()

		-- Update area targeting for area defense modes
		self:UpdateAreaTargeting()

		-- Find and engage targets
		self:UpdateTargeting()
	end

	return true
end

function ENT:CleanupHostileTargets()
	local curTime = CurTime()

	for target, lastTime in pairs(self.lastHostileTime) do
		-- Remove targets that haven't been hostile for 10 seconds
		if (curTime - lastTime > 10) then
			self.hostileTargets[target] = nil
			self.lastHostileTime[target] = nil

			-- Reset relationship to neutral
			if (IsValid(target) and IsValid(self.turretNPC)) then
				self.turretNPC:AddEntityRelationship(target, D_NU)
			end
		end
	end

	-- Clean up area targets that are no longer in range
	for target, _ in pairs(self.areaTargets) do
		if (not IsValid(target) or not target:Alive() or
				self:GetPos():Distance(target:GetPos()) > self.DetectionRange) then
			self.areaTargets[target] = nil

			if (IsValid(target) and IsValid(self.turretNPC)) then
				self.turretNPC:AddEntityRelationship(target, D_NU)
			end
		end
	end
end

function ENT:UpdateAreaTargeting()
	local mode = self:GetTurretMode()

	-- Only update area targeting for area defense modes
	if (mode ~= PLUGIN.TURRET_MODES.DEFEND_AREA_OWNER and
			mode ~= PLUGIN.TURRET_MODES.DEFEND_AREA_ALLIANCE) then
		return
	end

	local ownerChar = self:GetOwnerCharacter()

	-- Find players and NPC's in detection range
	for _, entity in ipairs(ents.FindInSphere(self:GetPos(), self.DetectionRange)) do
		local shouldTarget = false

		if (not self:IsValidTarget(entity)) then
			continue
		end

		if (mode == PLUGIN.TURRET_MODES.DEFEND_AREA_OWNER) then
			-- Target everyone except the owner
			shouldTarget = not self:IsOwner(entity)
		elseif (mode == PLUGIN.TURRET_MODES.DEFEND_AREA_ALLIANCE) then
			-- Target everyone not in owner's alliance
			if (ownerChar) then
				local playerChar = entity:IsPlayer() and entity:GetCharacter() or false

				if (playerChar) then
					local ownerAlliance = ownerChar:GetAlliance()
					local playerAlliance = playerChar:GetAlliance()
					shouldTarget = ownerAlliance and (not playerAlliance or ownerAlliance.id ~= playerAlliance.id)
				else
					shouldTarget = true -- No character means it's an NPC, shoot it
				end
			else
				shouldTarget = false -- owner left -- TODO: Disable turret
			end
		end

		if (shouldTarget) then
			self.areaTargets[entity] = true
		else
			self.areaTargets[entity] = nil
		end
	end
end

function ENT:UpdateTargeting()
	if (not IsValid(self.turretNPC)) then
		return
	end

	local allTargets = {}

	-- Add hostile targets
	for target, _ in pairs(self.hostileTargets) do
		if (IsValid(target) and target:Alive()) then
			allTargets[target] = true
		end
	end

	-- Add area targets
	for target, _ in pairs(self.areaTargets) do
		if (IsValid(target) and target:Alive()) then
			allTargets[target] = true
		end
	end

	-- Find closest target in range
	local closestTarget = nil
	local closestDistance = math.huge

	for target, _ in pairs(allTargets) do
		local distance = self:GetPos():Distance(target:GetPos())

		if (distance <= self.EngageRange and distance < closestDistance) then
			closestTarget = target
			closestDistance = distance
		end
	end

	-- Update current target
	if (IsValid(closestTarget) and closestTarget ~= self.currentTarget) then
		self.currentTarget = closestTarget

		-- Set turret to be hostile to this target
		self.turretNPC:AddEntityRelationship(closestTarget, D_HT, 100)
	elseif (not IsValid(closestTarget) and IsValid(self.currentTarget)) then
		-- No more targets, reset to neutral
		self.turretNPC:AddEntityRelationship(self.currentTarget, D_NU, 99)
		self.currentTarget = nil
	end
end

function ENT:IsValidTarget(target)
	return IsValid(target)
		and target ~= self
		and target ~= self.turretNPC
		and target:Alive()
		and (target:IsPlayer() or target:IsNPC())
		and not target.IsPassiveNPC
end

function ENT:SetHostileTarget(target)
	if (not self:IsValidTarget(target)) then
		return
	end

	local mode = self:GetTurretMode()

	-- For owner with no valid owner ID, use default behavior
	if (self:GetOwnerID() == -1) then
		self.hostileTargets[target] = true
		self.lastHostileTime[target] = CurTime()
		return
	end

	-- Check mode-specific targeting rules
	if (mode == PLUGIN.TURRET_MODES.DEFEND_OWNER) then
		-- Only target if owner was attacked - this will be handled in the damage hook
		return
	elseif (mode == PLUGIN.TURRET_MODES.DEFEND_ALLIANCE) then
		-- Only target if alliance member was attacked - this will be handled in the damage hook
		return
	elseif (mode == PLUGIN.TURRET_MODES.DEFEND_ALL) then
		-- Default behavior - target anyone causing hostile activity
		self.hostileTargets[target] = true
		self.lastHostileTime[target] = CurTime()
	end
	-- Area defense modes don't use hostile targeting, they use area targeting
end

function ENT:SetHostileTargetForDamage(attacker, victim)
	if (not self:IsValidTarget(attacker)) then
		return
	end

	local mode = self:GetTurretMode()

	-- For owner with no valid owner ID, use default behavior
	if (self:GetOwnerID() == -1) then
		self.hostileTargets[attacker] = true
		self.lastHostileTime[attacker] = CurTime()
		return
	end

	if (mode == PLUGIN.TURRET_MODES.DEFEND_OWNER) then
		-- Only defend if the owner is the victim
		if (self:IsOwner(victim)) then
			self.hostileTargets[attacker] = true
			self.lastHostileTime[attacker] = CurTime()
		end
	elseif (mode == PLUGIN.TURRET_MODES.DEFEND_ALLIANCE) then
		-- Only defend if victim is in owner's alliance
		local ownerChar = self:GetOwnerCharacter()

		if (ownerChar and IsValid(victim) and victim:IsPlayer()) then
			local victimChar = victim:GetCharacter()
			if (victimChar) then
				local ownerAlliance = ownerChar:GetAlliance()
				local victimAlliance = victimChar:GetAlliance()

				if (ownerAlliance and (not victimAlliance or ownerAlliance.id ~= victimAlliance.id)) then
					self.hostileTargets[attacker] = true
					self.lastHostileTime[attacker] = CurTime()
				end
			end
		end
	elseif (mode == PLUGIN.TURRET_MODES.DEFEND_ALL) then
		if (self:IsOwner(attacker)) then
			return
		end

		-- Default behavior - defend against any hostile activity not inflicted by the owner
		self.hostileTargets[attacker] = true
		self.lastHostileTime[attacker] = CurTime()
	end
	-- Area defense modes don't care about damage events, they target based on presence
end

function ENT:OnTakeDamage(dmgInfo)
	if (self:GetDisabled()) then
		return
	end

	local damage = dmgInfo:GetDamage()
	local newHealth = math.max(0, self:Health() - damage)
	self:SetHealth(newHealth)

	timer.Simple(0, function() -- Give some time for health to network
		Schema.PlayerClearEntityInfoTooltip(nil, self.turretNPC)
	end)

	-- Mark attacker as hostile
	local attacker = dmgInfo:GetAttacker()

	if (self:IsValidTarget(attacker)) then
		self:SetHostileTarget(attacker)
	end

	-- Destroy if health reaches 0
	if (newHealth <= 0) then
		self:Destroy()
	end

	return true -- Prevent default damage handling
end

function ENT:Destroy()
	if (self:GetDisabled()) then
		return
	end

	-- Create explosion effect
	local explosion = EffectData()
	explosion:SetOrigin(self:GetPos())
	explosion:SetMagnitude(1)
	explosion:SetScale(1)
	util.Effect("Explosion", explosion)

	-- Disable the turret
	self:SetDisabled(true)

	-- Retire the turret NPC
	if (IsValid(self.turretNPC)) then
		self.turretNPC:Fire("Disable")
	end

	-- Set respawn time if this is a turret owned by The Business (players have to repair their own turrets)
	if (self:GetOwnerID() == -1) then
		self.respawnTime = CurTime() + self.DisabledDuration
	end

	-- Clear targets
	self.hostileTargets = {}
	self.lastHostileTime = {}
	self.areaTargets = {}
	self.currentTarget = nil
end

function ENT:RespawnTurret()
	if (not self:GetDisabled()) then
		return
	end

	-- Restore turret
	self:SetDisabled(false)
	self:SetPlayerDisabled(false)
	self:Fire("Enable")
	self:SetHealth(self.MaxHealth)

	-- Clear respawn time
	self.respawnTime = nil

	timer.Simple(0, function() -- Give some time for health to network
		Schema.PlayerClearEntityInfoTooltip(nil, self.turretNPC)
	end)

	-- Create respawn effect
	local effect = EffectData()
	effect:SetOrigin(self:GetPos())
	effect:SetMagnitude(1)
	util.Effect("TeleportSplash", effect)
end

function ENT:OnRemove()
	if (IsValid(self.turretNPC)) then
		self.turretNPC:Remove()
	end
end

-- Modes will be handled by the network message instead
function ENT:OnOptionSelected(client, option, data)
	if (option == L("turretRepair", client)) then
		if (self:Health() >= self:GetMaxHealth()) then
			client:Notify("Turret does not need repairs.")
			return
		end

		-- TODO: Have this cost something?
		self:RespawnTurret()
	end
end

-- Handle mode change network message
net.Receive("ixTurretChangeMode", function(len, client)
	local turret = net.ReadEntity()
	local newMode = net.ReadUInt(8)

	if (not IsValid(turret) or turret:GetClass() ~= "exp_turret") then
		return
	end

	-- Verify client is the owner
	if (not turret:IsOwner(client)) then
		client:Notify("You are not the owner of this turret.")
		return
	end

	local modeIsValid = false

	-- Check if mode is valid
	for k, v in pairs(PLUGIN.TURRET_MODES) do
		if (v == newMode) then
			modeIsValid = true
			break
		end
	end

	if (not modeIsValid) then
		return
	end

	-- Check if alliance modes are available
	if ((newMode == PLUGIN.TURRET_MODES.DEFEND_ALLIANCE or
				newMode == PLUGIN.TURRET_MODES.DEFEND_AREA_ALLIANCE) and
			not client:GetAlliance()) then
		client:Notify("You must be in an alliance to use alliance defense modes.")
		return
	end

	local isDisabled = newMode == PLUGIN.TURRET_MODES.DISABLED

	turret:SetPlayerDisabled(isDisabled)

	if (isDisabled) then
		if (IsValid(turret.turretNPC)) then
			turret.turretNPC:Fire("Disable")
		end

		client:Notify("Turret disabled.")

		return
	end

	-- Set the new mode
	turret:SetTurretMode(newMode)

	-- Clear existing targets when changing modes
	turret.hostileTargets = {}
	turret.lastHostileTime = {}
	turret.areaTargets = {}
	if (IsValid(turret.currentTarget) and IsValid(turret.turretNPC)) then
		turret.turretNPC:AddEntityRelationship(turret.currentTarget, D_NU)
	end
	turret.currentTarget = nil

	client:Notify("Turret mode changed to: " .. turret:GetModeDisplayName(client))
end)
