ENT.Type = "brush"
ENT.Base = "base_brush"

ENT.PrintName = "Area Trigger"
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
	self.areaID = self.areaID or ""
	self.areaName = self.areaName or ""
end

-- Called when an entity starts touching the trigger
function ENT:StartTouch(ent)
	if (not IsValid(ent) or not ent:IsPlayer()) then
		return
	end

	hook.Run("PlayerEnteredArea", ent, self.areaID, self.areaName, self)

	if (GetConVar("developer"):GetInt() > 0) then
		print("[Area] Player ", ent, " entered area ", self.areaID, self.areaName)
	end
end

-- Called when an entity stops touching the trigger
function ENT:EndTouch(ent)
	if (not IsValid(ent) or not ent:IsPlayer()) then
		return
	end

	hook.Run("PlayerExitedArea", ent, self.areaID, self.areaName, self)

	if (GetConVar("developer"):GetInt() > 0) then
		print("[Area] Player ", ent, " exited area ", self.areaID, self.areaName)
	end
end

-- Handle keyvalues from the map
function ENT:KeyValue(key, value)
	key = key:lower()

	if (key == "areaid") then
		self.areaID = value
	elseif (key == "areaname") then
		self.areaName = value
	end
end
