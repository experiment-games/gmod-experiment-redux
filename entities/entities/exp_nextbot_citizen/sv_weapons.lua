function ENT:InitializeWeapons()
	self.WeaponClasses = {} -- Can be set with SetWeaponList()
	self.CurrentWeaponIndex = 1
	self.CurrentWeapon = nil
	self.WeaponInventory = {} -- Store actual weapon entities
	self.CurrentWeaponState = self.WeaponState.UNARMED
	self.WeaponSwitchDelay = 1.5
	self.LastWeaponSwitch = 0
	self.WeaponSwitchInProgress = false
	self.CurrentHoldType = "normal" -- Track current weapon holdtype

	self.PreferredWeaponRange = {
		melee = 100,
		close = 300,
		medium = 800,
		long = 1500
	}

	if (#self.WeaponClasses > 0) then
		self:InitializeWeaponInventory()
	end
end

--- Checks if the given weapon class is a default Half-Life weapon
local function isDefaultWeapon(weaponClass)
	return table.HasValue({
		"weapon_pistol",
		"weapon_smg1",
		"weapon_ar2",
		"weapon_crowbar"
	}, weaponClass)
end

function ENT:InitializeWeaponInventory()
	self:RemoveAllWeapons()
	self.WeaponInventory = {}

	for _, weaponClass in ipairs(self.WeaponClasses) do
		if (isDefaultWeapon(weaponClass)) then
			ix.util.SchemaErrorNoHalt("Cannot give default weapon " .. weaponClass .. " to NextBot citizen. Skipping.")
			continue
		end

		local weapon = self:CreateWeapon(weaponClass)

		if (IsValid(weapon)) then
			table.insert(self.WeaponInventory, weapon)
			self:SetupWeapon(weapon)
		end
	end

	if (#self.WeaponInventory > 0) then
		self:SwitchToWeapon(1)
	end
end

function ENT:CreateWeapon(weaponClass)
	-- Create weapon entity and attach it to the NextBot
	local weapon = ents.Create(weaponClass)
	if (not IsValid(weapon)) then
		return nil
	end

	weapon:SetPos(self:GetPos())
	weapon:SetAngles(self:GetAngles())
	weapon:Spawn()
	weapon:Activate()

	-- Parent the weapon to the NextBot
	weapon:SetParent(self)
	weapon:SetOwner(self)

	-- Hide the weapon initially
	weapon:SetNoDraw(true)

	return weapon
end

function ENT:SetupWeapon(weapon)
	-- Override this in derived classes for weapon-specific setup
	-- Example: weapon:SetClip1(weapon:GetMaxClip1())
	if (IsValid(weapon)) then
		weapon:SetNoDraw(true) -- Keep hidden until equipped

		-- Set up weapon attachment
		self:AttachWeaponToBone(weapon)
	end
end

function ENT:AttachWeaponToBone(weapon)
	if (not IsValid(weapon)) then
		return
	end

	-- Get the right hand bone for weapon attachment
	local boneIndex = self:LookupBone("ValveBiped.Bip01_R_Hand")

	if (not boneIndex or boneIndex == -1) then
		-- Fallback bone names for different models
		local fallbackBones = {
			"bip01_r_hand",
			"r_hand",
			"hand_R",
			"RightHand"
		}

		for _, boneName in ipairs(fallbackBones) do
			boneIndex = self:LookupBone(boneName)
			if (boneIndex and boneIndex ~= -1) then
				break
			end
		end
	end

	if (boneIndex and boneIndex ~= -1) then
		-- Get weapon-specific attachment offset and angles
		local offset, angles = self:GetWeaponAttachmentTransform(weapon)

		-- Use FollowBone to attach weapon to hand
		weapon:FollowBone(self, boneIndex)
		weapon:SetLocalPos(offset)
		weapon:SetLocalAngles(angles)
	else
		print("Warning: Could not find hand bone for weapon attachment")
		-- Fallback: just parent to entity without bone attachment
		weapon:SetParent(self)
	end
end

function ENT:GetWeaponAttachmentTransform(weapon)
	-- Define weapon-specific attachment offsets and angles
	-- Override this method for custom weapon positioning
	local weaponClass = weapon:GetClass()
	local offset = Vector(4, 2, -2) -- Default offset
	local angles = Angle(0, 0, 0) -- Default angles

	-- Weapon-specific adjustments
	if (string.find(string.lower(weaponClass), "pistol")) then
		offset = Vector(4, 1, -1)
		angles = Angle(0, 0, 0)
	elseif (string.find(string.lower(weaponClass), "rifle") or string.find(string.lower(weaponClass), "smg")) then
		offset = Vector(8, 2, -2)
		angles = Angle(0, 0, 0)
	elseif (string.find(string.lower(weaponClass), "shotgun")) then
		offset = Vector(10, 2, -2)
		angles = Angle(0, 0, 0)
	elseif (string.find(string.lower(weaponClass), "knife") or string.find(string.lower(weaponClass), "melee")) then
		offset = Vector(3, 1, -1)
		angles = Angle(-45, 0, 0)
	end

	return offset, angles
end

function ENT:UpdateWeapons()
	if (self.WeaponSwitchInProgress and CurTime() - self.LastWeaponSwitch >= self.WeaponSwitchDelay) then
		self:CompleteWeaponSwitch()
	end
end

function ENT:GetWeaponCount()
	return #self.WeaponInventory
end

function ENT:HasWeapons()
	return (#self.WeaponInventory > 0)
end

function ENT:GetCurrentWeapon()
	return self.CurrentWeapon
end

function ENT:GetWeaponList()
	return self.WeaponClasses
end

function ENT:GetWeaponInventory()
	return self.WeaponInventory
end

function ENT:GetCurrentHoldType()
	if (IsValid(self.CurrentWeapon)) then
		local holdType = self.CurrentWeapon:GetHoldType()
		if (holdType and holdType ~= "") then
			return holdType
		end
	end
	return "normal"
end

function ENT:SwitchToWeapon(index)
	if (#self.WeaponInventory == 0) then
		return false
	end

	index = math.Clamp(index, 1, #self.WeaponInventory)

	if (index == self.CurrentWeaponIndex and IsValid(self.CurrentWeapon)) then
		return true -- Already have this weapon
	end

	local weapon = self.WeaponInventory[index]
	if (not IsValid(weapon)) then
		return false
	end

	self.WeaponSwitchInProgress = true
	self.LastWeaponSwitch = CurTime()
	self.CurrentWeaponState = self.WeaponState.SWITCHING
	self.CurrentWeaponIndex = index

	-- Hide current weapon
	if (IsValid(self.CurrentWeapon)) then
		self.CurrentWeapon:SetNoDraw(true)
		self:OnWeaponHolstered(self.CurrentWeapon)
	end

	return true
end

function ENT:CompleteWeaponSwitch()
	if (not self.WeaponSwitchInProgress) then
		return
	end

	local weapon = self.WeaponInventory[self.CurrentWeaponIndex]

	if (not IsValid(weapon)) then
		self.WeaponSwitchInProgress = false
		self.CurrentWeaponState = self.WeaponState.UNARMED
		self.CurrentWeapon = nil
		self.CurrentHoldType = "normal"

		print("Switched to unarmed state")

		return
	end

	-- Show and equip the new weapon
	self.CurrentWeapon = weapon
	weapon:SetNoDraw(false)
	self.CurrentWeaponState = self.WeaponState.ARMED
	self.CurrentHoldType = self:GetCurrentHoldType()

	-- Reattach weapon to bone (in case it got detached)
	self:AttachWeaponToBone(weapon)

	print("Switched to weapon: " .. weapon:GetClass() .. " with holdtype: " .. self.CurrentHoldType)

	self:OnWeaponEquipped(weapon)

	self.WeaponSwitchInProgress = false
end

function ENT:OnWeaponEquipped(weapon)
	-- Override this for weapon-specific equip behavior
	-- Example: Play equip sound, set attachment position, etc.

	-- Update hold type for animations
	self.CurrentHoldType = self:GetCurrentHoldType()
end

function ENT:OnWeaponHolstered(weapon)
	-- Override this for weapon-specific holster behavior
	-- Example: Play holster sound
end

function ENT:SwitchToNextWeapon()
	if (#self.WeaponInventory <= 1) then
		return false
	end

	local nextIndex = (self.CurrentWeaponIndex % #self.WeaponInventory) + 1
	return self:SwitchToWeapon(nextIndex)
end

function ENT:SwitchToPreviousWeapon()
	if (#self.WeaponInventory <= 1) then
		return false
	end

	local prevIndex = ((self.CurrentWeaponIndex - 2) % #self.WeaponInventory) + 1
	return self:SwitchToWeapon(prevIndex)
end

function ENT:SelectBestWeaponForRange(distance)
	if (#self.WeaponInventory == 0) then
		return false
	end

	-- Simple weapon selection based on distance
	-- Override this method for more sophisticated weapon selection
	local bestWeaponIndex = 1

	for i, weapon in ipairs(self.WeaponInventory) do
		if (IsValid(weapon) and self:IsWeaponSuitableForRange(weapon:GetClass(), distance)) then
			bestWeaponIndex = i
			break
		end
	end

	return self:SwitchToWeapon(bestWeaponIndex)
end

function ENT:IsWeaponSuitableForRange(weaponClass, distance)
	-- Override this method to implement weapon-specific range preferences
	-- This is a simple example

	local lowerClass = string.lower(weaponClass)

	if (string.find(lowerClass, "knife") or
			string.find(lowerClass, "crowbar") or
			string.find(lowerClass, "sword")) then
		return distance <= self.PreferredWeaponRange.melee
	end

	if (string.find(lowerClass, "shotgun")) then
		return distance <= self.PreferredWeaponRange.close
	end

	if (string.find(lowerClass, "rifle") or
			string.find(lowerClass, "sniper")) then
		return distance >= self.PreferredWeaponRange.medium
	end

	-- Default to suitable for medium range
	return distance <= self.PreferredWeaponRange.medium
end

function ENT:CanSwitchWeapons()
	return (not self.WeaponSwitchInProgress and CurTime() - self.LastWeaponSwitch >= 0.5)
end

function ENT:IsArmed()
	return (self.CurrentWeaponState == self.WeaponState.ARMED and IsValid(self.CurrentWeapon))
end

function ENT:GetWeaponState()
	return self.CurrentWeaponState
end

function ENT:RemoveAllWeapons()
	-- Remove all weapon entities
	for _, weapon in pairs(self.WeaponInventory) do
		if (IsValid(weapon)) then
			weapon:Remove()
		end
	end

	self.WeaponInventory = {}
	self.CurrentWeapon = nil
	self.CurrentWeaponState = self.WeaponState.UNARMED
	self.CurrentHoldType = "normal"
end

function ENT:DropCurrentWeapon()
	if (IsValid(self.CurrentWeapon)) then
		-- Unparent and drop the weapon
		local weapon = self.CurrentWeapon
		weapon:SetParent(nil)
		weapon:SetOwner(nil)
		weapon:SetNoDraw(false)

		-- Give it some physics impulse to "drop" it
		local phys = weapon:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:EnableMotion(true)
			phys:Wake()
			phys:AddVelocity(self:GetForward() * 100 + Vector(0, 0, 50))
		end

		-- Remove from inventory
		for i, invWeapon in ipairs(self.WeaponInventory) do
			if (invWeapon == weapon) then
				table.remove(self.WeaponInventory, i)
				break
			end
		end

		self.CurrentWeapon = nil
		self.CurrentWeaponState = self.WeaponState.UNARMED
		self.CurrentHoldType = "normal"

		-- Switch to next weapon if available
		if (#self.WeaponInventory > 0) then
			if (self.CurrentWeaponIndex > #self.WeaponInventory) then
				self.CurrentWeaponIndex = 1
			end
			self:SwitchToWeapon(self.CurrentWeaponIndex)
		end
	end
end

-- Utility function to get weapon by class name
function ENT:GetWeaponByClass(weaponClass)
	for _, weapon in pairs(self.WeaponInventory) do
		if (IsValid(weapon) and weapon:GetClass() == weaponClass) then
			return weapon
		end
	end
	return nil
end

-- Method to fire current weapon (you'll need to implement the actual firing logic)
function ENT:FireWeapon(target)
	if (not self:IsArmed()) then
		return false
	end

	-- Override this method to implement weapon-specific firing
	-- Example: self.CurrentWeapon:PrimaryAttack()
	return self:OnFireWeapon(self.CurrentWeapon, target)
end

function ENT:OnFireWeapon(weapon, target)
	-- Override this for weapon-specific firing behavior
	-- Return true if weapon was fired successfully
	return false
end
