AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.Spawnable = true

--- Bot behavior states
ENT.BotState = {
	IDLE = "idle",
	GOING_HOME = "going_home",
	AT_HOME = "at_home",
	GOING_TO_TASK = "going_to_task",
	AT_TASK = "at_task",
	COMBAT = "combat",
	RETURNING_HOME = "returning_home"
}

--- Combat modes
ENT.CombatMode = {
	DEFENSIVE = "defensive",
	AGGRESSIVE = "aggressive"
}

--- Task urgency levels
ENT.TaskUrgency = {
	LOW = "low",    -- Walk to task
	NORMAL = "normal", -- Normal speed
	HIGH = "high",  -- Run to task
	URGENT = "urgent" -- Sprint to task
}

--- Animation states
ENT.AnimationState = {
	IDLE = "idle",
	WALKING = "walking",
	RUNNING = "running",
	JUMPING = "jumping",
	ATTACKING = "attacking",
	ALERT = "alert"
}

if (CLIENT) then
	return
end

--- Initialize the NextBot
function ENT:Initialize()
	-- Set default model (should be overridden by derived classes)
	self:SetModel("models/hl2rp/citizens/male_02.mdl")

	-- Core configuration
	self.SearchRadius = 1000    -- How far to search for enemies
	self.LoseTargetDistance = 2000 -- How far enemy must be to lose target
	self.HomeRadius = 100       -- How close to home counts as "at home"
	self.TaskRadius = 100       -- How close to task counts as "at task"
	self.AttackRange = 80       -- Range for melee attacks
	self.LastAttackedBy = nil   -- Track who last attacked us
	self.LastAttackedTime = 0   -- When we were last attacked
	self.DefensiveTimeout = 10  -- How long to stay defensive after being attacked

	-- State management
	self.CurrentState = self.BotState.IDLE
	self.CombatModeValue = self.CombatMode.DEFENSIVE
	self.CurrentTaskUrgency = self.TaskUrgency.NORMAL
	self.CurrentAnimationState = self.AnimationState.IDLE

	-- Entity references
	self.HomeEntity = nil    -- Entity to consider "home"
	self.TaskEntity = nil    -- Entity to go to for tasks
	self.CurrentEnemy = nil  -- Current target
	self.AggressiveTarget = nil -- Specific player to attack in aggressive mode

	-- Animation tracking
	self.LastActivity = ACT_HL2MP_IDLE
	self.IsPlayingSequence = false
	self.SequenceEndTime = 0
	self.IsJumping = false
	self.IsAttacking = false
	self.JumpStartTime = 0
	self.AttackStartTime = 0

	-- Animation durations
	self.AttackDuration = 1.0 -- Duration of attack animation
	self.JumpDuration = 0.8 -- Duration of jump animation

	-- Movement speeds based on urgency
	self.MovementSpeeds = {
		[self.TaskUrgency.LOW] = { speed = 150, animation = ACT_HL2MP_WALK },
		[self.TaskUrgency.NORMAL] = { speed = 250, animation = ACT_HL2MP_WALK },
		[self.TaskUrgency.HIGH] = { speed = 400, animation = ACT_HL2MP_RUN },
		[self.TaskUrgency.URGENT] = { speed = 600, animation = ACT_HL2MP_RUN }
	}

	-- Combat speeds
	self.CombatSpeed = 450
	self.ReturnHomeSpeed = 350

	-- Initialize locomotion
	self.loco:SetAcceleration(400)
	self.loco:SetDeceleration(400)

	-- Set initial pose
	self:SetPoseParameter("move_x", 0)
	self:SetPoseParameter("move_y", 0)
end

--- Play a sequence and track when it ends
--- @param sequenceName string Name of the sequence to play
--- @param duration number Duration of the sequence (optional, will estimate if not provided)
function ENT:PlaySequenceAndWait(sequenceName, duration)
	local sequenceId = self:LookupSequence(sequenceName)

	if (sequenceId > 0) then
		self:ResetSequence(sequenceId)
		self.IsPlayingSequence = true

		-- Use provided duration or estimate from sequence
		local seqDuration = duration or self:SequenceDuration(sequenceId)
		self.SequenceEndTime = CurTime() + seqDuration

		-- Wait for sequence to complete
		while (CurTime() < self.SequenceEndTime) do
			coroutine.yield()
		end

		self.IsPlayingSequence = false
	else
		-- Fallback if sequence doesn't exist
		print("Warning: Sequence '" .. sequenceName .. "' not found on model " .. self:GetModel())
		coroutine.wait(1)
	end
end

--- Play attack animation using animation layers
function ENT:PlayAttackAnimation()
	self.IsAttacking = true
	self.AttackStartTime = CurTime()
	self.CurrentAnimationState = self.AnimationState.ATTACKING

	local activity = ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST

	if (self:SelectWeightedSequence(activity) ~= -1) then
		self:AddGesture(activity)
	end
end

--- Play jump animation using animation layers
function ENT:PlayJumpAnimation()
	self.IsJumping = true
	self.JumpStartTime = CurTime()
	self.CurrentAnimationState = self.AnimationState.JUMPING

	local activity = ACT_HL2MP_JUMP_FIST

	if (self:SelectWeightedSequence(activity) ~= -1) then
		self:AddGesture(activity)
	end
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
		-- Check if enemy is too far away
		if (self:GetRangeTo(self:GetEnemy():GetPos()) > self.LoseTargetDistance) then
			return self:FindEnemy()
		end

		-- Check if enemy is dead (for players)
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

	-- In aggressive mode, prioritize the aggressive target
	if (self:IsAggressiveMode() and IsValid(self.AggressiveTarget)) then
		local distance = self:GetRangeTo(self.AggressiveTarget:GetPos())
		if (distance <= self.SearchRadius and self.AggressiveTarget:Alive()) then
			foundEnemy = self.AggressiveTarget
		end
	end

	-- In defensive mode, check if we were recently attacked
	if (not foundEnemy and self.CombatModeValue == self.CombatMode.DEFENSIVE) then
		if (self.LastAttackedBy and IsValid(self.LastAttackedBy) and
				CurTime() - self.LastAttackedTime < self.DefensiveTimeout) then
			local distance = self:GetRangeTo(self.LastAttackedBy:GetPos())
			if (distance <= self.SearchRadius) then
				foundEnemy = self.LastAttackedBy
			end
		end
	end

	-- If no priority target, search for nearby threats
	if (not foundEnemy) then
		local entities = ents.FindInSphere(self:GetPos(), self.SearchRadius)
		for _, entity in ipairs(entities) do
			if (entity:IsPlayer() and entity:Alive()) then
				-- In aggressive mode, only target the aggressive target
				if (self:IsAggressiveMode()) then
					if (entity == self.AggressiveTarget) then
						foundEnemy = entity
						break
					end
				else
					-- In defensive mode, any valid threat
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

		-- If not in aggressive mode, enter defensive combat
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

	self:StartActivity(ACT_HL2MP_WALK)
	self.loco:SetDesiredSpeed(self.ReturnHomeSpeed)
	local result = self:MoveToPos(self.HomeEntity:GetPos())
	self:StartActivity(ACT_HL2MP_IDLE)

	return result
end

--- Go to the task entity with specified urgency
--- @return string # Result of the movement ("ok", "failed", "stuck")
function ENT:GoToTask()
	if (not IsValid(self.TaskEntity)) then
		return "failed"
	end

	local movementData = self.MovementSpeeds[self.CurrentTaskUrgency]
	self:StartActivity(movementData.animation)
	self.loco:SetDesiredSpeed(movementData.speed)
	local result = self:MoveToPos(self.TaskEntity:GetPos())
	self:StartActivity(ACT_HL2MP_IDLE)

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
		-- Update path frequently since we're chasing a moving target
		if (path:GetAge() > 0.1) then
			path:Compute(self, self:GetEnemy():GetPos())
		end

		path:Update(self)

		if (options.draw) then
			path:Draw()
		end

		-- Check if we're close enough to attack
		if (self:GetRangeTo(self:GetEnemy():GetPos()) <= self.AttackRange) then
			self:PerformAttack()
			return "attacked"
		end

		-- Handle being stuck
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

	-- Face the enemy by rotating us
	self:SnapToFaceEnemy()

	-- Play attack animation
	self:PlayAttackAnimation()

	-- Wait for attack animation to complete most of its duration before dealing damage
	local damageDelay = self.AttackDuration * 0.5 -- Deal damage halfway through animation
	coroutine.wait(damageDelay)

	-- Deal damage if still in range and enemy is still valid
	if (self:HaveEnemy() and self:GetRangeTo(self:GetEnemy():GetPos()) <= self.AttackRange) then
		local damageInfo = DamageInfo()
		damageInfo:SetDamage(25)
		damageInfo:SetAttacker(self)
		damageInfo:SetInflictor(self)
		damageInfo:SetDamageType(DMG_SLASH)

		self:GetEnemy():TakeDamageInfo(damageInfo)
	end

	-- Wait for the rest of the animation
	coroutine.wait(self.AttackDuration - damageDelay)
end

--- Main AI behavior loop
function ENT:RunBehaviour()
	while (true) do
		-- State machine
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
	-- Check for enemies first
	if (self:HaveEnemy()) then
		self.CurrentState = self.BotState.COMBAT
		return
	end

	-- Decide what to do based on available entities
	if (IsValid(self.TaskEntity) and not self:IsAtTask()) then
		self.CurrentState = self.BotState.GOING_TO_TASK
	elseif (IsValid(self.HomeEntity) and not self:IsAtHome()) then
		self.CurrentState = self.BotState.GOING_HOME
	else
		-- Wander around randomly
		self:StartActivity(ACT_HL2MP_WALK)
		self.loco:SetDesiredSpeed(200)
		self:MoveToPos(self:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0) * 400)
		self:StartActivity(ACT_HL2MP_IDLE)
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

	-- Check if we should go to task
	if (IsValid(self.TaskEntity) and not self:IsAtTask()) then
		self.CurrentState = self.BotState.GOING_TO_TASK
		return
	end

	-- Idle at home
	self:StartActivity(ACT_HL2MP_IDLE)
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

	-- Perform task-related activities here
	-- This should be overridden by derived classes
	self:PerformTask()

	-- After task, return home or go idle
	if (IsValid(self.HomeEntity)) then
		self.CurrentState = self.BotState.RETURNING_HOME
	else
		self.CurrentState = self.BotState.IDLE
	end
end

--- Handle combat state
function ENT:HandleCombatState()
	if (not self:HaveEnemy()) then
		-- No more enemies, return to previous behavior
		if (IsValid(self.HomeEntity)) then
			self.CurrentState = self.BotState.RETURNING_HOME
		else
			self.CurrentState = self.BotState.IDLE
		end

		return
	end

	-- Face the enemy
	self.loco:FaceTowards(self:GetEnemy():GetPos())

	-- Set combat movement
	self:StartActivity(ACT_HL2MP_RUN)
	self.loco:SetDesiredSpeed(self.CombatSpeed)
	self.loco:SetAcceleration(900)

	-- Chase and attack
	local result = self:ChaseEnemy()

	-- Reset movement settings
	self.loco:SetAcceleration(400)

	if (result == "attacked") then
		-- Continue combat after brief pause
		coroutine.wait(0.5)
	elseif (result == "lost_target") then
		-- Lost target, transition out of combat
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
	-- Default task behavior - just idle
	self:StartActivity(ACT_HL2MP_IDLE)
	coroutine.wait(5)
end

--- Enhanced stuck handling with jump animation
function ENT:HandleStuck()
	-- Try jumping to get unstuck with proper animation
	if (self.loco:IsStuck()) then
		self:PlayJumpAnimation()
		self.loco:Jump()
		coroutine.wait(0.5)
		self.loco:ClearStuck()
	end
end

--- Enhanced body update with animation management
function ENT:BodyUpdate()
	local activity = self:GetActivity()

	if (
			ACT_HL2MP_IDLE
			or activity == ACT_HL2MP_WALK
			or activity == ACT_HL2MP_RUN
		) then
		self:BodyMoveXY()
	end

	self:FrameAdvance()
end

--- Get the current animation state
--- @return string # Current animation state
function ENT:GetAnimationState()
	return self.CurrentAnimationState
end

--- Check if currently playing a special animation
--- @return boolean # True if playing attack, jump, or sequence
function ENT:IsPlayingSpecialAnimation()
	return self.IsAttacking or self.IsJumping or self.IsPlayingSequence
end
