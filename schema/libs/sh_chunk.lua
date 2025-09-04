--[[
	Chunk-based infinite world system using the existing instance framework.
	Players are moved between chunk instances and teleported when hitting chunk edges.
	Neighboring chunks are rendered with proper positioning for seamless world illusion.
]]

local CHUNK_SIZE_X = 2048
local CHUNK_SIZE_Y = 2048
local BOUNDARY_MARGIN = 0.001 -- Small margin to prevent infinite loops

-- Utility library for chunk management
Schema.chunk = ix.util.GetOrCreateLibrary("chunk", {
	chunkSize = { x = CHUNK_SIZE_X, y = CHUNK_SIZE_Y },
	boundaryMargin = BOUNDARY_MARGIN,
})

--[[
	Shared Functions
--]]

--- Generates a chunk instance ID from chunk coordinates
--- @param chunkX number
--- @param chunkY number
--- @return string
function Schema.chunk.GetChunkInstanceID(chunkX, chunkY)
	return string.format("chunk_%d_%d", chunkX, chunkY)
end

--- Gets the chunk coordinates for a player
--- @param client Player
--- @return table|nil { x = number, y = number }
function Schema.chunk.GetPlayerChunk(client)
	if (not IsValid(client)) then
		return nil
	end

	return client.chunk or { x = 0, y = 0 }
end

--- Sets the chunk coordinates for a player
--- @param client Player
--- @param chunkX number
--- @param chunkY number
function Schema.chunk.SetPlayerChunk(client, chunkX, chunkY)
	if (not IsValid(client)) then
		return
	end

	client.chunk = { x = chunkX, y = chunkY }
end

--- Gets neighboring chunk coordinates around a given chunk
--- @param chunkX number
--- @param chunkY number
--- @return table Array of { x = number, y = number }
function Schema.chunk.GetNeighboringChunks(chunkX, chunkY)
	local neighbors = {}

	for dx = -1, 1 do
		for dy = -1, 1 do
			if dx ~= 0 or dy ~= 0 then -- Exclude the center chunk
				table.insert(neighbors, { x = chunkX + dx, y = chunkY + dy })
			end
		end
	end

	return neighbors
end

--- Gets the world position offset for a chunk relative to origin chunk
--- @param chunkX number
--- @param chunkY number
--- @return Vector
function Schema.chunk.GetChunkWorldOffset(chunkX, chunkY)
	return Vector(chunkX * CHUNK_SIZE_X, chunkY * CHUNK_SIZE_Y, 0)
end

--- Checks if a position is near a chunk boundary
--- @param pos Vector
--- @param margin number Optional margin (defaults to BOUNDARY_MARGIN)
--- @return boolean, number, number Returns whether near boundary and which boundaries (offsetX, offsetY)
function Schema.chunk.IsNearChunkBoundary(pos, margin)
	margin = margin or BOUNDARY_MARGIN

	local halfSizeX = CHUNK_SIZE_X / 2
	local halfSizeY = CHUNK_SIZE_Y / 2

	local offsetX = 0
	local offsetY = 0
	local nearBoundary = false

	-- Check X boundaries
	if pos.x >= halfSizeX - margin then
		offsetX = 1
		nearBoundary = true
	elseif pos.x <= -halfSizeX + margin then
		offsetX = -1
		nearBoundary = true
	end

	-- Check Y boundaries
	if pos.y >= halfSizeY - margin then
		offsetY = 1
		nearBoundary = true
	elseif pos.y <= -halfSizeY + margin then
		offsetY = -1
		nearBoundary = true
	end

	return nearBoundary, offsetX, offsetY
end

if SERVER then
	--[[
		Server Functions
	--]]

	--- Moves a player to a specific chunk
	--- @param client Player
	--- @param chunkX number
	--- @param chunkY number
	--- @param teleportPos? Vector Optional position to teleport to
	--- @param moveData? CMoveData Optional movement data to position the player
	function Schema.chunk.MovePlayerToChunk(client, chunkX, chunkY, teleportPos, moveData)
		if (not IsValid(client)) then
			return
		end

		local oldChunk = Schema.chunk.GetPlayerChunk(client)
		local newInstanceID = Schema.chunk.GetChunkInstanceID(chunkX, chunkY)

		-- Update player's chunk data
		Schema.chunk.SetPlayerChunk(client, chunkX, chunkY)

		-- Create the chunk instance if it doesn't exist (no owner for shared instances)
		Schema.instance.CreateInstance(newInstanceID, nil)

		-- Move player to the new instance
		Schema.instance.AddPlayer(client, newInstanceID)

		-- Teleport player if position is provided
		if (teleportPos) then
			if (moveData) then
				moveData:SetOrigin(teleportPos)
			else
				client:SetPos(teleportPos)
			end
		end

		-- Network the chunk change
		client:SetNWInt("ChunkX", chunkX)
		client:SetNWInt("ChunkY", chunkY)

		hook.Run("PlayerChangedChunk", client, chunkX, chunkY, oldChunk.x, oldChunk.y)

		print(string.format("Player %s moved to chunk (%d, %d)", client:Name(), chunkX, chunkY))
	end

	--- Initializes a player in the default chunk (0, 0)
	--- @param client Player
	function Schema.chunk.InitializePlayer(client)
		if (not IsValid(client)) then
			return
		end

		-- Initialize player in chunk (0, 0)
		timer.Simple(0.1, function()
			if (IsValid(client)) then
				Schema.chunk.MovePlayerToChunk(client, 0, 0)
			end
		end)
	end

	--- Gets the teleport position when crossing a chunk edge
	--- @param currentPos Vector
	--- @param offsetX number
	--- @param offsetY number
	--- @return Vector
	function Schema.chunk.GetTeleportPosition(currentPos, offsetX, offsetY)
		local newPos = Vector(currentPos.x, currentPos.y, currentPos.z)

		-- Calculate half sizes (since origin is at center)
		local halfSizeX = CHUNK_SIZE_X / 2
		local halfSizeY = CHUNK_SIZE_Y / 2

		-- Calculate teleport position (opposite side of the map with margin)
		if (offsetX > 0) then
			-- Moving to +X chunk, teleport to -X side with margin
			newPos.x = -halfSizeX + BOUNDARY_MARGIN
		elseif (offsetX < 0) then
			-- Moving to -X chunk, teleport to +X side with margin
			newPos.x = halfSizeX - BOUNDARY_MARGIN
		end

		if (offsetY > 0) then
			-- Moving to +Y chunk, teleport to -Y side with margin
			newPos.y = -halfSizeY + BOUNDARY_MARGIN
		elseif (offsetY < 0) then
			-- Moving to -Y chunk, teleport to +Y side with margin
			newPos.y = halfSizeY - BOUNDARY_MARGIN
		end

		return newPos
	end

	--- Checks if a player should be moved to a different chunk and handles the transition
	--- @param client Player
	--- @param moveData? CMoveData Optional movement data to position the player
	function Schema.chunk.CheckPlayerChunkTransition(client, moveData)
		if (not IsValid(client) or not client.chunk) then
			return
		end

		local pos = client:GetPos()
		local nearBoundary, offsetX, offsetY = Schema.chunk.IsNearChunkBoundary(pos)

		if (nearBoundary) then
			local currentChunk = Schema.chunk.GetPlayerChunk(client)

			-- Calculate new chunk coordinates
			local newChunkX = currentChunk.x + offsetX
			local newChunkY = currentChunk.y + offsetY

			-- Calculate teleport position
			local teleportPos = Schema.chunk.GetTeleportPosition(pos, offsetX, offsetY)

			-- Move player to new chunk
			Schema.chunk.MovePlayerToChunk(client, newChunkX, newChunkY, teleportPos, moveData)
		end
	end

	--[[
		Server Hooks
	--]]

	-- Initialize players when they spawn
	hook.Add("PlayerSpawn", "ChunkSystemPlayerSpawn", function(client)
		if (not client.chunk) then
			Schema.chunk.InitializePlayer(client)
		end
	end)

	-- Monitor player positions for chunk transitions
	hook.Add("PlayerTick", "ChunkSystemPlayerTick", function(client, moveData)
		if (not IsValid(client) or not client:Alive()) then
			return
		end

		Schema.chunk.CheckPlayerChunkTransition(client, moveData)
	end)
else
	--[[
		Client Functions
	--]]

	--- Gets a player's chunk from networked data
	--- @param client Player
	--- @return table { x = number, y = number }
	function Schema.chunk.GetPlayerChunkNetworked(client)
		if (not IsValid(client)) then
			return { x = 0, y = 0 }
		end

		return {
			x = client:GetNWInt("ChunkX", 0),
			y = client:GetNWInt("ChunkY", 0)
		}
	end

	--- Checks if a player is in a neighboring chunk
	--- @param viewerChunk table { x = number, y = number }
	--- @param targetChunk table { x = number, y = number }
	--- @return boolean
	function Schema.chunk.IsNeighboringChunk(viewerChunk, targetChunk)
		local dx = math.abs(viewerChunk.x - targetChunk.x)
		local dy = math.abs(viewerChunk.y - targetChunk.y)

		-- Check if it's a direct neighbor (including diagonals)
		return dx <= 1 and dy <= 1 and not (dx == 0 and dy == 0)
	end

	--- Calculates the render position for a player in a neighboring chunk
	--- @param localPlayerChunk table { x = number, y = number }
	--- @param targetPlayerChunk table { x = number, y = number }
	--- @param targetPlayer Player
	--- @return Vector|nil
	function Schema.chunk.GetNeighborRenderPosition(localPlayerChunk, targetPlayerChunk, targetPlayer)
		if (not IsValid(targetPlayer)) then
			return nil
		end

		local dx = targetPlayerChunk.x - localPlayerChunk.x
		local dy = targetPlayerChunk.y - localPlayerChunk.y

		local offset = Vector(dx * CHUNK_SIZE_X, dy * CHUNK_SIZE_Y, 0)

		local targetPos = targetPlayer:GetPos()
		local renderPos = targetPos + offset

		return renderPos
	end

	--[[
		Client Hooks
	--]]

	-- Handle rendering players from neighboring chunks
	hook.Add("ShouldHideEntityDueToInstance", "ChunkSystemNeighborRendering", function(localPlayer, entity, shouldHide)
		if (not IsValid(localPlayer) or not IsValid(entity)) then
			return nil
		end

		-- Only handle players in different instances
		if (not entity:IsPlayer() or not shouldHide) then
			return nil
		end

		local localChunk = Schema.chunk.GetPlayerChunkNetworked(localPlayer)
		local targetChunk = Schema.chunk.GetPlayerChunkNetworked(entity)

		-- Check if the target player is in a neighboring chunk
		if (Schema.chunk.IsNeighboringChunk(localChunk, targetChunk)) then
			-- Don't hide players in neighboring chunks.
			-- Instead, we'll render them with a position offset.
			local renderPos = Schema.chunk.GetNeighborRenderPosition(localChunk, targetChunk, entity)

			if (renderPos) then
				entity:SetRenderOrigin(renderPos)
				return false -- Don't hide the entity
			end
		end
	end)

	-- Clean up render origins when entities are removed or chunks change
	hook.Add("EntityRemoved", "ChunkSystemRenderCleanup", function(entity)
		if (IsValid(entity) and entity:IsPlayer()) then
			entity:SetRenderOrigin(nil)
		end
	end)
end

--[[
	Commands for Testing
--]]

do
	local COMMAND = {}

	COMMAND.description = "Get your current chunk coordinates."
	COMMAND.arguments = {}

	function COMMAND:OnRun(client)
		local chunk = Schema.chunk.GetPlayerChunk(client)
		client:Notify(string.format("You are in chunk (%d, %d)", chunk.x, chunk.y))
	end

	ix.command.Add("ChunkGetCoords", COMMAND)
end

if SERVER then
	do
		local COMMAND = {}

		COMMAND.description = "Move a player to a specific chunk."
		COMMAND.arguments = {
			ix.type.player,
			ix.type.number,
			ix.type.number
		}
		COMMAND.superAdminOnly = true

		function COMMAND:OnRun(client, target, chunkX, chunkY)
			if (not IsValid(target)) then
				client:Notify("Invalid player.")
				return
			end

			Schema.chunk.MovePlayerToChunk(target, chunkX, chunkY)
			client:Notify(string.format("Moved %s to chunk (%d, %d)", target:Name(), chunkX, chunkY))
		end

		ix.command.Add("ChunkMoveTo", COMMAND)
	end
end
