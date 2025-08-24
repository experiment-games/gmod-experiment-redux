ENT.Type = "brush"
ENT.Base = "base_brush"

ENT.PrintName = "Resource Area Trigger"
ENT.Category = "Experiment Redux"
ENT.Spawnable = false
ENT.AdminOnly = true

if (not SERVER) then
	return
end

-- Initialize the entity
function ENT:Initialize()
	self:SetSolid(SOLID_BSP)

	-- Commented as we manually check if inside the bounds of this area upon attempting to spawn resources
	-- self:SetTrigger(true)

	-- Get keyvalues from the map
	self.resourceTypeID = self.resourceTypeID or ""
end

-- Gets the resource type ID
function ENT:GetResourceTypeID()
	return self.resourceTypeID
end

-- Handle keyvalues from the map
function ENT:KeyValue(key, value)
	key = key:lower()

	if (key == "resourcetypeid") then
		self.resourceTypeID = value
	end
end
