local META = FindMetaTable("Entity")

if (SERVER) then
	util.AddNetworkString("expPlayerBodyGroupChanged")
	util.AddNetworkString("expPlayerBodyGroupsChanged")
	util.AddNetworkString("expLongRangeInteraction") -- TODO: Remove after resolving NebulousCloud/helix#483
	util.AddNetworkString("expRemoveDecals")

	META.expSetBodygroup = META.expSetBodygroup or META.SetBodygroup
	META.expSetBodyGroups = META.expSetBodyGroups or META.SetBodyGroups
	META.expSetParent = META.expSetParent or META.SetParent

	--- Call a hook when we set the parent
	--- @param parent Entity
	function META:SetParent(parent)
		hook.Run("EntitySetParent", self, parent)

		self:expSetParent(parent)
	end

	--- @param index number
	--- @param value number
	function META:SetBodygroup(index, value)
		if (self:IsPlayer()) then
			local oldValue = self:GetBodygroup(index)
			hook.Run("PlayerBodyGroupChanged", self, index, value, oldValue)

			net.Start("expPlayerBodyGroupChanged")
			net.WriteEntity(self)
			net.WriteUInt(index, 32)
			net.WriteUInt(value, 32)
			net.WriteUInt(oldValue, 32)
			net.Broadcast()
		end

		self:expSetBodygroup(index, value)
	end

	--- @param index number
	--- @param value number
	function META:SetBodyGroup(index, value)
		self:SetBodygroup(index, value)
	end

	--- @param bodygroups string # Body groups to set. Each character in the string represents a separate bodygroup. (0 to 9, a to z being (10 to 35))
	function META:SetBodyGroups(bodygroups)
		if (self:IsPlayer()) then
			local oldBodygroups = ""

			for i = 1, 9 do
				local bodygroup = self:GetBodygroup(i)
				oldBodygroups = oldBodygroups .. bodygroup
			end

			hook.Run("PlayerBodyGroupsChanged", self, bodygroups, oldBodygroups)

			net.Start("expPlayerBodyGroupsChanged")
			net.WriteEntity(self)
			net.WriteString(bodygroups)
			net.WriteString(oldBodygroups)
			net.Broadcast()
		end

		self:expSetBodyGroups(bodygroups)
	end

	function META:RemoveAllClientDecals()
		net.Start("expRemoveDecals")
		net.WriteEntity(self)
		net.Broadcast()
	end

	function META:RemoveWithEffect()
		Schema.ImpactEffect(self:GetPos(), 8, true)
		self:Remove()
	end

	function META:CreateServerRagdoll()
		local entity = ents.Create("prop_ragdoll")
		entity:SetPos(self:GetPos())
		entity:SetAngles(self:EyeAngles())
		entity:SetModel(self:GetModel())
		entity:SetSkin(self:GetSkin())

		for i = 0, (self:GetNumBodyGroups() - 1) do
			entity:SetBodygroup(i, self:GetBodygroup(i))
		end

		entity:Spawn()

		entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		entity:Activate()

		local modelScale = self:GetModelScale()
		local modelScaleVector = Vector(modelScale, modelScale, modelScale)

		for i = 0, entity:GetBoneCount() do
			entity:ManipulateBoneScale(i, modelScaleVector)
		end

		local velocity = self:GetVelocity() * modelScale

		for i = 0, entity:GetPhysicsObjectCount() - 1 do
			local physObj = entity:GetPhysicsObjectNum(i)

			if (IsValid(physObj)) then
				physObj:SetVelocity(velocity)

				local index = entity:TranslatePhysBoneToBone(i)

				if (index) then
					local position, angles = self:GetBonePosition(index)

					physObj:SetPos(position)
					physObj:SetAngles(angles)
				end
			end
		end

		return entity
	end

	function META:OpenDoorAwayFrom(position, notSilent, noLockCheck)
		local target = ents.Create("info_target")
		target:SetName(tostring(target))
		target:SetPos(position)
		target:Spawn()

		if (not noLockCheck and self:GetInternalVariable("m_bLocked")) then
			if (notSilent) then
				self:Fire("SetAnimation", "locked", 0)
				self:EmitSound("doors/door_locked2.wav", 75, math.random(95, 105))
			end
		elseif (self:GetInternalVariable("m_eDoorState") == 0) then
			if (notSilent) then
				self:Fire("SetAnimation", "open", 0)
			end
			self:Fire("OpenAwayFrom", tostring(target))
		else
			self:Fire("Close")
		end

		timer.Simple(1, function()
			if (IsValid(target)) then
				target:Remove()
			end
		end)
	end

	--[[
		Net Messages
	--]]

	-- TODO: Remove after resolving NebulousCloud/helix#483
	net.Receive("expLongRangeInteraction", function(len, client)
		local entity = net.ReadEntity()
		local option = net.ReadString()
		local data = net.ReadType()

		if (not IsValid(entity) or not entity.OnOptionSelected) then
			return
		end

		-- Ensure the entity is within range
		local maxRange = 192 ^ 2

		if (entity:GetPos():Distance(client:GetPos()) > maxRange) then
			return
		end

		entity:OnOptionSelected(client, option, data)
	end)
else
	--- TODO: Remove after resolving NebulousCloud/helix#483
	--- Send long range interaction
	--- @param option string
	--- @param data any
	function META:SendLongRangeInteraction(option, data)
		if (not IsValid(self)) then
			return
		end

		net.Start("expLongRangeInteraction")
		net.WriteEntity(self)
		net.WriteString(option)
		net.WriteType(data)
		net.SendToServer()
	end

	--[[
		Net Messages
	--]]

	net.Receive("expPlayerBodyGroupChanged", function()
		local player = net.ReadEntity()
		local index = net.ReadUInt(32)
		local value = net.ReadUInt(32)
		local oldValue = net.ReadUInt(32)

		hook.Run("PlayerBodyGroupChanged", player, index, value, oldValue)
	end)

	net.Receive("expPlayerBodyGroupsChanged", function()
		local player = net.ReadEntity()
		local bodygroups = net.ReadString()
		local oldBodygroups = net.ReadString()

		hook.Run("PlayerBodyGroupsChanged", player, bodygroups, oldBodygroups)
	end)

	net.Receive("expRemoveDecals", function()
		local entity = net.ReadEntity()

		if (IsValid(entity)) then
			entity:RemoveAllDecals()
		end
	end)
end

-- Override the default IsDoor logic to not include entities that are not doors. We call a hook to check.
function META:IsDoor()
	local class = self:GetClass()
	local pluginIsDoor = hook.Run("EntityIsDoor", self)

	if (pluginIsDoor == true) then
		return true
	end

	local baseIsDoor = (class and class:find("door") ~= nil)

	if (not baseIsDoor) then
		return false
	end

	return pluginIsDoor ~= false
end
