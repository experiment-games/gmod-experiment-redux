function ENT:InitializeCombat()
	self.AttackRange = 80
	self.LastAttackedBy = nil
	self.LastAttackedTime = 0
	self.DefensiveTimeout = 10

	self.CombatModeValue = self.CombatMode.DEFENSIVE
	self.CurrentEnemy = nil
	self.AggressiveTarget = nil
	self.CombatSpeed = 450
	self.AttackDuration = 1.0

	self.AutoSwitchWeapons = true
	self.LastCombatWeaponSwitch = 0
	self.CombatWeaponSwitchCooldown = 3.0

	-- Combat pose parameters
	self.AimYaw = 0
	self.AimPitch = 0

	-- Ranged combat parameters
	self.OptimalRangedDistance = 400
	self.MinRangedDistance = 200
	self.MaxRangedDistance = 800

	-- Fix for erratic movement
	self.LastPositionUpdate = 0
	self.PositionUpdateCooldown = 2.0 -- Only recalculate position every 2 seconds
	self.InCombatPosition = false
	self.LastAttackAttempt = 0
	self.AttackCooldown = 1.5
end

function ENT:HandleDamage(damageInfo)
	local attacker = damageInfo:GetAttacker()

	if (IsValid(attacker) and attacker:IsPlayer()) then
		self.LastAttackedBy = attacker
		self.LastAttackedTime = CurTime()

		if (not self:IsAggressiveMode()) then
			self.CurrentState = self.BotState.COMBAT
		end

		self:EnterCombatMode()
	end
end

function ENT:EnterCombatMode()
	if (self:HasWeapons() and self:HaveEnemy()) then
		local distance = self:GetRangeTo(self:GetEnemy():GetPos())
		self:SelectBestWeaponForRange(distance)
	end

	-- Reset position tracking
	self.InCombatPosition = false
	self.LastPositionUpdate = 0
end

function ENT:SetAggressiveMode(player)
	if (IsValid(player) and player:IsPlayer()) then
		self.CombatModeValue = self.CombatMode.AGGRESSIVE
		self.AggressiveTarget = player
		self:EnterCombatMode()
	end
end

function ENT:SetDefensiveMode()
	self.CombatModeValue = self.CombatMode.DEFENSIVE
	self.AggressiveTarget = nil
end

function ENT:IsAggressiveMode()
	return (self.CombatModeValue == self.CombatMode.AGGRESSIVE)
end

function ENT:SetEnemy(entity)
	self.CurrentEnemy = entity

	if (IsValid(entity) and self:HasWeapons() and self.AutoSwitchWeapons) then
		local distance = self:GetRangeTo(entity:GetPos())
		self:SelectBestWeaponForRange(distance)
	end

	-- Reset position when enemy changes
	self.InCombatPosition = false
end

function ENT:GetEnemy()
	return self.CurrentEnemy
end

function ENT:HaveEnemy()
	if (self:GetEnemy() and IsValid(self:GetEnemy())) then
		if (self:GetRangeTo(self:GetEnemy():GetPos()) > self.LoseTargetDistance) then
			return self:FindEnemy()
		end

		if (self:GetEnemy():IsPlayer() and not self:GetEnemy():Alive()) then
			return self:FindEnemy()
		end

		return true
	else
		return self:FindEnemy()
	end
end

function ENT:FindEnemy()
	local foundEnemy = nil

	-- Aggressive mode targeting
	if (self:IsAggressiveMode() and IsValid(self.AggressiveTarget)) then
		local distance = self:GetRangeTo(self.AggressiveTarget:GetPos())
		if (distance <= self.SearchRadius and self.AggressiveTarget:Alive()) then
			foundEnemy = self.AggressiveTarget
		end
	end

	-- Defensive mode targeting
	if (not foundEnemy and self.CombatModeValue == self.CombatMode.DEFENSIVE) then
		if (self.LastAttackedBy and IsValid(self.LastAttackedBy) and
				(CurTime() - self.LastAttackedTime < self.DefensiveTimeout)) then
			local distance = self:GetRangeTo(self.LastAttackedBy:GetPos())
			if (distance <= self.SearchRadius) then
				foundEnemy = self.LastAttackedBy
			end
		end
	end

	-- General enemy search
	if (not foundEnemy) then
		local entities = ents.FindInSphere(self:GetPos(), self.SearchRadius)
		for _, entity in ipairs(entities) do
			if (entity:IsPlayer() and entity:Alive()) then
				if (self:IsAggressiveMode()) then
					if (entity == self.AggressiveTarget) then
						foundEnemy = entity
						break
					end
				else
					foundEnemy = entity
					break
				end
			end
		end
	end

	if foundEnemy then
		self:SetEnemy(foundEnemy)
		return true
	else
		self:SetEnemy(nil)
		return false
	end
end

function ENT:ChaseEnemy(options)
	local options = options or {}
	local path = Path("Follow")
	path:SetMinLookAheadDistance(options.lookahead or 300)
	path:SetGoalTolerance(options.tolerance or 20)

	if (not self:HaveEnemy()) then
		return "lost_target"
	end

	local isRangedWeapon = self:IsUsingRangedWeapon()

	-- Determine behavior based on weapon type
	if (isRangedWeapon) then
		return self:EngageWithRangedWeapon(path, options)
	else
		return self:EngageWithMeleeWeapon(path, options)
	end
end

function ENT:EngageWithRangedWeapon(path, options)
	if (not self:HaveEnemy()) then
		return "lost_target"
	end

	local targetPos = self:GetEnemy():GetPos()
	local currentDistance = self:GetRangeTo(targetPos)
	local effectiveRange = self:GetEffectiveAttackRange()

	while (self:HaveEnemy()) do
		currentDistance = self:GetRangeTo(self:GetEnemy():GetPos())
		targetPos = self:GetEnemy():GetPos()

		-- Update aim direction for weapon aiming
		self:UpdateAimDirection()
		self:SnapToFaceEnemy()

		-- Update weapon selection based on distance (less frequently)
		if (CurTime() - self.LastCombatWeaponSwitch >= self.CombatWeaponSwitchCooldown) then
			self:UpdateCombatWeaponSelection(currentDistance)
		end

		-- Check if we can attack from current position
		if (currentDistance <= effectiveRange and currentDistance >= self.MinRangedDistance) then
			-- We're in good range
			self.InCombatPosition = true

			-- Attack if cooldown is ready
			if (CurTime() - self.LastAttackAttempt >= self.AttackCooldown) then
				self:PerformAttack()
				self.LastAttackAttempt = CurTime()
			end

			-- Stay in position and keep aiming
			self:SnapToFaceEnemy()
			coroutine.wait(0.2)
			continue
		end

		-- Only recalculate position if we're not in a good position and enough time has passed
		if (not self.InCombatPosition and CurTime() - self.LastPositionUpdate >= self.PositionUpdateCooldown) then
			local needsMovement = false
			local targetMovePos = nil

			if (currentDistance < self.MinRangedDistance) then
				-- Too close, back away
				targetMovePos = self:CalculateBackoffPosition(targetPos, self.OptimalRangedDistance)
				needsMovement = true
			elseif (currentDistance > effectiveRange) then
				-- Too far, move closer
				targetMovePos = self:CalculateApproachPosition(targetPos, self.OptimalRangedDistance)
				needsMovement = true
			end

			-- Execute movement if needed
			if (needsMovement and targetMovePos) then
				path:Compute(self, targetMovePos)
				self.LastPositionUpdate = CurTime()
				self.InCombatPosition = false

				if (path:IsValid()) then
					-- Move for a limited time, then reassess
					local moveStartTime = CurTime()
					local maxMoveTime = 3.0

					while (CurTime() - moveStartTime < maxMoveTime and path:IsValid() and self:HaveEnemy()) do
						path:Update(self)

						if (options.draw) then
							path:Draw()
						end

						-- Check if we've reached a good position
						local newDistance = self:GetRangeTo(self:GetEnemy():GetPos())
						if (newDistance <= effectiveRange and newDistance >= self.MinRangedDistance) then
							self.InCombatPosition = true
							break
						end

						coroutine.wait(0.1)
					end
				end
			end
		else
			-- Just maintain current position and face enemy
			self:SnapToFaceEnemy()
			coroutine.wait(0.2)
		end

		if (self.loco:IsStuck()) then
			self:HandleStuck()
			self.InCombatPosition = false
		end

		coroutine.yield()
	end

	return "ok"
end

function ENT:EngageWithMeleeWeapon(path, options)
	-- Original melee behavior - chase until in range
	path:Compute(self, self:GetEnemy():GetPos())

	if (not path:IsValid()) then
		return "failed"
	end

	while (path:IsValid() and self:HaveEnemy()) do
		if (path:GetAge() > 0.1) then
			path:Compute(self, self:GetEnemy():GetPos())
		end

		path:Update(self)

		-- Update aim direction for weapon aiming
		self:UpdateAimDirection()

		if (options.draw) then
			path:Draw()
		end

		local currentDistance = self:GetRangeTo(self:GetEnemy():GetPos())

		-- Less frequent weapon switching
		if (CurTime() - self.LastCombatWeaponSwitch >= self.CombatWeaponSwitchCooldown) then
			self:UpdateCombatWeaponSelection(currentDistance)
		end

		if (currentDistance <= self:GetEffectiveAttackRange()) then
			self:PerformAttack()
			return "attacked"
		end

		if (self.loco:IsStuck()) then
			self:HandleStuck()
			return "stuck"
		end

		coroutine.yield()
	end

	return "ok"
end

function ENT:IsUsingRangedWeapon()
	if (not self:IsArmed() or not IsValid(self.CurrentWeapon)) then
		return false
	end

	local weaponClass = string.lower(self.CurrentWeapon:GetClass())

	-- Check if it's a ranged weapon
	local rangedWeapons = {
		"pistol", "rifle", "smg", "shotgun", "crossbow", "ar2", "revolver", "sniper"
	}

	for _, weaponType in ipairs(rangedWeapons) do
		if (string.find(weaponClass, weaponType)) then
			return true
		end
	end

	-- Check holdtype as fallback
	local holdType = self:GetCurrentHoldType()
	local rangedHoldTypes = {
		"pistol", "smg", "ar2", "shotgun", "crossbow", "revolver"
	}

	return table.HasValue(rangedHoldTypes, holdType)
end

function ENT:CalculateBackoffPosition(enemyPos, desiredDistance)
	local myPos = self:GetPos()
	local direction = (myPos - enemyPos):GetNormalized()
	local backoffPos = enemyPos + direction * desiredDistance

	-- Make sure the position is navigable
	local navArea = navmesh.GetNearestNavArea(backoffPos, false, 500, false, true)
	if (navArea) then
		return navArea:GetClosestPointOnArea(backoffPos)
	end

	return backoffPos
end

function ENT:CalculateApproachPosition(enemyPos, desiredDistance)
	local myPos = self:GetPos()
	local direction = (enemyPos - myPos):GetNormalized()
	local approachPos = enemyPos - direction * desiredDistance

	-- Make sure the position is navigable
	local navArea = navmesh.GetNearestNavArea(approachPos, false, 500, false, true)
	if (navArea) then
		return navArea:GetClosestPointOnArea(approachPos)
	end

	return approachPos
end

function ENT:UpdateAimDirection()
	if (not self:HaveEnemy()) then
		return
	end

	local enemyPos = self:GetEnemy():GetPos() + Vector(0, 0, 32)
	local myPos = self:GetPos() + Vector(0, 0, 64)
	local aimVector = (enemyPos - myPos):GetNormalized()
	local aimAngles = aimVector:Angle()

	-- Calculate yaw and pitch relative to our current angles
	local myAngles = self:GetAngles()
	local deltaYaw = math.AngleDifference(aimAngles.y, myAngles.y)
	local deltaPitch = aimAngles.p

	-- Update pose parameters for aiming
	self:SetPoseParameter("aim_yaw", deltaYaw)
	self:SetPoseParameter("aim_pitch", -deltaPitch)

	-- Store for later use
	self.AimYaw = deltaYaw
	self.AimPitch = deltaPitch
end

function ENT:UpdateCombatWeaponSelection(distance)
	-- Auto-switch weapons during combat if enabled and enough time has passed
	if (self.AutoSwitchWeapons and self:CanSwitchWeapons() and
			CurTime() - self.LastCombatWeaponSwitch >= self.CombatWeaponSwitchCooldown) then
		if (not self:IsWeaponSuitableForRange(self.WeaponClasses[self.CurrentWeaponIndex] or "", distance)) then
			if (self:SelectBestWeaponForRange(distance)) then
				self.LastCombatWeaponSwitch = CurTime()
			end
		end
	end
end

function ENT:GetEffectiveAttackRange()
	-- Return weapon-specific attack range if armed, otherwise default melee range
	if (self:IsArmed() and IsValid(self.CurrentWeapon)) then
		return self:GetWeaponAttackRange(self.CurrentWeapon)
	end

	return self.AttackRange
end

function ENT:GetWeaponAttackRange(weapon)
	local weaponClass = weapon:GetClass()

	if (string.find(string.lower(weaponClass), "knife") or
			string.find(string.lower(weaponClass), "crowbar") or
			string.find(string.lower(weaponClass), "sword")) then
		return 80
	end

	if (string.find(string.lower(weaponClass), "shotgun")) then
		return 300
	end

	if (string.find(string.lower(weaponClass), "pistol")) then
		return 600
	end

	if (string.find(string.lower(weaponClass), "rifle")) then
		return 800
	end

	if (string.find(string.lower(weaponClass), "smg")) then
		return 500
	end

	return self.AttackRange
end

function ENT:SnapToFaceEnemy()
	if (not self:HaveEnemy()) then
		return
	end

	local enemyPos = self:GetEnemy():GetPos()
	local direction = (enemyPos - self:GetPos()):GetNormalized()
	local angle = direction:Angle()
	angle.p = 0 -- Keep pitch at 0 for body rotation
	self:SetAngles(angle)
end

-- FIXED: Simplified PerformAttack to avoid coroutine issues
function ENT:PerformAttack()
	if (not self:HaveEnemy()) then
		return
	end

	self:SnapToFaceEnemy()

	if (self:IsArmed()) then
		self:PerformWeaponAttack()
	else
		self:PerformMeleeAttack()
	end
end

-- FIXED: Removed coroutine.wait from weapon attack
function ENT:PerformWeaponAttack()
	if (not IsValid(self.CurrentWeapon)) then
		return
	end

	print("=== ATTEMPTING WEAPON ATTACK ===")
	print("Current weapon:", self.CurrentWeapon:GetClass())
	print("Enemy distance:", self:GetRangeTo(self:GetEnemy():GetPos()))
	print("Effective range:", self:GetEffectiveAttackRange())

	self:RequestAttackAnimation()

	-- Fire immediately, don't wait for animation
	if (self:HaveEnemy() and self:GetRangeTo(self:GetEnemy():GetPos()) <= self:GetEffectiveAttackRange()) then
		-- Position weapon at muzzle for accurate shooting
		self:PositionWeaponForFiring()

		print("=== FIRING WEAPON AT ENEMY ===", self:GetEnemy())

		-- Try different firing methods
		local fired = false

		if (self.CurrentWeapon.PrimaryAttack) then
			print("Using PrimaryAttack method")
			self.CurrentWeapon:PrimaryAttack()
			fired = true
		elseif (self.CurrentWeapon.FireBullets) then
			print("Using FireBullets method")
			-- Fallback for weapons that use FireBullets directly
			local bullet = {}
			bullet.Num = 1
			bullet.Src = self.CurrentWeapon:GetPos()
			bullet.Dir = (self:GetEnemy():GetPos() + Vector(0, 0, 32) - bullet.Src):GetNormalized()
			bullet.Spread = Vector(0.01, 0.01, 0)
			bullet.Tracer = 1
			bullet.Force = 10
			bullet.Damage = 25
			bullet.AmmoType = "Pistol"
			bullet.Attacker = self

			self.CurrentWeapon:FireBullets(bullet)
			fired = true
		else
			print("No firing method found for weapon")
		end

		if fired then
			print("=== WEAPON FIRED SUCCESSFULLY ===")
		end
	else
		print("Target out of range or no enemy")
	end
end

function ENT:PositionWeaponForFiring()
	if (not IsValid(self.CurrentWeapon)) then
		return
	end

	-- Get the weapon's muzzle attachment or approximate muzzle position
	local muzzlePos = self.CurrentWeapon:GetPos()
	local muzzleAng = self.CurrentWeapon:GetAngles()

	-- Try to get muzzle attachment if it exists
	local muzzleAttachment = self.CurrentWeapon:LookupAttachment("muzzle")
	if (muzzleAttachment > 0) then
		local attachData = self.CurrentWeapon:GetAttachment(muzzleAttachment)
		if (attachData) then
			muzzlePos = attachData.Pos
			muzzleAng = attachData.Ang
		end
	end

	-- Update weapon position for accurate firing
	self.CurrentWeapon:SetPos(muzzlePos)
	self.CurrentWeapon:SetAngles(muzzleAng)
end

-- FIXED: Simplified melee attack
function ENT:PerformMeleeAttack()
	print("=== PERFORMING MELEE ATTACK ===")

	self:RequestAttackAnimation()

	-- Deal damage immediately
	if (self:HaveEnemy() and self:GetRangeTo(self:GetEnemy():GetPos()) <= self.AttackRange) then
		print("=== DEALING MELEE DAMAGE ===")

		local damageInfo = DamageInfo()
		damageInfo:SetDamage(25)
		damageInfo:SetAttacker(self)
		damageInfo:SetInflictor(self)
		damageInfo:SetDamageType(DMG_SLASH)

		self:GetEnemy():TakeDamageInfo(damageInfo)

		-- Create impact effect
		self:CreateMeleeImpactEffect()
	end
end

function ENT:CreateMeleeImpactEffect()
	if (not self:HaveEnemy()) then
		return
	end

	-- Create blood effect
	local effectData = EffectData()
	effectData:SetOrigin(self:GetEnemy():GetPos() + Vector(0, 0, 40))
	effectData:SetNormal((self:GetEnemy():GetPos() - self:GetPos()):GetNormalized())

	util.Effect("BloodImpact", effectData)
end

function ENT:SetAutoWeaponSwitch(enabled)
	self.AutoSwitchWeapons = enabled
end

function ENT:SetCombatWeaponSwitchCooldown(cooldown)
	self.CombatWeaponSwitchCooldown = cooldown or 3.0
end

function ENT:GetAimVector()
	if (not IsValid(self.CurrentWeapon)) then
		return self:GetForward()
	end

	return self.CurrentWeapon:GetForward()
end

function ENT:GetShootPos()
	if (not IsValid(self.CurrentWeapon)) then
		return self:GetPos()
	end

	return self.CurrentWeapon:GetPos()
end

function ENT:SetOptimalRangedDistance(distance)
	self.OptimalRangedDistance = distance or 400
end

function ENT:SetMinRangedDistance(distance)
	self.MinRangedDistance = distance or 200
end

function ENT:SetMaxRangedDistance(distance)
	self.MaxRangedDistance = distance or 800
end
