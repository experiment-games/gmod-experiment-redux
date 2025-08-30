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
end

function ENT:HandleDamage(damageInfo)
	local attacker = damageInfo:GetAttacker()

	if (IsValid(attacker) and attacker:IsPlayer()) then
		self.LastAttackedBy = attacker
		self.LastAttackedTime = CurTime()

		if (not self:IsAggressiveMode()) then
			self.CurrentState = self.BotState.COMBAT
		end
	end
end

function ENT:SetAggressiveMode(player)
	if (IsValid(player) and player:IsPlayer()) then
		self.CombatModeValue = self.CombatMode.AGGRESSIVE
		self.AggressiveTarget = player
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

		if (options.draw) then
			path:Draw()
		end

		if (self:GetRangeTo(self:GetEnemy():GetPos()) <= self.AttackRange) then
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

function ENT:SnapToFaceEnemy()
	if (not self:HaveEnemy()) then
		return
	end

	local enemyPos = self:GetEnemy():GetPos()
	local direction = (enemyPos - self:GetPos()):GetNormalized()
	local angle = direction:Angle()
	angle.p = 0
	self:SetAngles(angle)
end

function ENT:PerformAttack()
	if (not self:HaveEnemy()) then
		return
	end

	self:SnapToFaceEnemy()
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
	end

	coroutine.wait(self.AttackDuration - damageDelay)
end
