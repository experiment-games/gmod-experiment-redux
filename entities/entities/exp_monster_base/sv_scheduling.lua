DEFINE_BASECLASS("base_ai")

function ENT:InitializeScheduleSystem()
	self.expSchedules = {}
	self.expSchedules.Attacks = {}
	self:SetupSchedules()
end

function ENT:SelectSchedule()
	if (GetConVar("ai_disabled"):GetBool() or self:GetNPCState() == NPC_STATE_DEAD) then
		return
	end

	if (self.ShouldOverrideSelectSchedule and self:ShouldOverrideSelectSchedule()) then
		return
	end

	-- Handle current target or find new one
	local currentTarget = self.targetingSystem.currentTarget

	if (not self:IsValidTarget(currentTarget)) then
		-- Look for new target
		local newTarget = self:FindBestTarget()
		self:SetTargetEntity(newTarget)
		currentTarget = newTarget
	end

	if (IsValid(currentTarget)) then
		self:HandleTargetedBehavior(currentTarget)
	else
		self:StartDefaultSchedule()
	end
end

function ENT:HandleTargetedBehavior(target)
	local distance = self:GetDistanceToEntitySqr(target)
	local meleeRange = self:GetRangeSquared(self:GetAttackMeleeRange())

	if (distance < meleeRange) then
		self:StartAttackSchedule(target)
	else
		if (self:GetSchedule() ~= self.expSchedules.Chase) then
			self:StartSchedule(self.expSchedules.Chase)
		end
	end
end

function ENT:StartDefaultSchedule()
	self:StartSchedule(self.expSchedules.Patrol)
end

function ENT:HandleAttackTaskComplete()
	self.expRouteBlockedCount = nil
	self:EndAttackHandles()
	self.expAttackSchedule = nil
end

function ENT:ScheduleFinished()
	if (self.CurrentSchedule == self.expAttackSchedule) then
		self:HandleAttackTaskComplete()
	end

	BaseClass.ScheduleFinished(self)
end

function ENT:OnTaskFailed(failCode, failReason)
	-- Handle blocked routes
	if (failCode == FAIL_NO_ROUTE_BLOCKED) then
		local position = self:GetPos()

		self:SetPos(position + Vector(0, 0, 16))
		Schema.MakeFlushToGround(self, position)

		self.expRouteBlockedCount = (self.expRouteBlockedCount or 0) + 1

		-- Remove if stuck too long
		if (self.expRouteBlockedCount > 5) then
			local owner = self:GetDTEntity(0)

			ix.util.SchemaErrorNoHalt(
				"Monster (owned by %s) is stuck, despawning",
				IsValid(owner) and owner:Name() or "unknown"
			)

			self:Remove()
		end
		return
	end

	-- Handle no enemy
	if (failCode == FAIL_NO_ENEMY) then
		self:SetTargetEntity(nil)
		self:StartDefaultSchedule()

		return
	end
end

function ENT:GetAttackSchedule(target)
	return self.expSchedules.Attacks[math.random(#self.expSchedules.Attacks)]
end

function ENT:StartAttackSchedule(target)
	local attackSchedule = self:GetAttackSchedule(target)

	if (not attackSchedule) then
		return
	end

	self.expAttackSchedule = attackSchedule
	self:UpdateEnemyMemory(target, target:GetPos())
	self:StartSchedule(attackSchedule)
	self:StartAttackHandles(attackSchedule.expAttackData)
end

function ENT:StartSchedule(schedule)
	BaseClass.StartSchedule(self, schedule)
	self:OnScheduleStarted(schedule)
end

function ENT:OnScheduleStarted(schedule)
	-- Override in subclasses
end

function ENT:OnDoingSchedule(schedule)
	if (not schedule.forceRetrigger) then
		return
	end

	if (Schema.util.Throttle("RecalculatePath", schedule.forceRetrigger, self)) then
		return
	end

	if (not self:OnRetriggerSchedule(schedule)) then
		self:StartSchedule(schedule)
	end
end

function ENT:OnRetriggerSchedule(schedule)
	-- Override to prevent retrigger, return true to prevent
	return false
end

function ENT:DoSchedule(schedule)
	self:OnDoingSchedule(schedule)
	BaseClass.DoSchedule(self, schedule)
end

--- CurrentSchedule is defined in base/entities/entities/base_ai/schedules.lua and contains the current lua defined schedule table
function ENT:GetSchedule()
	return self.CurrentSchedule
end
