local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Experiment Turret"
ENT.Category = "Experiment Redux"
ENT.Spawnable = false
ENT.AdminSpawnable = false

-- Configuration
ENT.DisabledDuration = 30 -- Seconds before turret respawns after being destroyed
ENT.MaxHealth = 100
ENT.DetectionRange = 500
ENT.EngageRange = 800
ENT.ThinkInterval = 0.1

local CEILING_TURRET_EFFICIENT = 16
local FLOOR_TURRET_FAST_RETIRE = 128
local FLOOR_TURRET_CITIZEN_MODIFIED_FRIENDLY = 512

function ENT:SetupDataTables()
	self:NetworkVar("Bool", "Disabled")
	self:NetworkVar("String", "TurretType")
	self:NetworkVar("Int", "OwnerID")
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

if (not SERVER) then
	function ENT:OnPopulateEntityInfo(tooltip)
		local ownerName, isOwner = self:GetOwnerName()
		local name = tooltip:AddRow("name")
		name:SetImportant()

		if (isOwner) then
			name:SetText(L("turretOwnerSelf"))
		else
			if (ownerName == false) then
				name:SetText(L("turretOwnerTheBusiness", ownerName))
				name:SetBackgroundColor(derma.GetColor("Warning", tooltip))
			else
				name:SetText(L("turretOwnerName", ownerName))
			end
		end

		name:SizeToContents()

		local healthBar = tooltip:Add("expProgressBar")
		healthBar:SetValue(self:Health())
		healthBar:SetMaxValue(self:GetMaxHealth())
		healthBar:SetPrefix(L("turretHealth"))

		-- Only red
		healthBar:SetProgressColors({
			{ threshold = 1, color = derma.GetColor("Error", healthBar) },
		})

		healthBar:Dock(BOTTOM)
	end

	function ENT:Think()
		if (IsValid(self.turretNPC)) then
			-- Already setup
			return
		end

		self.turretNPC = self:GetChildren()[1]

		if (not IsValid(self.turretNPC)) then
			-- Not yet fully spawned
			return
		end

		self.turretNPC.PopulateEntityInfo = true
		self.turretNPC.OnPopulateEntityInfo = function(npc, tooltip)
			self:OnPopulateEntityInfo(tooltip)
		end
	end

	return
end

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
	self:SetNoDraw(true)

	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)

	-- Initialize networked variables
	self:SetDisabled(false)

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

	-- Don't be aggressive towards players by default
	self.turretNPC:AddRelationship("player D_NU 99")

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

	self.lastThink = curTime

	-- Handle disabled state
	if (self:GetDisabled()) then
		if (self.respawnTime and curTime >= self.respawnTime) then
			self:RespawnTurret()
		end

		self:NextThink(curTime + self.ThinkInterval)

		return true
	end

	-- Turn the scanning back on if it was turned off for some reason
	if (not self.turretNPC:GetInternalVariable("m_bActive")) then
		self.turretNPC:Fire("Enable")
	end

	-- Keep the NPC scanning forever
	self.turretNPC:SetSaveValue("m_flLastSight", curTime + 100)

	-- Clean up old hostile targets
	self:CleanupHostileTargets()

	-- Find and engage targets
	self:UpdateTargeting()

	self:NextThink(curTime + self.ThinkInterval)

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
end

function ENT:UpdateTargeting()
	if (not IsValid(self.turretNPC)) then
		return
	end

	-- Find closest hostile target in range
	local closestTarget = nil
	local closestDistance = math.huge

	for target, _ in pairs(self.hostileTargets) do
		if (IsValid(target) and target:Alive()) then
			local distance = self:GetPos():Distance(target:GetPos())

			if (distance <= self.EngageRange and distance < closestDistance) then
				closestTarget = target
				closestDistance = distance
			end
		end
	end

	-- Update current target
	if (IsValid(closestTarget) and closestTarget ~= self.currentTarget) then
		self.currentTarget = closestTarget

		-- Set turret to be hostile to this target
		self.turretNPC:AddEntityRelationship(closestTarget, D_HT)
	elseif (not IsValid(closestTarget) and IsValid(self.currentTarget)) then
		-- No more targets, reset to neutral
		self.turretNPC:AddEntityRelationship(self.currentTarget, D_NU)
		self.currentTarget = nil
	end
end

function ENT:SetHostileTarget(target)
	if (not IsValid(target)) then
		return
	end

	self.hostileTargets[target] = true
	self.lastHostileTime[target] = CurTime()
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

	if (IsValid(attacker) and attacker:IsPlayer()) then
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

	-- Set respawn time
	self.respawnTime = CurTime() + self.DisabledDuration

	-- Clear targets
	self.hostileTargets = {}
	self.lastHostileTime = {}
	self.currentTarget = nil
end

function ENT:RespawnTurret()
	if (not self:GetDisabled()) then
		return
	end

	-- Restore turret
	self:SetDisabled(false)
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

-- Utility functions
function ENT:SetTurretType(turretType)
	self:SetDTString(0, turretType)
end

function ENT:GetTurretType()
	return self:GetDTString(0)
end
