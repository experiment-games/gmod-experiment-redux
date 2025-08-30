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
		self:UpdateCombatWeaponSelection(currentDistance)

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

function ENT:UpdateAimDirection()
	if (not self:HaveEnemy()) then
		return
	end

	local enemyPos = self:GetEnemy():GetPos() + Vector(0, 0, 32) -- Aim at chest level
	local myPos = self:GetPos() + Vector(0, 0, 64)            -- From my eye level
	local aimVector = (enemyPos - myPos):GetNormalized()
	local aimAngles = aimVector:Angle()

	-- Calculate yaw and pitch relative to our current angles
	local myAngles = self:GetAngles()
	local deltaYaw = math.AngleDifference(aimAngles.y, myAngles.y)
	local deltaPitch = aimAngles.p

	-- Update pose parameters for aiming (these may vary depending on the model)
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
	-- Override this method to define weapon-specific ranges
	-- Default implementation
	local weaponClass = weapon:GetClass()

	if (string.find(string.lower(weaponClass), "knife") or
			string.find(string.lower(weaponClass), "crowbar") or
			string.find(string.lower(weaponClass), "sword")) then
		return 80
	end

	if (string.find(string.lower(weaponClass), "shotgun")) then
		return 200
	end

	if (string.find(string.lower(weaponClass), "pistol")) then
		return 500
	end

	if (string.find(string.lower(weaponClass), "rifle")) then
		return 800
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

function ENT:PerformWeaponAttack()
	if (not IsValid(self.CurrentWeapon)) then
		return
	end

	self:RequestAttackAnimation()

	local attackDelay = self.AttackDuration * 0.3
	coroutine.wait(attackDelay)

	if (self:HaveEnemy() and self:GetRangeTo(self:GetEnemy():GetPos()) <= self:GetEffectiveAttackRange()) then
		-- Set weapon owner and position before firing
		self.CurrentWeapon:SetOwner(self)

		-- Position weapon at muzzle for accurate shooting
		self:PositionWeaponForFiring()

		-- Fire the weapon
		if (self.CurrentWeapon.PrimaryAttack) then
			self.CurrentWeapon:PrimaryAttack()
		elseif (self.CurrentWeapon.FireBullets) then
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
		end
	end

	coroutine.wait(self.AttackDuration - attackDelay)
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

function ENT:PerformMeleeAttack()
	self:RequestAttackAnimation()

	local damageDelay = self.AttackDuration * 0.5
	coroutine.wait(damageDelay)

	if (self:HaveEnemy() and self:GetRangeTo(self:GetEnemy():GetPos()) <= self.AttackRange) then
		local damageInfo = DamageInfo()
		damageInfo:SetDamage(25)
		damageInfo:SetAttacker(self)
		damageInfo:SetInflictor(self)
		damageInfo:SetDamageType(DMG_SLASH)

		self:GetEnemy():TakeDamageInfo(damageInfo)

		-- Create impact effect
		self:CreateMeleeImpactEffect()
	end

	coroutine.wait(self.AttackDuration - damageDelay)
end

function ENT:CreateMeleeImpactEffect()
	if (not self:HaveEnemy()) then
		return
	end

	-- Create blood effect or spark effect depending on target
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
