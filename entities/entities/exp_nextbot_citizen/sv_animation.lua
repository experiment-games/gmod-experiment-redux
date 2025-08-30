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

-- Get holdtype-specific activities
function ENT:GetHoldTypeActivity(baseActivity)
	local holdType = self:GetCurrentHoldType()

	-- Map base activities to holdtype-specific activities
	local activityMap = {
		["normal"] = {
			[ACT_HL2MP_IDLE] = ACT_HL2MP_IDLE,
			[ACT_HL2MP_WALK] = ACT_HL2MP_WALK,
			[ACT_HL2MP_RUN] = ACT_HL2MP_RUN
		},
		["pistol"] = {
			[ACT_HL2MP_IDLE] = ACT_HL2MP_IDLE_PISTOL,
			[ACT_HL2MP_WALK] = ACT_HL2MP_WALK_PISTOL,
			[ACT_HL2MP_RUN] = ACT_HL2MP_RUN_PISTOL
		},
		["smg"] = {
			[ACT_HL2MP_IDLE] = ACT_HL2MP_IDLE_SMG1,
			[ACT_HL2MP_WALK] = ACT_HL2MP_WALK_SMG1,
			[ACT_HL2MP_RUN] = ACT_HL2MP_RUN_SMG1
		},
		["ar2"] = {
			[ACT_HL2MP_IDLE] = ACT_HL2MP_IDLE_AR2,
			[ACT_HL2MP_WALK] = ACT_HL2MP_WALK_AR2,
			[ACT_HL2MP_RUN] = ACT_HL2MP_RUN_AR2
		},
		["shotgun"] = {
			[ACT_HL2MP_IDLE] = ACT_HL2MP_IDLE_SHOTGUN,
			[ACT_HL2MP_WALK] = ACT_HL2MP_WALK_SHOTGUN,
			[ACT_HL2MP_RUN] = ACT_HL2MP_RUN_SHOTGUN
		},
		["crossbow"] = {
			[ACT_HL2MP_IDLE] = ACT_HL2MP_IDLE_CROSSBOW,
			[ACT_HL2MP_WALK] = ACT_HL2MP_WALK_CROSSBOW,
			[ACT_HL2MP_RUN] = ACT_HL2MP_RUN_CROSSBOW
		},
		["melee"] = {
			[ACT_HL2MP_IDLE] = ACT_HL2MP_IDLE_MELEE,
			[ACT_HL2MP_WALK] = ACT_HL2MP_WALK_MELEE,
			[ACT_HL2MP_RUN] = ACT_HL2MP_RUN_MELEE
		},
		["melee2"] = {
			[ACT_HL2MP_IDLE] = ACT_HL2MP_IDLE_MELEE2,
			[ACT_HL2MP_WALK] = ACT_HL2MP_WALK_MELEE2,
			[ACT_HL2MP_RUN] = ACT_HL2MP_RUN_MELEE2
		},
		["knife"] = {
			[ACT_HL2MP_IDLE] = ACT_HL2MP_IDLE_KNIFE,
			[ACT_HL2MP_WALK] = ACT_HL2MP_WALK_KNIFE,
			[ACT_HL2MP_RUN] = ACT_HL2MP_RUN_KNIFE
		},
		["duel"] = {
			[ACT_HL2MP_IDLE] = ACT_HL2MP_IDLE_DUEL,
			[ACT_HL2MP_WALK] = ACT_HL2MP_WALK_DUEL,
			[ACT_HL2MP_RUN] = ACT_HL2MP_RUN_DUEL
		},
		["slam"] = {
			[ACT_HL2MP_IDLE] = ACT_HL2MP_IDLE_SLAM,
			[ACT_HL2MP_WALK] = ACT_HL2MP_WALK_SLAM,
			[ACT_HL2MP_RUN] = ACT_HL2MP_RUN_SLAM
		},
		["fist"] = {
			[ACT_HL2MP_IDLE] = ACT_HL2MP_IDLE_FIST,
			[ACT_HL2MP_WALK] = ACT_HL2MP_WALK_FIST,
			[ACT_HL2MP_RUN] = ACT_HL2MP_RUN_FIST
		}
	}

	-- Get the holdtype-specific activity map
	local holdTypeMap = activityMap[holdType]
	if (holdTypeMap and holdTypeMap[baseActivity]) then
		return holdTypeMap[baseActivity]
	end

	-- Fallback to base activity if no mapping exists
	return baseActivity
end

-- Get holdtype-specific attack activities
function ENT:GetHoldTypeAttackActivity()
	local holdType = self:GetCurrentHoldType()

	local attackActivityMap = {
		["normal"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST,
		["pistol"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL,
		["smg"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1,
		["ar2"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2,
		["shotgun"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN,
		["crossbow"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW,
		["melee"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE,
		["melee2"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2,
		["knife"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE,
		["duel"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_DUEL,
		["slam"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM,
		["fist"] = ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST
	}

	return attackActivityMap[holdType] or ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST
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
	-- Convert to holdtype-specific activity
	local holdTypeActivity = self:GetHoldTypeActivity(activity)
	self.RequestedActivity = holdTypeActivity
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
	local activity = self:GetHoldTypeAttackActivity()

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
	local holdType = self:GetCurrentHoldType()
	local activity = ACT_HL2MP_JUMP_FIST -- Default jump activity

	-- Use holdtype-specific jump activities if available
	local jumpActivityMap = {
		["pistol"] = ACT_HL2MP_JUMP_PISTOL,
		["smg"] = ACT_HL2MP_JUMP_SMG1,
		["ar2"] = ACT_HL2MP_JUMP_AR2,
		["shotgun"] = ACT_HL2MP_JUMP_SHOTGUN,
		["crossbow"] = ACT_HL2MP_JUMP_CROSSBOW,
		["melee"] = ACT_HL2MP_JUMP_MELEE,
		["melee2"] = ACT_HL2MP_JUMP_MELEE2,
		["knife"] = ACT_HL2MP_JUMP_KNIFE,
		["duel"] = ACT_HL2MP_JUMP_DUEL,
		["slam"] = ACT_HL2MP_JUMP_SLAM,
		["fist"] = ACT_HL2MP_JUMP_FIST
	}

	activity = jumpActivityMap[holdType] or ACT_HL2MP_JUMP_FIST

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

	-- Check for holdtype-specific activities to determine state
	local holdType = self:GetCurrentHoldType()

	-- Get the base activity (without holdtype modifier)
	local baseActivity = self:GetBaseActivity(activity)

	if (baseActivity == ACT_HL2MP_IDLE) then
		self.CurrentAnimationState = self.AnimationState.IDLE
	elseif (baseActivity == ACT_HL2MP_WALK) then
		self.CurrentAnimationState = self.AnimationState.WALKING
	elseif (baseActivity == ACT_HL2MP_RUN) then
		self.CurrentAnimationState = self.AnimationState.RUNNING
	else
		self.CurrentAnimationState = self.AnimationState.IDLE
	end
end

-- Helper function to get base activity from holdtype-specific activity
function ENT:GetBaseActivity(activity)
	-- Map holdtype-specific activities back to base activities
	local reverseActivityMap = {
		-- Idle activities
		[ACT_HL2MP_IDLE] = ACT_HL2MP_IDLE,
		[ACT_HL2MP_IDLE_PISTOL] = ACT_HL2MP_IDLE,
		[ACT_HL2MP_IDLE_SMG1] = ACT_HL2MP_IDLE,
		[ACT_HL2MP_IDLE_AR2] = ACT_HL2MP_IDLE,
		[ACT_HL2MP_IDLE_SHOTGUN] = ACT_HL2MP_IDLE,
		[ACT_HL2MP_IDLE_CROSSBOW] = ACT_HL2MP_IDLE,
		[ACT_HL2MP_IDLE_MELEE] = ACT_HL2MP_IDLE,
		[ACT_HL2MP_IDLE_MELEE2] = ACT_HL2MP_IDLE,
		[ACT_HL2MP_IDLE_KNIFE] = ACT_HL2MP_IDLE,
		[ACT_HL2MP_IDLE_DUEL] = ACT_HL2MP_IDLE,
		[ACT_HL2MP_IDLE_SLAM] = ACT_HL2MP_IDLE,
		[ACT_HL2MP_IDLE_FIST] = ACT_HL2MP_IDLE,

		-- Walk activities
		[ACT_HL2MP_WALK] = ACT_HL2MP_WALK,
		[ACT_HL2MP_WALK_PISTOL] = ACT_HL2MP_WALK,
		[ACT_HL2MP_WALK_SMG1] = ACT_HL2MP_WALK,
		[ACT_HL2MP_WALK_AR2] = ACT_HL2MP_WALK,
		[ACT_HL2MP_WALK_SHOTGUN] = ACT_HL2MP_WALK,
		[ACT_HL2MP_WALK_CROSSBOW] = ACT_HL2MP_WALK,
		[ACT_HL2MP_WALK_MELEE] = ACT_HL2MP_WALK,
		[ACT_HL2MP_WALK_MELEE2] = ACT_HL2MP_WALK,
		[ACT_HL2MP_WALK_KNIFE] = ACT_HL2MP_WALK,
		[ACT_HL2MP_WALK_DUEL] = ACT_HL2MP_WALK,
		[ACT_HL2MP_WALK_SLAM] = ACT_HL2MP_WALK,
		[ACT_HL2MP_WALK_FIST] = ACT_HL2MP_WALK,

		-- Run activities
		[ACT_HL2MP_RUN] = ACT_HL2MP_RUN,
		[ACT_HL2MP_RUN_PISTOL] = ACT_HL2MP_RUN,
		[ACT_HL2MP_RUN_SMG1] = ACT_HL2MP_RUN,
		[ACT_HL2MP_RUN_AR2] = ACT_HL2MP_RUN,
		[ACT_HL2MP_RUN_SHOTGUN] = ACT_HL2MP_RUN,
		[ACT_HL2MP_RUN_CROSSBOW] = ACT_HL2MP_RUN,
		[ACT_HL2MP_RUN_MELEE] = ACT_HL2MP_RUN,
		[ACT_HL2MP_RUN_MELEE2] = ACT_HL2MP_RUN,
		[ACT_HL2MP_RUN_KNIFE] = ACT_HL2MP_RUN,
		[ACT_HL2MP_RUN_DUEL] = ACT_HL2MP_RUN,
		[ACT_HL2MP_RUN_SLAM] = ACT_HL2MP_RUN,
		[ACT_HL2MP_RUN_FIST] = ACT_HL2MP_RUN
	}

	return reverseActivityMap[activity] or activity
end
