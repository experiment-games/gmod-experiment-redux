function ENT:InitializeMovement()
	-- Default speeds (can be overridden)
	self.WalkSpeed = 250
	self.RunSpeed = 400

	self:UpdateMovementSpeeds()

	self.ReturnHomeSpeed = 350

	self.loco:SetAcceleration(400)
	self.loco:SetDeceleration(400)
end

function ENT:UpdateMovementSpeeds()
	local walkThreshold = self.WalkSpeed
	local runThreshold = self.RunSpeed

	-- We might still be initializing
	if (not walkThreshold or not runThreshold) then
		return
	end

	self.MovementSpeeds = {
		[self.TaskUrgency.LOW] = {
			speed = math.min(walkThreshold * 0.6, 150),
			animation = ACT_HL2MP_WALK
		},
		[self.TaskUrgency.NORMAL] = {
			speed = walkThreshold,
			animation = ACT_HL2MP_WALK
		},
		[self.TaskUrgency.HIGH] = {
			speed = runThreshold,
			animation = ACT_HL2MP_RUN
		},
		[self.TaskUrgency.URGENT] = {
			speed = math.max(runThreshold * 1.5, 600),
			animation = ACT_HL2MP_RUN
		}
	}
end

function ENT:GetWalkSpeed()
	return self.WalkSpeed
end

function ENT:GetRunSpeed()
	return self.RunSpeed
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

function ENT:MoveAtSpeed(targetPos, speed, activity)
	activity = activity or (speed > self.WalkSpeed and ACT_HL2MP_RUN or ACT_HL2MP_WALK)

	self:RequestActivity(activity)
	self.loco:SetDesiredSpeed(speed)
	local result = self:MoveToPos(targetPos)
	self:RequestActivity(ACT_HL2MP_IDLE)

	return result
end
