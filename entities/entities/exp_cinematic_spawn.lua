if (SERVER) then
	AddCSLuaFile()
end

ENT.Type = "point"
ENT.PrintName = "Cinematic Spawn Point"
ENT.Author = "Experiment Redux"
ENT.Spawnable = false
ENT.AdminOnly = false

AccessorFunc(ENT, "expSequenceID", "SequenceID")

function ENT:Initialize()
end

function ENT:KeyValue(key, value)
	key = key:lower()

	if (key == "sequenceid") then
		self:SetSequenceID(value)
	end
end
