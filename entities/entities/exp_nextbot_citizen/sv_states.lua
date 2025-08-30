function ENT:InitializeStates()
	-- State initialization if needed
end

function ENT:HandleIdleState()
	if (self:HaveEnemy()) then
		self.CurrentState = self.BotState.COMBAT
		return
	end

	if (IsValid(self.TaskEntity) and not self:IsAtTask()) then
		self.CurrentState = self.BotState.GOING_TO_TASK
	elseif (IsValid(self.HomeEntity) and not self:IsAtHome()) then
		self.CurrentState = self.BotState.GOING_HOME
	else
		self:RequestActivity(ACT_HL2MP_WALK)
		self.loco:SetDesiredSpeed(200)
		self:MoveToPos(self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * 400)
		self:RequestActivity(ACT_HL2MP_IDLE)
		coroutine.wait(2)
	end
end

function ENT:HandleGoingHomeState()
	if (self:HaveEnemy()) then
		self.CurrentState = self.BotState.COMBAT
		return
	end

	if (self:IsAtHome()) then
		self.CurrentState = self.BotState.AT_HOME
		return
	end

	local result = self:GoHome()
	if (result == "ok") then
		self.CurrentState = self.BotState.AT_HOME
	else
		self.CurrentState = self.BotState.IDLE
	end
end

function ENT:HandleAtHomeState()
	if (self:HaveEnemy()) then
		self.CurrentState = self.BotState.COMBAT
		return
	end

	if (IsValid(self.TaskEntity) and not self:IsAtTask()) then
		self.CurrentState = self.BotState.GOING_TO_TASK
		return
	end

	self:RequestActivity(ACT_HL2MP_IDLE)
	coroutine.wait(2)
end

function ENT:HandleGoingToTaskState()
	if (self:HaveEnemy()) then
		self.CurrentState = self.BotState.COMBAT
		return
	end

	if (self:IsAtTask()) then
		self.CurrentState = self.BotState.AT_TASK
		return
	end

	local result = self:GoToTask()
	if (result == "ok") then
		self.CurrentState = self.BotState.AT_TASK
	else
		self.CurrentState = self.BotState.IDLE
	end
end

function ENT:HandleAtTaskState()
	if (self:HaveEnemy()) then
		self.CurrentState = self.BotState.COMBAT
		return
	end

	self:PerformTask()

	if (IsValid(self.HomeEntity)) then
		self.CurrentState = self.BotState.RETURNING_HOME
	else
		self.CurrentState = self.BotState.IDLE
	end
end

function ENT:HandleCombatState()
	if (not self:HaveEnemy()) then
		if (IsValid(self.HomeEntity)) then
			self.CurrentState = self.BotState.RETURNING_HOME
		else
			self.CurrentState = self.BotState.IDLE
		end
		return
	end

	self.loco:FaceTowards(self:GetEnemy():GetPos())

	self:RequestActivity(ACT_HL2MP_RUN)
	self.loco:SetDesiredSpeed(self.CombatSpeed)
	self.loco:SetAcceleration(900)

	local result = self:ChaseEnemy()

	self.loco:SetAcceleration(400)

	if (result == "attacked") then
		coroutine.wait(0.5)
	elseif (result == "lost_target") then
		if (IsValid(self.HomeEntity)) then
			self.CurrentState = self.BotState.RETURNING_HOME
		else
			self.CurrentState = self.BotState.IDLE
		end
	end
end

function ENT:HandleReturningHomeState()
	if (self:HaveEnemy()) then
		self.CurrentState = self.BotState.COMBAT
		return
	end

	if (self:IsAtHome()) then
		self.CurrentState = self.BotState.AT_HOME
		return
	end

	local result = self:GoHome()
	if (result == "ok") then
		self.CurrentState = self.BotState.AT_HOME
	else
		self.CurrentState = self.BotState.IDLE
	end
end

-- Override this in derived classes
function ENT:PerformTask()
	self:RequestActivity(ACT_HL2MP_IDLE)
	coroutine.wait(5)
end
