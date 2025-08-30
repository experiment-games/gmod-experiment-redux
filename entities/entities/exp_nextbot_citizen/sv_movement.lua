function ENT:InitializeMovement()
	self.MovementSpeeds = {
		[self.TaskUrgency.LOW] = { speed = 150, animation = ACT_HL2MP_WALK },
		[self.TaskUrgency.NORMAL] = { speed = 250, animation = ACT_HL2MP_WALK },
		[self.TaskUrgency.HIGH] = { speed = 400, animation = ACT_HL2MP_RUN },
		[self.TaskUrgency.URGENT] = { speed = 600, animation = ACT_HL2MP_RUN }
	}

	self.ReturnHomeSpeed = 350

	self.loco:SetAcceleration(400)
	self.loco:SetDeceleration(400)
end

function ENT:GoHome()
	if (not IsValid(self.HomeEntity)) then
		return "failed"
	end

	self:RequestActivity(ACT_HL2MP_WALK)
	self.loco:SetDesiredSpeed(self.ReturnHomeSpeed)
	local result = self:MoveToPos(self.HomeEntity:GetPos())
	self:RequestActivity(ACT_HL2MP_IDLE)

	return result
end

function ENT:GoToTask()
	if (not IsValid(self.TaskEntity)) then
		return "failed"
	end

	local movementData = self.MovementSpeeds[self.CurrentTaskUrgency]
	self:RequestActivity(movementData.animation)
	self.loco:SetDesiredSpeed(movementData.speed)
	local result = self:MoveToPos(self.TaskEntity:GetPos())
	self:RequestActivity(ACT_HL2MP_IDLE)

	return result
end

function ENT:HandleStuck()
	if (self.loco:IsStuck()) then
		self:RequestJumpAnimation()
		self.loco:Jump()
		coroutine.wait(0.5)
		self.loco:ClearStuck()
	end
end
