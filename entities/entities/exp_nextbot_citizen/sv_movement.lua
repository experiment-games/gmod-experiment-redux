function ENT:InitializeMovement()
	-- Default speeds (can be overridden)
	self.WalkSpeed = 250
	self.RunSpeed = 400

	self:UpdateMovementSpeeds()

	self.ReturnHomeSpeed = 350

	self.loco:SetAcceleration(400)
	self.loco:SetDeceleration(400)

	-- Fix for stuck handling
	self.LastStuckCheck = 0
	self.StuckCheckInterval = 1.0
	self.LastPosition = Vector(0, 0, 0)
	self.StuckThreshold = 10 -- If we haven't moved this distance in StuckCheckInterval, we're stuck
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

-- FIXED: Improved stuck handling
function ENT:HandleStuck()
	print("=== HANDLING STUCK SITUATION ===")

	if (self.loco:IsStuck()) then
		print("Bot is stuck, attempting to resolve...")

		-- Try jumping first
		self:RequestJumpAnimation()
		self.loco:Jump()

		-- Wait a bit for the jump
		local jumpWaitTime = 0
		while jumpWaitTime < 0.8 do
			coroutine.wait(0.1)
			jumpWaitTime = jumpWaitTime + 0.1

			-- If we're no longer stuck, break out early
			if not self.loco:IsStuck() then
				break
			end
		end

		-- Clear the stuck state
		self.loco:ClearStuck()

		-- If still stuck after jump, try moving in a random direction
		if self.loco:IsStuck() then
			print("Still stuck after jump, trying random movement...")
			local randomDir = Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0):GetNormalized()
			local newPos = self:GetPos() + randomDir * 100

			self:RequestActivity(ACT_HL2MP_WALK)
			self.loco:SetDesiredSpeed(200)
			self:MoveToPos(newPos)

			coroutine.wait(1.0)
			self.loco:ClearStuck()
		end
	end
end

-- FIXED: Better stuck detection
function ENT:CheckIfStuck()
	local currentTime = CurTime()

	if currentTime - self.LastStuckCheck >= self.StuckCheckInterval then
		local currentPos = self:GetPos()
		local distanceMoved = currentPos:Distance(self.LastPosition)

		-- If we haven't moved much and we're supposed to be moving
		if distanceMoved < self.StuckThreshold and self.loco:GetDesiredSpeed() > 0 then
			-- Mark as stuck
			if not self.loco:IsStuck() then
				print("Detected stuck condition, distance moved:", distanceMoved)
				self.loco:SetStuck()
			end
		end

		self.LastPosition = currentPos
		self.LastStuckCheck = currentTime
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

-- Override MoveToPos to include stuck checking
function ENT:MoveToPos(pos)
	local path = Path("Follow")
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(20)
	path:Compute(self, pos)

	if not path:IsValid() then
		return "failed"
	end

	-- Reset stuck detection
	self.LastPosition = self:GetPos()
	self.LastStuckCheck = CurTime()

	while path:IsValid() do
		-- Check for stuck condition
		self:CheckIfStuck()

		if self.loco:IsStuck() then
			self:HandleStuck()
			-- Recompute path after getting unstuck
			path:Compute(self, pos)
			if not path:IsValid() then
				return "stuck"
			end
		end

		if path:GetAge() > 0.1 then
			path:Compute(self, pos)
		end

		path:Update(self)

		if self:GetRangeTo(pos) < 50 then
			return "ok"
		end

		coroutine.yield()
	end

	return "failed"
end
