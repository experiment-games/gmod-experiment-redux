function ENT:InitializeAI()
	self.SearchRadius = 1000
	self.LoseTargetDistance = 2000
	self.HomeRadius = 100
	self.TaskRadius = 100

	self.CurrentState = self.BotState.IDLE
	self.HomeEntity = nil
	self.TaskEntity = nil
	self.CurrentTaskUrgency = self.TaskUrgency.NORMAL
end

function ENT:UpdateAI()
	if (self.CurrentState == self.BotState.IDLE) then
		self:HandleIdleState()
	elseif (self.CurrentState == self.BotState.GOING_HOME) then
		self:HandleGoingHomeState()
	elseif (self.CurrentState == self.BotState.AT_HOME) then
		self:HandleAtHomeState()
	elseif (self.CurrentState == self.BotState.GOING_TO_TASK) then
		self:HandleGoingToTaskState()
	elseif (self.CurrentState == self.BotState.AT_TASK) then
		self:HandleAtTaskState()
	elseif (self.CurrentState == self.BotState.COMBAT) then
		self:HandleCombatState()
	elseif (self.CurrentState == self.BotState.RETURNING_HOME) then
		self:HandleReturningHomeState()
	end
end

-- Home/Task entity management
function ENT:SetHomeEntity(entity)
	if (IsValid(entity)) then
		self.HomeEntity = entity
	else
		self.HomeEntity = nil
	end
end

function ENT:GetHomeEntity()
	return self.HomeEntity
end

function ENT:SetTaskEntity(entity)
	if (IsValid(entity)) then
		self.TaskEntity = entity
	else
		self.TaskEntity = nil
	end
end

function ENT:GetTaskEntity()
	return self.TaskEntity
end

function ENT:SetTaskUrgency(urgency)
	if (self.MovementSpeeds[urgency]) then
		self.CurrentTaskUrgency = urgency
	end
end

function ENT:GetTaskUrgency()
	return self.CurrentTaskUrgency
end

-- Position checking
function ENT:IsAtHome()
	if (not IsValid(self.HomeEntity)) then
		return false
	end
	return (self:GetRangeTo(self.HomeEntity:GetPos()) <= self.HomeRadius)
end

function ENT:IsAtTask()
	if (not IsValid(self.TaskEntity)) then
		return false
	end
	return (self:GetRangeTo(self.TaskEntity:GetPos()) <= self.TaskRadius)
end

function ENT:SetSchedule(schedule)
	-- TODO: Implement SetSchedule for NextBot
	print("TODO: Implement SetSchedule for NextBot")
end
