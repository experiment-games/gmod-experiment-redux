function ENT:InitializeAnimation()
	self.CurrentAnimationState = self.AnimationState.IDLE
	self.AnimationRequestType = self.AnimationRequest.NONE
	self.AnimationRequestData = {}
	self.LastActivity = ACT_HL2MP_IDLE
	self.RequestedActivity = ACT_HL2MP_IDLE
	self.AnimationStartTime = 0
	self.AnimationDuration = 0
	self.AnimationEndTime = 0
	self.JumpDuration = 0.8

	self:SetPoseParameter("move_x", 0)
	self:SetPoseParameter("move_y", 0)
end

function ENT:UpdateAnimation()
	local currentTime = CurTime()

	if (self.AnimationRequestType ~= self.AnimationRequest.NONE and self.AnimationEndTime <= currentTime) then
		self:ProcessAnimationRequest(currentTime)
	end

	self:UpdateAnimationState()

	if (self.RequestedActivity ~= self.LastActivity) then
		self:StartActivity(self.RequestedActivity)
		self.LastActivity = self.RequestedActivity
	end

	local activity = self:GetActivity()
	if (activity == ACT_HL2MP_IDLE or activity == ACT_HL2MP_WALK or activity == ACT_HL2MP_RUN) then
		self:BodyMoveXY()
	end
end

-- Animation requests
function ENT:RequestAttackAnimation()
	self.AnimationRequestType = self.AnimationRequest.ATTACK
	self.AnimationRequestData = {}
end

function ENT:RequestJumpAnimation()
	self.AnimationRequestType = self.AnimationRequest.JUMP
	self.AnimationRequestData = {}
end

function ENT:RequestSequenceAnimation(sequenceName, duration)
	self.AnimationRequestType = self.AnimationRequest.SEQUENCE
	self.AnimationRequestData = {
		sequenceName = sequenceName,
		duration = duration
	}
end

function ENT:RequestActivity(activity)
	self.RequestedActivity = activity
end

function ENT:IsPlayingSpecialAnimation()
	return (self.AnimationRequestType ~= self.AnimationRequest.NONE and CurTime() < self.AnimationEndTime)
end

function ENT:GetAnimationState()
	return self.CurrentAnimationState
end

function ENT:PlaySequenceAndWait(sequenceName, duration)
	self:RequestSequenceAnimation(sequenceName, duration)

	while (self:IsPlayingSpecialAnimation()) do
		coroutine.yield()
	end
end

-- Animation processing
function ENT:ProcessAnimationRequest(currentTime)
	if (self.AnimationRequestType == self.AnimationRequest.ATTACK) then
		self:ProcessAttackAnimation(currentTime)
	elseif (self.AnimationRequestType == self.AnimationRequest.JUMP) then
		self:ProcessJumpAnimation(currentTime)
	elseif (self.AnimationRequestType == self.AnimationRequest.SEQUENCE) then
		self:ProcessSequenceAnimation(currentTime)
	end
end

function ENT:ProcessAttackAnimation(currentTime)
	local activity = ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST

	if (self:SelectWeightedSequence(activity) ~= -1) then
		self:AddGesture(activity)
	end

	self.CurrentAnimationState = self.AnimationState.ATTACKING
	self.AnimationStartTime = currentTime
	self.AnimationDuration = self.AttackDuration
	self.AnimationEndTime = currentTime + self.AttackDuration
	self.AnimationRequestType = self.AnimationRequest.NONE
	self.AnimationRequestData = {}
end

function ENT:ProcessJumpAnimation(currentTime)
	local activity = ACT_HL2MP_JUMP_FIST

	if (self:SelectWeightedSequence(activity) ~= -1) then
		self:AddGesture(activity)
	end

	self.CurrentAnimationState = self.AnimationState.JUMPING
	self.AnimationStartTime = currentTime
	self.AnimationDuration = self.JumpDuration
	self.AnimationEndTime = currentTime + self.JumpDuration
	self.AnimationRequestType = self.AnimationRequest.NONE
	self.AnimationRequestData = {}
end

function ENT:ProcessSequenceAnimation(currentTime)
	local sequenceName = self.AnimationRequestData.sequenceName
	local duration = self.AnimationRequestData.duration

	local sequenceId = self:LookupSequence(sequenceName)

	if (sequenceId > 0) then
		self:ResetSequence(sequenceId)

		local seqDuration = duration or self:SequenceDuration(sequenceId)

		self.AnimationStartTime = currentTime
		self.AnimationDuration = seqDuration
		self.AnimationEndTime = currentTime + seqDuration
	else
		print("Warning: Sequence '" .. sequenceName .. "' not found on model " .. self:GetModel())
		self.AnimationEndTime = currentTime + 1
	end

	self.AnimationRequestType = self.AnimationRequest.NONE
	self.AnimationRequestData = {}
end

function ENT:UpdateAnimationState()
	if (self:IsPlayingSpecialAnimation()) then
		return
	end

	local activity = self:GetActivity()
	if (activity == ACT_HL2MP_IDLE) then
		self.CurrentAnimationState = self.AnimationState.IDLE
	elseif (activity == ACT_HL2MP_WALK) then
		self.CurrentAnimationState = self.AnimationState.WALKING
	elseif (activity == ACT_HL2MP_RUN) then
		self.CurrentAnimationState = self.AnimationState.RUNNING
	else
		self.CurrentAnimationState = self.AnimationState.IDLE
	end
end
