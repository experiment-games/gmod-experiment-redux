ENT.Type = "brush"
ENT.Base = "base_brush"

ENT.PrintName = "Chunk Edge"
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
	self.offsetX = self.offsetX or 0
	self.offsetY = self.offsetY or 0

	print("Chunk edge initialized with offsets:", self.offsetX, self.offsetY)
end

-- Called when an entity starts touching the trigger
function ENT:StartTouch(ent)
	print("Touched chunk edge", ent)
	if (not IsValid(ent) or not ent:IsPlayer()) then
		return
	end

	local client = ent
	local currentChunk = Schema.chunk.GetPlayerChunk(client)

	-- Calculate new chunk coordinates
	local newChunkX = currentChunk.x + self.offsetX
	local newChunkY = currentChunk.y + self.offsetY

	-- Calculate teleport position
	local teleportPos = Schema.chunk.GetTeleportPosition(client:GetPos(), self.offsetX, self.offsetY)

	-- Move player to new chunk
	Schema.chunk.MovePlayerToChunk(client, newChunkX, newChunkY, teleportPos)
end

-- Handle keyvalues from the map
function ENT:KeyValue(key, value)
	key = key:lower()

	if (key == "chunkx") then
		self.offsetX = tonumber(value) or 0
	elseif (key == "chunky") then
		self.offsetY = tonumber(value) or 0
	end
end
