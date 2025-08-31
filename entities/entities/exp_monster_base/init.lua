AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

include("sv_chat.lua")
include("sv_combat.lua")
include("sv_inventory.lua")
include("sv_scheduling.lua")
include("sv_targeting.lua")
include("sv_voice.lua")

DEFINE_BASECLASS("base_ai")

AccessorFunc(ENT, "expVoicePitch", "VoicePitch", FORCE_NUMBER)
AccessorFunc(ENT, "expAttackMeleeRange", "AttackMeleeRange", FORCE_NUMBER)
AccessorFunc(ENT, "expAttackRange", "AttackRange", FORCE_NUMBER)
AccessorFunc(ENT, "expSenseRange", "SenseRange", FORCE_NUMBER)
AccessorFunc(ENT, "expChatClass", "ChatClass", FORCE_STRING)

function ENT:Initialize()
	self:Boot()
end

function ENT:Boot()
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
	self:SetCustomCollisionCheck(true)
	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_CUSTOM)

	self:CapabilitiesClear()
	self:CapabilitiesAdd(
		bit.bor(
			CAP_SKIP_NAV_GROUND_CHECK,
			CAP_USE_SHOT_REGULATOR,
			CAP_MOVE_GROUND,
			CAP_ANIMATEDFACE,
			CAP_TURN_HEAD,
			CAP_INNATE_MELEE_ATTACK1
		)
	)

	self:SetNPCClass(CLASS_ZOMBIE)
	self:SetMaxLookDistance(9000)
	self:SetMaxYawSpeed(256)

	-- Set default values
	if (not self:GetAttackMeleeRange()) then
		self:SetAttackMeleeRange(55)
	end

	if (not self:GetSenseRange()) then
		self:SetSenseRange(512)
	end

	if (not self:GetVoicePitch()) then
		self:SetVoicePitch(100)
	end

	-- Initialize systems
	self:InitializeVoiceSystem()
	self:InitializeScheduleSystem()
	self:InitializeTargetingSystem()
	self:InitializeAttackSystem()
	self:InitializeInventorySystem()
end

function ENT:SetupVoiceSounds()
	-- Override this in subclasses
end

function ENT:SetupSchedules()
	self.expSchedules.WaitStand = ai_schedule.New("expWaitStand")
	self.expSchedules.WaitStand:EngTask("TASK_WAIT", 1)

	self.expSchedules.Patrol = ai_schedule.New("expPatrol")
	self.expSchedules.Patrol:EngTask("TASK_WAIT_FOR_MOVEMENT", 0)
	self.expSchedules.Patrol:EngTask("TASK_WANDER", 480512)
	self.expSchedules.Patrol:EngTask("TASK_FACE_PATH", 0)
	self.expSchedules.Patrol:EngTask("TASK_WALK_PATH", 0)
	self.expSchedules.Patrol:EngTask("TASK_WAIT_FOR_MOVEMENT", 0)
	self.expSchedules.Patrol.forceRetrigger = 1

	self.expSchedules.Chase = ai_schedule.New("expChase")
	self.expSchedules.Chase:EngTask("TASK_GET_PATH_TO_ENEMY", 0)
	self.expSchedules.Chase:EngTask("TASK_RUN_PATH_WITHIN_DIST", 1024)
	self.expSchedules.Chase:EngTask("TASK_WAIT_FOR_MOVEMENT", 0)
	self.expSchedules.Chase.forceRetrigger = 1

	local attackMelee1 = ai_schedule.New("expAttackMelee1")
	attackMelee1:EngTask("TASK_STOP_MOVING", 0)
	attackMelee1:EngTask("TASK_FACE_ENEMY", 0)
	attackMelee1:EngTask("TASK_MELEE_ATTACK1", 0)
	attackMelee1:EngTask("TASK_WAIT_FOR_MOVEMENT", 0)
	attackMelee1:EngTask("TASK_WAIT", 0.5)
	attackMelee1.expAttackData = {
		damageAfterTask = "TASK_MELEE_ATTACK1",
		range = self:GetAttackMeleeRange(),
		damage = 5,
		damageType = DMG_SLASH,
	}

	self.expSchedules.Attacks[#self.expSchedules.Attacks + 1] = attackMelee1
end

-- Defaults to hating players
function ENT:GetRelationship(entity)
	-- Commented as this would cause AddEntityRelationship to not work
	-- if (entity:IsPlayer()) then
	-- 	return D_HT
	-- end

	-- return D_NU
end

--- Override this method inside your derived monster entity to specify custom handles
function ENT:SetupAttackHandles()
	self:ClearAttackHandles()

	local leftHandBone = self:LookupBone("ValveBiped.Bip01_L_Hand")

	if (leftHandBone) then
		self:CreateAttackHandle("left_hand", leftHandBone, Vector(0, 0, 0), 8)
	end

	local rightHandBone = self:LookupBone("ValveBiped.Bip01_R_Hand")

	if (rightHandBone) then
		self:CreateAttackHandle("right_hand", rightHandBone, Vector(0, 0, 0), 8)
	end
end

function ENT:Think()
	if self:ShouldHibernate() then
		self:StopMoving()
		self:ClearSchedule()
		self:NextThink(CurTime() + 5)
		return true
	end

	-- Always scan for new targets periodically, even if we have one
	if Schema.util.Throttle("ScanForTargets", 0.5, self) then
		local newTarget = self:FindBestTarget()
		if IsValid(newTarget) then
			-- If we found a higher priority target, switch to it
			local currentTarget = self.targetingSystem.currentTarget
			if not IsValid(currentTarget) or self:GetTargetPriority(newTarget) > self:GetTargetPriority(currentTarget) then
				self:SetTargetEntity(newTarget)
			end
		end
	end

	-- Check if we should resume chasing primary target
	-- This happens when we were targeting an obstacle (like a door) but should go back to the primary target
	if (IsValid(self.targetingSystem.primaryTarget) and
			IsValid(self.targetingSystem.currentTarget) and
			self.targetingSystem.currentTarget ~= self.targetingSystem.primaryTarget) then
		-- If current target is an obstacle and we should resume primary target
		if (self.targetingSystem.currentTarget:IsDoor() and self:ShouldResumeChasePrimaryTarget()) then
			self:SetTargetEntity(self.targetingSystem.primaryTarget)
		end
	end

	-- Find targets if we don't have one
	local currentTarget = self.targetingSystem.currentTarget
	if (not self:IsValidTarget(currentTarget)) then
		-- Try to resume primary target first
		if (IsValid(self.targetingSystem.primaryTarget) and self:ShouldResumeChasePrimaryTarget()) then
			self:SetTargetEntity(self.targetingSystem.primaryTarget)
			currentTarget = self.targetingSystem.primaryTarget
		else
			-- Look for new target
			local newTarget = self:FindBestTarget()

			if (IsValid(newTarget)) then
				self:SetTargetEntity(newTarget)
				currentTarget = newTarget
			end
		end
	end

	-- Update target visibility and handle chasing logic
	if (not IsValid(currentTarget)) then
		-- No target - play idle sounds
		self:SpeakFromTypedVoiceSet("Idle", 5)
		return
	end

	if (not currentTarget:IsDoor() and not self:CanSeeTarget(currentTarget)) then
		-- Can't see the target and not trying to go through a door, we will lose this target
		self:OnTargetLost(currentTarget)

		if (self.targetingSystem.lostTargetCount >= 3) then
			-- If we're losing our current target, try to resume primary target before giving up
			if (IsValid(self.targetingSystem.primaryTarget) and
					self.targetingSystem.primaryTarget ~= currentTarget and
					self:ShouldResumeChasePrimaryTarget()) then
				self:SetTargetEntity(self.targetingSystem.primaryTarget)
			else
				self:SetTargetEntity(nil)
				currentTarget = nil
			end
		end
	else
		-- We can see the target, updating our position memory, so we know where it last was.
		self.targetingSystem.lostTargetCount = 0

		if (not currentTarget:IsDoor()) then
			self:UpdateEnemyMemory(currentTarget, currentTarget:GetPos())
		end
	end

	-- Handle immediate melee range attacks during chase
	if (self:GetSchedule() == self.expSchedules.Chase) then
		if (self:IsTargetInMeleeRange(currentTarget)) then
			self:ClearSchedule()
			self:StartAttackSchedule(currentTarget)
		end
	end

	if (IsValid(currentTarget)) then
		self:SpeakFromTypedVoiceSet("Chase", 2)
	end
end

function ENT:ShouldHibernate()
	local hibernationRange = self:GetRangeSquared(1500)

	for _, player in ipairs(player.GetAll()) do
		if (player:GetMoveType() ~= MOVETYPE_NOCLIP) then
			if (self:GetPos():DistToSqr(player:GetPos()) < hibernationRange) then
				return false
			end
		end
	end

	return true
end

function ENT:OnRemove()
	self:ClearAttackHandles()
end

--[[
	Utility Functions
--]]
function ENT:GetRangeSquared(range)
	return range ^ 2
end

-- Gets the closest point on an entity's bounding box
function ENT:GetClosestPointOnEntity(entity)
	local ourPos = self:GetPos()
	local mins, maxs = entity:GetCollisionBounds()
	local entityPos = entity:GetPos()

	-- Calculate the closest point on the entity's bounding box to our position
	local closestPoint = Vector(
		math.Clamp(ourPos.x, entityPos.x + mins.x, entityPos.x + maxs.x),
		math.Clamp(ourPos.y, entityPos.y + mins.y, entityPos.y + maxs.y),
		math.Clamp(ourPos.z, entityPos.z + mins.z, entityPos.z + maxs.z)
	)

	return closestPoint
end

-- Gets the distance to closest point on entity
function ENT:GetDistanceToEntity(entity)
	if not IsValid(entity) then return math.huge end

	local closestPoint = self:GetClosestPointOnEntity(entity)
	return self:GetPos():Distance(closestPoint)
end

-- Geths the squared distance to closest point on entity
function ENT:GetDistanceToEntitySqr(entity)
	if not IsValid(entity) then return math.huge end

	local closestPoint = self:GetClosestPointOnEntity(entity)
	return self:GetPos():DistToSqr(closestPoint)
end

function ENT:AnimEventID(eventName)
	return util.GetAnimEventIDByName(eventName)
end

function ENT:GetFailMessage(failCode)
	local failMessages = {
		[0] = "No task failure",
		[1] = "No target",
		[2] = "Weapon owned",
		[3] = "Item not found",
		[4] = "No hint node",
		[5] = "Schedule not found",
		[6] = "No enemy",
		[7] = "No backaway node",
		[8] = "No cover",
		[9] = "No flank",
		[10] = "No shoot",
		[11] = "No route",
		[12] = "No route (goal)",
		[13] = "No route (blocked)",
		[14] = "No route (illegal)",
		[15] = "No walk",
		[16] = "Already locked",
		[17] = "No sound",
		[18] = "No scent",
		[19] = "Bad activity",
		[20] = "No goal",
		[21] = "No player",
		[22] = "No reachable node",
		[23] = "No AI network",
		[24] = "Bad position",
		[25] = "Bad path goal",
		[26] = "Stuck on top",
		[27] = "Item taken"
	}
	return failMessages[failCode] or "Unknown failure"
end
