AddCSLuaFile("shared.lua")
include("shared.lua")

include("sv_ai.lua")
include("sv_combat.lua")
include("sv_animation.lua")
include("sv_movement.lua")
include("sv_states.lua")
include("sv_weapons.lua")

function ENT:Initialize()
	self:SetModel("models/hl2rp/citizens/male_02.mdl")

	-- Initialize all components
	self:InitializeAI()
	self:InitializeCombat()
	self:InitializeAnimation()
	self:InitializeMovement()
	self:InitializeStates()
	self:InitializeWeapons()

	-- Set up model and bone cache
	self:SetupModelBones()
end

function ENT:SetupModelBones()
	self.HandBoneIndex = self:LookupBone("ValveBiped.Bip01_R_Hand")

	if (not self.HandBoneIndex or self.HandBoneIndex == -1) then
		local fallbackBones = {
			"bip01_r_hand",
			"r_hand",
			"hand_R",
			"RightHand"
		}

		for _, boneName in ipairs(fallbackBones) do
			self.HandBoneIndex = self:LookupBone(boneName)

			if (self.HandBoneIndex and self.HandBoneIndex ~= -1) then
				break
			end
		end
	end
end

function ENT:RunBehaviour()
	local aiDisabledCon = GetConVar("ai_disabled")

	while (true) do
		if (not aiDisabledCon:GetBool()) then
			self:UpdateAI()
		end

		coroutine.wait(0.1)
	end
end

function ENT:BodyUpdate()
	self:UpdateAnimation()
	self:UpdateWeapons()
	self:FrameAdvance()

	-- Update weapon bone attachment if needed
	if (IsValid(self.CurrentWeapon) and self:IsArmed()) then
		self:MaintainWeaponAttachment()
	end
end

function ENT:MaintainWeaponAttachment()
	if (not IsValid(self.CurrentWeapon)) then
		return
	end

	local boneIndex = self.HandBoneIndex

	if (boneIndex and boneIndex ~= -1) then
		local bonePos = self:GetBonePosition(boneIndex)
		local weaponPos = self.CurrentWeapon:GetPos()

		-- If weapon is too far from hand bone, reattach (happens when gestures are played sometimes)
		if (bonePos:DistToSqr(weaponPos) > 10 ^ 2) then
			self:AttachWeaponToBone(self.CurrentWeapon)
		end
	end
end

function ENT:OnTakeDamage(damageInfo)
	self:HandleDamage(damageInfo)
end

function ENT:SetWalkSpeed(speed)
	self.WalkSpeed = speed or 250
	self:UpdateMovementSpeeds()
end

function ENT:SetRunSpeed(speed)
	self.RunSpeed = speed or 400
	self:UpdateMovementSpeeds()
end

function ENT:SetWeaponList(weapons)
	self.WeaponClasses = weapons or {}
	self:InitializeWeaponInventory()
end

function ENT:SetCombatWeaponSwitchDelay(delay)
	self.WeaponSwitchDelay = delay or 1.5
end

-- Helper function to get current holdtype for external access
function ENT:GetCurrentHoldType()
	if (IsValid(self.CurrentWeapon)) then
		local holdType = self.CurrentWeapon:GetHoldType()
		if (holdType and holdType ~= "") then
			return holdType
		end
	end
	return "normal"
end

-- Override for weapon-specific cleanup
function ENT:OnRemove()
	-- Clean up weapon entities
	self:RemoveAllWeapons()
end
