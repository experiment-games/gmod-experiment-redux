local PLUGIN = PLUGIN

if (SERVER) then
	AddCSLuaFile()
end

ENT.Type = "anim"
ENT.PrintName = "Experiment Monitor (Static)"
ENT.Author = "Experiment Redux"
ENT.Category = "Experiment Redux"

-- This entity is replaced at map startup with the real monitor entity, based on the monitorPreset keyvalue
-- It can not be physgunned or moved
ENT.Spawnable = false
ENT.AdminOnly = false

if (not SERVER) then
	return
end

function ENT:Initialize()
	local preset = PLUGIN.presets[self.monitorPreset]

	PLUGIN:SetupParentEntity(self, preset)
	self:SetSolid(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)

	-- We do not draw this parent, since it only communicates the angles of a static prop with the real monitor parent
	self:SetNoDraw(true)

	for _, monitor in ipairs(preset.monitors) do
		local monitorEntity = PLUGIN:SpawnMonitor(self, monitor)

		if (self.specialID) then
			monitorEntity:SetSpecialID(self.specialID)
		end
	end
end

function ENT:KeyValue(key, value)
	key = key:lower()

	if (key == "monitorpreset") then
		self.monitorPreset = value
	elseif (key == "specialid") then
		self.specialID = value
	end
end
