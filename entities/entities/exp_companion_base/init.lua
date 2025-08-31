AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

DEFINE_BASECLASS("exp_monster_base")

AccessorFunc(ENT, "expFriendlyToFollow", "FriendlyToFollow")
AccessorFunc(ENT, "expIsSitting", "IsSitting", FORCE_BOOL)
AccessorFunc(ENT, "expSitAfterWaiting", "SitAfterWaiting", FORCE_NUMBER)
AccessorFunc(ENT, "expCommand", "Command", FORCE_STRING)

function ENT:Initialize()
	self:SetUseType(SIMPLE_USE)
	BaseClass.Initialize(self)
end

function ENT:SetItem(itemTable, owner)
	self:SetItemInstanceID(itemTable:GetID())
	self.expItem = itemTable
	self.expItemOwner = owner

	self:SetModel(itemTable.companionModel)

	local health = itemTable.companionHealth or itemTable.companionMaxHealth or 100

	if (health ~= Schema.npc.NO_HEALTH) then
		self:SetMaxHealth(itemTable.companionMaxHealth or health)
		self:SetHealth(health)
	else
		self:SetMaxHealth(100)
		self:SetHealth(100)
		self.expIsInvincible = true
	end

	if (itemTable.companionSitAfterWaiting) then
		self:SetSitAfterWaiting(itemTable.companionSitAfterWaiting)
	end
end

function ENT:GetItem()
	return self.expItem
end

function ENT:Use(activator, caller)
	if (not IsValid(activator) or not activator:IsPlayer()) then
		return
	end

	if (Schema.util.Throttle("Use", 1, self)) then
		return
	end

	local canCommand, fault = Schema.companion.CanPlayerCommand(activator, self)

	if (not canCommand) then
		activator:Notify(fault)
		return
	end

	Schema.companion.PlayerQuickCommandMenu(activator, self)
end

function ENT:SetupSchedules()
	BaseClass.SetupSchedules(self)

	-- Add a follow schedule to run to the friendly to follow
	self.expSchedules.RunToFollow = ai_schedule.New("expFollow")
	self.expSchedules.RunToFollow:EngTask("TASK_GET_PATH_TO_TARGET", 0)
	self.expSchedules.RunToFollow:EngTask("TASK_RUN_PATH_WITHIN_DIST", 1024)
	self.expSchedules.RunToFollow:EngTask("TASK_WAIT_FOR_MOVEMENT", 0)
	self.expSchedules.RunToFollow.forceRetrigger = 1

	-- Add a follow schedule to walk to the friendly to follow
	self.expSchedules.WalkToFollow = ai_schedule.New("expFollowWalk")
	self.expSchedules.WalkToFollow:EngTask("TASK_GET_PATH_TO_TARGET", 0)
	self.expSchedules.WalkToFollow:EngTask("TASK_WALK_PATH_WITHIN_DIST", 1024)
	self.expSchedules.WalkToFollow:EngTask("TASK_WAIT_FOR_MOVEMENT", 0)
	self.expSchedules.WalkToFollow.forceRetrigger = 1

	-- Sit down and wait
	self.expSchedules.WaitSitEntry = ai_schedule.New("expWaitEntry")
	self.expSchedules.WaitSitEntry:EngTask("TASK_PLAY_SEQUENCE", ACT_BUSY_SIT_GROUND_ENTRY)
	self.expSchedules.WaitSitEntry:EngTask("TASK_WAIT_FOR_MOVEMENT", 0)

	-- Keep sitting down
	self.expSchedules.WaitSitting = ai_schedule.New("expWaiting")
	self.expSchedules.WaitSitting:EngTask("TASK_PLAY_SEQUENCE", ACT_BUSY_SIT_GROUND)
	self.expSchedules.WaitSitting:EngTask("TASK_WAIT_FOR_MOVEMENT", 0)
	self.expSchedules.WaitSitting:EngTask("TASK_WAIT", 1)

	-- Stand up from wait
	self.expSchedules.WaitSitExit = ai_schedule.New("expWaitExit")
	self.expSchedules.WaitSitExit:EngTask("TASK_PLAY_SEQUENCE", ACT_BUSY_SIT_GROUND_EXIT)
	self.expSchedules.WaitSitExit:EngTask("TASK_WAIT_FOR_MOVEMENT", 0)

	local attackMelee1 = ai_schedule.New("expAttackMelee1")
	attackMelee1:EngTask("TASK_STOP_MOVING", 0)
	attackMelee1:EngTask("TASK_FACE_ENEMY", 0)
	attackMelee1:EngTask("TASK_MELEE_ATTACK1", 0)
	attackMelee1:EngTask("TASK_WAIT_FOR_MOVEMENT", 0)
	attackMelee1:EngTask("TASK_WAIT", 0.5)
	attackMelee1.expAttackData = {
		damageAfterTask = "TASK_MELEE_ATTACK1",
		range = self:GetAttackMeleeRange(),
		damage = 2,
		damageType = DMG_SLASH,
	}

	-- Have the only attack be the melee biting attack which does only a bit of damage
	self.expSchedules.Attacks = {}
	self.expSchedules.Attacks[#self.expSchedules.Attacks + 1] = attackMelee1
end

function ENT:ShouldHibernate()
	-- For companion npcs we don't hibernate
	return false
end

function ENT:OnScheduleStarted(schedule)
	if (schedule == self.expSchedules.Patrol) then
		-- If we lose an enemy, we're patrolling
		self:SetCommand("patrol")
	elseif (schedule == self.expSchedules.Chase) then
		-- If we find the enemy again, we're attacking
		self:SetCommand("attack")
	end
end

function ENT:OnRetriggerSchedule(schedule)
	-- If our last command isn't the same, then don't retrigger
	if (not self.expLastCommand or self.expLastCommand ~= self:GetCommand()) then
		-- Prevents the schedule from being retriggered when the command changes
		-- (e.g: when patrolling, but then the player commands the companion to follow)
		return true
	end

	self.expLastCommand = self:GetCommand()

	if (schedule ~= self.expSchedules.RunToFollow and schedule ~= self.expSchedules.WalkToFollow) then
		return
	end

	-- If we're following or running and we're close to the friendly to follow, stop the schedule
	local friendlyToFollow = self:GetFriendlyToFollow()

	if (IsValid(friendlyToFollow)) then
		local distance = self:GetPos():DistToSqr(friendlyToFollow:GetPos())

		if (distance < (256 * 256)) then
			self:ClearSchedule()
			return true -- Prevent the schedule from being retriggered
		end
	end
end

function ENT:HandleFollowing(friendlyToFollow)
	self:SetTarget(friendlyToFollow)
	local targetPosition = friendlyToFollow:GetPos()
	local distance = self:GetPos():DistToSqr(targetPosition)

	-- If we are close to the friendly to follow, then we should wait
	if (distance < (256 * 256)) then
		return self:HandleWaiting()
	end

	self.expWaitingSince = nil

	if (self:GetIsSitting()) then
		self:StartSchedule(self.expSchedules.WaitSitExit)
		self:SetIsSitting(false)
		return true
	end

	-- If we are not too far away and the friendly is not running, then we should walk to the friendly to follow
	if (distance < (256 * 256) and not friendlyToFollow:IsRunning()) then
		self:StartSchedule(self.expSchedules.WalkToFollow)
		return true
	end

	-- If we are too far away, then we should run to the friendly to follow
	self:StartSchedule(self.expSchedules.RunToFollow)
	return true
end

function ENT:HandleWaiting()
	if (not self.expWaitingSince) then
		self.expWaitingSince = CurTime()
	end

	if (CurTime() - self.expWaitingSince < self:GetSitAfterWaiting()) then
		self:StartSchedule(self.expSchedules.WaitStand)
		return true
	end

	if (not self:GetIsSitting()) then
		self:StartSchedule(self.expSchedules.WaitSitEntry)
		self:SetIsSitting(true)
	else
		self:StartSchedule(self.expSchedules.WaitSitting)
	end

	return true
end

function ENT:ShouldOverrideSelectSchedule()
	local command = self:GetCommand()

	if (command == "patrol") then
		self:StartSchedule(self.expSchedules.Patrol)
		return true
	elseif (command == "stay") then
		return self:HandleWaiting()
	elseif (command == "follow") then
		local friendlyToFollow = self:GetFriendlyToFollow()

		if (IsValid(friendlyToFollow)) then
			return self:HandleFollowing(friendlyToFollow)
		end
	end

	return false
end

function ENT:FindBestTarget()
	local command = self:GetCommand()

	-- Only find enemies if we're not following a friendly or staying in place
	if (command == "follow" or command == "stay") then
		return nil
	end

	return BaseClass.FindBestTarget(self)
end

function ENT:GetRelationship(entity)
	local friendlyToFollow = self:GetFriendlyToFollow()

	-- Never target the friendly to follow, unless it is specifically marked as an enemy
	if (IsValid(friendlyToFollow) and entity == friendlyToFollow) then
		if (self.targetingSystem.currentTarget ~= entity) then
			return D_LI
		end
	end

	return BaseClass.GetRelationship(self, entity)
end

function ENT:OnRemove(isFullUpdate)
	if (not self.expItem or not IsValid(self.expItemOwner)) then
		return
	end

	-- Ensure the owner has a character
	if (not self.expItemOwner:GetCharacter()) then
		return
	end

	Schema.companion.Remove(self.expItemOwner, self.expItem)
end
