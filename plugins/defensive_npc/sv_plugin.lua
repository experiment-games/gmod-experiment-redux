local PLUGIN = PLUGIN

-- Store active turrets for efficient lookup
PLUGIN.activeTurrets = PLUGIN.activeTurrets or {}

function PLUGIN:SpawnTurret(turretType, position, angles, ownerID)
	local entity = ents.Create("exp_turret")
	entity:SetPos(position)
	entity:SetAngles(angles)
	entity:SetTurretType(turretType)
	entity:SetOwnerID(ownerID or -1) -- Belonging to 'The Business'
	entity:Spawn()
	entity:Activate()

	-- Add to our tracking list
	table.insert(self.activeTurrets, entity)

	return entity
end

-- Hook to detect damage events near turrets
function PLUGIN:PostEntityTakeDamage(target, dmgInfo, wasDamageTaken)
	local attacker = dmgInfo:GetAttacker()

	-- Only care about player vs player or NPC vs player damage
	if (not (IsValid(attacker) and IsValid(target))) then
		return
	end

	-- If the target is a turret, ensure its damage is also inflicted to the parent logic npc
	if (IsValid(target.expTurret)) then
		local turret = target.expTurret

		turret:TakeDamageInfo(dmgInfo)
	end


	local damagePos = target:GetPos()
	local detectionRangeSquared = self.turretDetectionRange ^ 2

	-- Check all active turrets for proximity
	for i = #self.activeTurrets, 1, -1 do
		local turret = self.activeTurrets[i]

		-- Clean up invalid turrets
		if (not IsValid(turret)) then
			table.remove(self.activeTurrets, i)
			continue
		end

		-- Skip if turret is disabled/destroyed
		if (turret:GetDisabled()) then
			continue
		end

		-- Check if damage occurred within turret's detection range
		local distance = turret:GetPos():DistToSqr(damagePos)

		if (distance <= detectionRangeSquared) then
			-- Determine hostile player and victim
			local hostilePlayer = nil
			local victim = nil

			if (attacker:IsPlayer() and target:IsPlayer()) then
				-- Player vs Player - attacker is hostile, target is victim
				hostilePlayer = attacker
				victim = target
			elseif (attacker:IsPlayer() and not target:IsPlayer()) then
				-- Player attacking NPC - player is hostile, NPC is victim
				hostilePlayer = attacker
				victim = target
			elseif (attacker:IsNPC() and target:IsPlayer()) then
				-- NPC attacking player - NPC is hostile
				hostilePlayer = attacker
				victim = target
			elseif (not attacker:IsPlayer() and target:IsPlayer()) then
				-- NPC attacking player - we might want to protect the player
				-- For now, we'll ignore this case unless it's a turret mode that cares
				continue
			end

			if (IsValid(hostilePlayer)) then
				turret:SetHostileTargetForDamage(hostilePlayer, victim)
			end
		end
	end
end

-- Clean up turret tracking when entities are removed
function PLUGIN:EntityRemoved(entity)
	if (entity:GetClass() == "exp_turret") then
		for i = #self.activeTurrets, 1, -1 do
			if (self.activeTurrets[i] == entity) then
				table.remove(self.activeTurrets, i)
				break
			end
		end
	end
end

-- Save/Load functionality
function PLUGIN:LoadData()
	local npcs = self:GetData() or {}

	for _, npcData in pairs(npcs) do
		self:SpawnTurret(npcData.type, npcData.pos, npcData.ang, npcData.owner)
	end
end

function PLUGIN:SaveData()
	local npcs = {}

	for _, entity in ipairs(ents.FindByClass("exp_turret")) do
		if (entity:MapCreationID() > -1) then
			-- Do not save entities that are part of the map
			continue
		end

		-- Let's not save player NPC's for now
		if (entity:GetOwnerID() ~= -1) then
			continue
		end

		table.insert(npcs, {
			type = entity:GetTurretType(),
			pos = entity:GetPos(),
			ang = entity:GetAngles(),
			owner = entity:GetOwnerID(),
			mode = entity:GetTurretMode()
		})
	end

	self:SetData(npcs)
end

function PLUGIN:LoadData()
	local npcs = self:GetData() or {}

	for _, npcData in pairs(npcs) do
		local turret = self:SpawnTurret(npcData.type, npcData.pos, npcData.ang, npcData.owner)

		-- Restore the turret mode if it was saved
		if (npcData.mode) then
			turret:SetTurretMode(npcData.mode)
		end
	end
end

-- Utility function to get all turrets in range of a position
function PLUGIN:GetTurretsInRange(position, range)
	local nearbyTurrets = {}
	range = range or self.turretDetectionRange

	for _, turret in ipairs(self.activeTurrets) do
		if (IsValid(turret) and not turret:GetDisabled()) then
			if (turret:GetPos():Distance(position) <= range) then
				table.insert(nearbyTurrets, turret)
			end
		end
	end

	return nearbyTurrets
end
