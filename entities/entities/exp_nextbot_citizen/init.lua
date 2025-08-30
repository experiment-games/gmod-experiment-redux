AddCSLuaFile("shared.lua")
include("shared.lua")

--- Initialize the NextBot
function ENT:Initialize()
	self:SetModel("models/hl2rp/citizens/male_02.mdl")

	self.SearchRadius = 1000
	self.LoseTargetDistance = 2000
	self.HomeRadius = 100
	self.TaskRadius = 100
	self.AttackRange = 80
	self.LastAttackedBy = nil
	self.LastAttackedTime = 0
	self.DefensiveTimeout = 10

	self.CurrentState = self.BotState.IDLE
	self.CombatModeValue = self.CombatMode.DEFENSIVE
	self.CurrentTaskUrgency = self.TaskUrgency.NORMAL
	self.CurrentAnimationState = self.AnimationState.IDLE

	self.HomeEntity = nil
	self.TaskEntity = nil
	self.CurrentEnemy = nil
	self.AggressiveTarget = nil

	self.AnimationRequestType = self.AnimationRequest.NONE
	self.AnimationRequestData = {}
	self.LastActivity = ACT_HL2MP_IDLE
	self.RequestedActivity = ACT_HL2MP_IDLE
	self.AnimationStartTime = 0
	self.AnimationDuration = 0
	self.AnimationEndTime = 0

	self.AttackDuration = 1.0
	self.JumpDuration = 0.8

	self.MovementSpeeds = {
		[self.TaskUrgency.LOW] = { speed = 150, animation = ACT_HL2MP_WALK },
		[self.TaskUrgency.NORMAL] = { speed = 250, animation = ACT_HL2MP_WALK },
		[self.TaskUrgency.HIGH] = { speed = 400, animation = ACT_HL2MP_RUN },
		[self.TaskUrgency.URGENT] = { speed = 600, animation = ACT_HL2MP_RUN }
	}

	self.CombatSpeed = 450
	self.ReturnHomeSpeed = 350

	self.loco:SetAcceleration(400)
	self.loco:SetDeceleration(400)

	self:SetPoseParameter("move_x", 0)
	self:SetPoseParameter("move_y", 0)
end

--- Request an attack animation to be played
function ENT:RequestAttackAnimation()
	self.AnimationRequestType = self.AnimationRequest.ATTACK
	self.AnimationRequestData = {}
end

--- Request a jump animation to be played
function ENT:RequestJumpAnimation()
	self.AnimationRequestType = self.AnimationRequest.JUMP
	self.AnimationRequestData = {}
end

--- Request a sequence animation to be played
--- @param sequenceName string Name of the sequence to play
--- @param duration number Duration of the sequence (optional, will estimate if not provided)
function ENT:RequestSequenceAnimation(sequenceName, duration)
	self.AnimationRequestType = self.AnimationRequest.SEQUENCE
	self.AnimationRequestData = {
		sequenceName = sequenceName,
		duration = duration
	}
end

--- Request a specific activity to be played
--- @param activity number The activity to play
function ENT:RequestActivity(activity)
	self.RequestedActivity = activity
end

--- Check if currently playing a special animation
--- @return boolean # True if playing attack, jump, or sequence
function ENT:IsPlayingSpecialAnimation()
	return self.AnimationRequestType ~= self.AnimationRequest.NONE and CurTime() < self.AnimationEndTime
end

--- Get the current animation state
--- @return string # Current animation state
function ENT:GetAnimationState()
	return self.CurrentAnimationState
end

--- Set the home entity that the bot should return to
--- @param entity Entity The entity to use as home
function ENT:SetHomeEntity(entity)
	if (IsValid(entity)) then
		self.HomeEntity = entity
	else
		self.HomeEntity = nil
	end
end

--- Get the current home entity
--- @return Entity|nil # The home entity or nil if none set
function ENT:GetHomeEntity()
	return self.HomeEntity
end

--- Set the task entity that the bot should go to for tasks
--- @param entity Entity The entity to use for tasks
function ENT:SetTaskEntity(entity)
	if (IsValid(entity)) then
		self.TaskEntity = entity
	else
		self.TaskEntity = nil
	end
end

--- Get the current task entity
--- @return Entity|nil # The task entity or nil if none set
function ENT:GetTaskEntity()
	return self.TaskEntity
end

--- Set the task urgency level
--- @param urgency string The urgency level from TaskUrgency enum
function ENT:SetTaskUrgency(urgency)
	if (self.MovementSpeeds[urgency]) then
		self.CurrentTaskUrgency = urgency
	end
end

--- Get the current task urgency
--- @return string # The current task urgency level
function ENT:GetTaskUrgency()
	return self.CurrentTaskUrgency
end

--- Enable aggressive mode targeting a specific player
--- @param player Player The player to target aggressively
function ENT:SetAggressiveMode(player)
	if (IsValid(player) and player:IsPlayer()) then
		self.CombatModeValue = self.CombatMode.AGGRESSIVE
		self.AggressiveTarget = player
	end
end

--- Disable aggressive mode and return to defensive
function ENT:SetDefensiveMode()
	self.CombatModeValue = self.CombatMode.DEFENSIVE
	self.AggressiveTarget = nil
end

--- Check if bot is in aggressive mode
--- @return boolean # True if in aggressive mode
function ENT:IsAggressiveMode()
	return self.CombatModeValue == self.CombatMode.AGGRESSIVE
end

--- Set the current enemy
--- @param entity Entity The entity to target as enemy
function ENT:SetEnemy(entity)
	self.CurrentEnemy = entity
end

--- Get the current enemy
--- @return Entity|nil # The current enemy or nil
function ENT:GetEnemy()
	return self.CurrentEnemy
end

--- Check if we have a valid enemy
--- @return boolean # True if we have a valid enemy
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

--- Find a new enemy based on current combat mode
--- @return boolean # True if enemy found
function ENT:FindEnemy()
	local foundEnemy = nil

	if (self:IsAggressiveMode() and IsValid(self.AggressiveTarget)) then
		local distance = self:GetRangeTo(self.AggressiveTarget:GetPos())
		if (distance <= self.SearchRadius and self.AggressiveTarget:Alive()) then
			foundEnemy = self.AggressiveTarget
		end
	end

	if (not foundEnemy and self.CombatModeValue == self.CombatMode.DEFENSIVE) then
		if (self.LastAttackedBy and IsValid(self.LastAttackedBy) and
				CurTime() - self.LastAttackedTime < self.DefensiveTimeout) then
			local distance = self:GetRangeTo(self.LastAttackedBy:GetPos())
			if (distance <= self.SearchRadius) then
				foundEnemy = self.LastAttackedBy
			end
		end
	end

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

	if (foundEnemy) then
		self:SetEnemy(foundEnemy)
		return true
	else
		self:SetEnemy(nil)
		return false
	end
end

--- Handle taking damage (defensive mode activation)
--- @param damageInfo CTakeDamageInfo Damage information
function ENT:OnTakeDamage(damageInfo)
	local attacker = damageInfo:GetAttacker()

	if (IsValid(attacker) and attacker:IsPlayer()) then
		self.LastAttackedBy = attacker
		self.LastAttackedTime = CurTime()

		if (not self:IsAggressiveMode()) then
			self.CurrentState = self.BotState.COMBAT
		end
	end
end

--- Check if we're at the home location
--- @return boolean # True if at home
function ENT:IsAtHome()
	if (not IsValid(self.HomeEntity)) then
		return false
	end

	return self:GetRangeTo(self.HomeEntity:GetPos()) <= self.HomeRadius
end

--- Check if we're at the task location
--- @return boolean # True if at task location
function ENT:IsAtTask()
	if (not IsValid(self.TaskEntity)) then
		return false
	end

	return self:GetRangeTo(self.TaskEntity:GetPos()) <= self.TaskRadius
end

--- Go to the home entity
--- @return string # Result of the movement ("ok", "failed", "stuck")
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

--- Go to the task entity with specified urgency
--- @return string # Result of the movement ("ok", "failed", "stuck")
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

--- Chase the current enemy
--- @param options table|nil Optional parameters for chasing
--- @return string # Result of the chase ("ok", "failed", "stuck", "lost_target")
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

--- Snaps to face the enemy
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

--- Perform an attack on the current enemy
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

--- Play a sequence and track when it ends (now uses animation request system)
--- @param sequenceName string Name of the sequence to play
--- @param duration number Duration of the sequence (optional, will estimate if not provided)
function ENT:PlaySequenceAndWait(sequenceName, duration)
	self:RequestSequenceAnimation(sequenceName, duration)

	while (self:IsPlayingSpecialAnimation()) do
		coroutine.yield()
	end
end

--- Main AI behavior loop
function ENT:RunBehaviour()
	while (true) do
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

		coroutine.wait(0.1)
	end
end

--- Handle idle state behavior
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

--- Handle going home state
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

--- Handle at home state
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

--- Handle going to task state
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

--- Handle at task state
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

--- Handle combat state
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

--- Handle returning home after combat
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

--- Perform task activities (override in derived classes)
function ENT:PerformTask()
	self:RequestActivity(ACT_HL2MP_IDLE)
	coroutine.wait(5)
end

--- Enhanced stuck handling with jump animation
function ENT:HandleStuck()
	if (self.loco:IsStuck()) then
		self:RequestJumpAnimation()
		self.loco:Jump()
		coroutine.wait(0.5)
		self.loco:ClearStuck()
	end
end

--- Enhanced body update with centralized animation management
function ENT:BodyUpdate()
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

	self:FrameAdvance()
end

--- Process pending animation requests
--- @param currentTime number Current game time
function ENT:ProcessAnimationRequest(currentTime)
	if (self.AnimationRequestType == self.AnimationRequest.ATTACK) then
		self:ProcessAttackAnimation(currentTime)
	elseif (self.AnimationRequestType == self.AnimationRequest.JUMP) then
		self:ProcessJumpAnimation(currentTime)
	elseif (self.AnimationRequestType == self.AnimationRequest.SEQUENCE) then
		self:ProcessSequenceAnimation(currentTime)
	end
end

--- Process attack animation request
--- @param currentTime number Current game time
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

--- Process jump animation request
--- @param currentTime number Current game time
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

--- Process sequence animation request
--- @param currentTime number Current game time
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

--- Update current animation state based on activity and special animations
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
