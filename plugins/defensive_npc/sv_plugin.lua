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

	-- Only care about player vs player or player vs NPC damage
	if (not (IsValid(attacker) and IsValid(target))) then
		return
	end

	if (not (attacker:IsPlayer() or target:IsPlayer())) then
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
			-- Determine hostile player
			local hostilePlayer = nil

			if (attacker:IsPlayer() and target:IsPlayer()) then
				-- Player vs Player - attacker is hostile
				hostilePlayer = attacker
			elseif (attacker:IsPlayer() and not target:IsPlayer()) then
				-- Player attacking NPC - player is hostile
				hostilePlayer = attacker
			elseif (not attacker:IsPlayer() and target:IsPlayer()) then
				-- NPC attacking player - we might want to protect the player
				-- For now, we'll ignore this case
				continue
			end

			if (IsValid(hostilePlayer)) then
				turret:SetHostileTarget(hostilePlayer)
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

		table.insert(npcs, {
			type = entity:GetTurretType(),
			pos = entity:GetPos(),
			ang = entity:GetAngles(),
			owner = entity:GetOwnerID()
		})
	end

	self:SetData(npcs)
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
