if SERVER then
	AddCSLuaFile()
end

ENT.Type = "anim"
ENT.PrintName = "Spawn Point"
ENT.Author = "Experiment Redux"
ENT.Category = "Experiment Redux"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.IsSpawnPoint = true

if (not SERVER) then
	return
end

function ENT:Initialize()
	Schema.spawnPoints.AddMapSpawn({
		name = self.expName,
		position = self:GetPos(),
		angles = self:GetAngles(),
		shouldNotSave = true,     -- The map will always dictate where this spawn point is
		status = self.expStatus or nil, -- Let the map decide the status of this spawn point
	})

	-- This entity only exists temporarily for mappers to mark a spawn point
	self:Remove()
end

function ENT:KeyValue(key, value)
	if (key == "name") then
		self.expName = value
	elseif (key == "status") then
		self.expStatus = tonumber(value)
		self.expStatus = self.expStatus > -1 and self.expStatus or nil
	end
end
