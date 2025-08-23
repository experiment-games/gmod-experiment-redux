ENT.Type = "brush"
ENT.Base = "base_brush"

ENT.PrintName = "Non-Entity Area"
ENT.Category = "Experiment Redux"
ENT.Spawnable = false
ENT.AdminOnly = true

if (not SERVER) then
	return
end

-- Initialize the entity
function ENT:Initialize()
	self:SetSolid(SOLID_BSP)

	-- Set up the trigger
	self:SetTrigger(true)

	-- Get keyvalues from the map
	self.expTeleportTarget = self.expTeleportTarget or ""

	-- Create a list of entity types to remove/teleport
	self.RemovableEntities = {
		"ix_item",

		-- Experiment Redux specific entities
		"exp_*",

		-- Weapons and items
		"weapon_*",
		"item_*",

		-- Props and physics objects
		"prop_physics",
		"prop_physics_multiplayer",

		-- Ragdolls (corpses)
		"prop_ragdoll",
	}
end

-- Function to check if an entity matches our removal criteria
function ENT:ShouldRemoveEntity(ent)
	local class = ent:GetClass()

	-- Check against our list of removable entity patterns
	for _, pattern in ipairs(self.RemovableEntities) do
		if (string.match(class, string.gsub(pattern, "%*", ".*"))) then
			-- Don't remove players
			if (ent:IsPlayer()) then
				return false
			end

			-- Don't remove vehicles with players in them
			if (ent:IsVehicle() and IsValid(ent:GetDriver())) then
				return false
			end

			-- Don't remove the trigger itself or other map entities
			if (ent:MapCreationID() ~= -1 and not ent:IsWeapon()) then
				return false
			end

			return true
		end
	end

	-- Special cases for ragdolls (corpses)
	if (class == "prop_ragdoll") then
		return true
	end

	-- Check if it's a dropped weapon or item
	if (ent:IsWeapon() and not IsValid(ent:GetOwner())) then
		return true
	end

	return false
end

-- Function to find teleport destination
function ENT:GetTeleportDestination()
	if (self.expTeleportTarget == "") then
		return nil
	end

	-- Find the target entity
	local target = ents.FindByName(self.expTeleportTarget)[1]

	if (not IsValid(target)) then
		-- Try finding by class name
		target = ents.FindByClass(self.expTeleportTarget)[1]
	end

	return target
end

-- Called when an entity starts touching the trigger
function ENT:StartTouch(ent)
	-- Don't remove map entities
	if (not IsValid(ent) or ent:MapCreationID() > -1) then
		return
	end

	-- Check if this entity should be removed/teleported
	if (self:ShouldRemoveEntity(ent)) then
		local teleportDest = self:GetTeleportDestination()

		if (IsValid(teleportDest)) then
			-- Teleport the entity
			self:TeleportEntity(ent, teleportDest)
		else
			-- Remove the entity after a small delay to avoid issues
			timer.Simple(0, function()
				if (IsValid(ent)) then
					self:RemoveEntity(ent)
				end
			end)
		end
	end
end

-- Function to teleport an entity to the target destination
function ENT:TeleportEntity(ent, destination)
	if (not IsValid(ent) or not IsValid(destination)) then
		return
	end

	local destPos = destination:GetPos()
	local destAng = destination:GetAngles()

	-- Create teleport effect at origin
	self:CreateTeleportEffect(ent:GetPos(), destPos)

	-- Handle different entity types
	if (ent:IsPlayer()) then
		ent:SetPos(destPos)
		ent:SetAngles(destAng)
		ent:SetVelocity(Vector(0, 0, 0))
	elseif (ent:GetPhysicsObject():IsValid()) then
		local phys = ent:GetPhysicsObject()
		phys:SetPos(destPos)
		phys:SetAngles(destAng)
		phys:SetVelocity(Vector(0, 0, 0))
	else
		ent:SetPos(destPos)
		ent:SetAngles(destAng)
	end

	if (GetConVar("developer"):GetInt() > 0) then
		print("[NonEntityArea] Teleported " .. ent:GetClass() .. " to " .. self.expTeleportTarget)
	end
end

-- Function to remove an entity safely
function ENT:RemoveEntity(entity)
	self:CreateRemovalEffect(entity:GetPos())

	-- Special handling for different entity types
	if (entity:IsPlayer()) then
		-- Don't remove players, just teleport them out if possible
		local teleportDest = self:GetTeleportDestination()

		if (IsValid(teleportDest)) then
			self:TeleportEntity(entity, teleportDest)
		end

		return
	end

	if (GetConVar("developer"):GetInt() > 0) then
		print("[NonEntityArea] Removed " .. entity:GetClass() .. " from area ", self)
	end

	hook.Run("OnNonEntityAreaRemoval", entity)

	entity:Remove()
end

-- Create visual effect for teleportation
function ENT:CreateTeleportEffect(startPos, endPos)
	local effectdata = EffectData()
	effectdata:SetStart(startPos)
	effectdata:SetOrigin(endPos)
	effectdata:SetScale(1)
	util.Effect("teleport_splash", effectdata)
end

-- Create visual effect for removal
function ENT:CreateRemovalEffect(pos)
	local effectdata = EffectData()
	effectdata:SetOrigin(pos)
	effectdata:SetScale(0.5)
	util.Effect("cball_explode", effectdata)
end

-- Handle keyvalues from the map
function ENT:KeyValue(key, value)
	key = key:lower()

	if (key == "teleporttarget") then
		self.expTeleportTarget = value
	end
end
