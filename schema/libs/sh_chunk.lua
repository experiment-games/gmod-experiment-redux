--[[
	Chunk-based infinite world system using the existing instance framework.
	Players are moved between chunk instances and teleported when hitting chunk edges.
	Neighboring chunks are rendered with proper positioning for seamless world illusion.
]]

local CHUNK_SIZE_X = 2048
local CHUNK_SIZE_Y = 2048
local BOUNDARY_MARGIN = 0.001     -- Small margin to prevent infinite loops
local PVS_BOUNDARY_DISTANCE = 512 -- Distance from boundary to start adding PVS origins

-- Utility library for chunk management
Schema.chunk = ix.util.GetOrCreateLibrary("chunk", {
	chunkSize = { x = CHUNK_SIZE_X, y = CHUNK_SIZE_Y },
	boundaryMargin = BOUNDARY_MARGIN,
	pvsBoundaryDistance = PVS_BOUNDARY_DISTANCE,
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
	--- Checks if a position is near a chunk boundary for PVS purposes
	--- @param pos Vector
	--- @param distance number Distance from boundary to check
	--- @return boolean, table Returns whether near boundary and which boundaries { x = number, y = number }
	function Schema.chunk.IsNearChunkBoundaryForPVS(pos, distance)
		distance = distance or PVS_BOUNDARY_DISTANCE

		local halfSizeX = CHUNK_SIZE_X / 2
		local halfSizeY = CHUNK_SIZE_Y / 2

		local boundaries = {}
		local nearBoundary = false

		-- Check X boundaries
		if pos.x >= halfSizeX - distance then
			table.insert(boundaries, { x = 1, y = 0 })
			nearBoundary = true
		end
		if pos.x <= -halfSizeX + distance then
			table.insert(boundaries, { x = -1, y = 0 })
			nearBoundary = true
		end

		-- Check Y boundaries
		if pos.y >= halfSizeY - distance then
			table.insert(boundaries, { x = 0, y = 1 })
			nearBoundary = true
		end
		if pos.y <= -halfSizeY + distance then
			table.insert(boundaries, { x = 0, y = -1 })
			nearBoundary = true
		end

		-- Check diagonal boundaries (corners)
		if pos.x >= halfSizeX - distance and pos.y >= halfSizeY - distance then
			table.insert(boundaries, { x = 1, y = 1 })
			nearBoundary = true
		end
		if pos.x <= -halfSizeX + distance and pos.y >= halfSizeY - distance then
			table.insert(boundaries, { x = -1, y = 1 })
			nearBoundary = true
		end
		if pos.x >= halfSizeX - distance and pos.y <= -halfSizeY + distance then
			table.insert(boundaries, { x = 1, y = -1 })
			nearBoundary = true
		end
		if pos.x <= -halfSizeX + distance and pos.y <= -halfSizeY + distance then
			table.insert(boundaries, { x = -1, y = -1 })
			nearBoundary = true
		end

		return nearBoundary, boundaries
	end

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

	--- Calculates PVS origins for neighboring chunks that the player is near
	--- @param client Player
	--- @return table Array of Vector positions to add to PVS
	function Schema.chunk.GetPVSOriginsForPlayer(client)
		if (not IsValid(client) or not client.chunk) then
			return {}
		end

		local pos = client:GetPos()
		local currentChunk = Schema.chunk.GetPlayerChunk(client)
		local nearBoundary, boundaries = Schema.chunk.IsNearChunkBoundaryForPVS(pos, PVS_BOUNDARY_DISTANCE)

		local pvsOrigins = {}

		if (nearBoundary) then
			for _, boundary in ipairs(boundaries) do
				-- Calculate the neighboring chunk coordinates
				local neighborChunkX = currentChunk.x + boundary.x
				local neighborChunkY = currentChunk.y + boundary.y

				-- Calculate the world offset for this neighboring chunk
				local chunkOffset = Schema.chunk.GetChunkWorldOffset(neighborChunkX, neighborChunkY)

				-- Calculate a position in the neighboring chunk that would be good for PVS
				-- We want a position that's on the boundary but in the neighboring chunk
				local pvsPos = Vector(pos.x, pos.y, pos.z)

				-- Adjust position to be in the neighboring chunk
				if (boundary.x ~= 0) then
					local halfSizeX = CHUNK_SIZE_X / 2
					if (boundary.x > 0) then
						pvsPos.x = -halfSizeX + PVS_BOUNDARY_DISTANCE
					else
						pvsPos.x = halfSizeX - PVS_BOUNDARY_DISTANCE
					end
				end

				if (boundary.y ~= 0) then
					local halfSizeY = CHUNK_SIZE_Y / 2
					if (boundary.y > 0) then
						pvsPos.y = -halfSizeY + PVS_BOUNDARY_DISTANCE
					else
						pvsPos.y = halfSizeY - PVS_BOUNDARY_DISTANCE
					end
				end

				-- Add the chunk offset to get the actual world position
				pvsPos = pvsPos + chunkOffset

				table.insert(pvsOrigins, pvsPos)
			end
		end

		return pvsOrigins
	end

	-- Store original positions for cross-chunk combat calculations
	Schema.chunk.playerOriginalPositions = Schema.chunk.playerOriginalPositions or {}

	--- Gets the effective position of a player for combat calculations
	--- This considers their position from the perspective of another player's chunk
	--- @param targetPlayer Player The player whose position we want
	--- @param viewerPlayer Player The player viewing/attacking
	--- @return Vector The effective position for combat
	function Schema.chunk.GetPlayerEffectivePosition(targetPlayer, viewerPlayer)
		if (not IsValid(targetPlayer) or not IsValid(viewerPlayer)) then
			return targetPlayer:GetPos()
		end

		local viewerChunk = Schema.chunk.GetPlayerChunk(viewerPlayer)
		local targetChunk = Schema.chunk.GetPlayerChunk(targetPlayer)

		-- If in same chunk, return normal position
		if (viewerChunk.x == targetChunk.x and viewerChunk.y == targetChunk.y) then
			return targetPlayer:GetPos()
		end

		-- If not neighboring chunks, return normal position (shouldn't hit anyway due to instance system)
		if (not Schema.chunk.IsNeighboringChunk(viewerChunk, targetChunk)) then
			return targetPlayer:GetPos()
		end

		-- Calculate the offset position as seen from viewer's chunk
		local dx = targetChunk.x - viewerChunk.x
		local dy = targetChunk.y - viewerChunk.y
		local offset = Vector(dx * CHUNK_SIZE_X, dy * CHUNK_SIZE_Y, 0)

		return targetPlayer:GetPos() + offset
	end

	--- Custom trace function for cross-chunk combat
	--- @param start Vector
	--- @param endPos Vector
	--- @param filter table|function
	--- @param mask number
	--- @param attacker Player
	--- @return table Trace result
	function Schema.chunk.TraceCrossChunk(start, endPos, filter, mask, attacker)
		-- First do a normal trace
		local tr = util.TraceLine({
			start = start,
			endpos = endPos,
			filter = filter,
			mask = mask
		})

		if (not IsValid(attacker) or not attacker:IsPlayer()) then
			return tr
		end

		-- If we hit something or don't have a valid attacker, return the trace
		if (tr.Hit and IsValid(tr.Entity)) then
			return tr
		end

		-- Check for cross-chunk hits on players
		local attackerChunk = Schema.chunk.GetPlayerChunk(attacker)
		local nearbyPlayers = {}

		-- Get players in neighboring chunks
		for _, client in ipairs(player.GetAll()) do
			if (client == attacker) then continue end

			local clientChunk = Schema.chunk.GetPlayerChunk(client)
			if (Schema.chunk.IsNeighboringChunk(attackerChunk, clientChunk)) then
				table.insert(nearbyPlayers, client)
			end
		end

		-- Check intersection with effective positions of cross-chunk players
		for _, targetPlayer in ipairs(nearbyPlayers) do
			local effectivePos = Schema.chunk.GetPlayerEffectivePosition(targetPlayer, attacker)
			local mins, maxs = targetPlayer:GetCollisionBounds()

			-- Simple box intersection check
			local hitPos = util.IntersectRayWithOBB(start, endPos - start, effectivePos, targetPlayer:GetAngles(), mins,
				maxs)
			if (hitPos) then
				-- Create a custom trace result
				local customTr = {
					Hit = true,
					Entity = targetPlayer,
					HitPos = hitPos,
					Normal = (start - hitPos):GetNormalized(),
					Fraction = start:Distance(hitPos) / start:Distance(endPos),
					StartPos = start,
					EndPos = endPos
				}
				return customTr
			end
		end

		return tr
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

	-- Add PVS origins for neighboring chunks when player is near boundaries
	hook.Add("SetupPlayerVisibility", "ChunkSystemPVS", function(client, viewEntity)
		if (not IsValid(client)) then
			return
		end

		local pvsOrigins = Schema.chunk.GetPVSOriginsForPlayer(client)

		for _, origin in ipairs(pvsOrigins) do
			AddOriginToPVS(origin)
		end
	end)

	-- Allow damage in between neighboring chunks
	hook.Add("ShouldInstanceBlockEntityDamage", "ChunkSystemAllowCrossChunkDamage",
		function(attacker, target, attackerInstance, targetInstance)
			if (not IsValid(attacker) or not IsValid(target)) then
				return
			end

			if (not attacker:IsPlayer() or not target:IsPlayer()) then
				return
			end

			local attackerChunk = Schema.chunk.GetPlayerChunk(attacker)
			local targetChunk = Schema.chunk.GetPlayerChunk(target)

			-- Allow damage if in neighboring chunks
			if (Schema.chunk.IsNeighboringChunk(attackerChunk, targetChunk)) then
				return false
			end
		end)

	-- Hook into weapon firing to use custom trace
	hook.Add("EntityFireBullets", "ChunkSystemCrossBorder", function(entity, data)
		if (not IsValid(entity) or not entity:IsPlayer()) then
			return
		end

		-- Store original callback
		local originalCallback = data.Callback

		-- Create new callback that handles cross-chunk hits
		-- TODO: This idea fails, because this is only called if we hit something (not the skybox or water)
		data.Callback = function(attacker, tr, dmgInfo)
			-- If we have an original callback, call it first
			if (originalCallback) then
				local result = originalCallback(attacker, tr, dmgInfo)
				if (result) then return result end
			end

			-- If the trace didn't hit anything, try cross-chunk trace
			if (not tr.Hit or not IsValid(tr.Entity)) then
				local customTr = Schema.chunk.TraceCrossChunk(
					tr.StartPos,
					tr.StartPos + data.Dir * (data.Distance or 8192),
					data.Filter,
					data.Mask or MASK_SHOT,
					attacker
				)

				if (customTr.Hit and IsValid(customTr.Entity) and customTr.Entity:IsPlayer()) then
					-- Apply damage manually since the trace system won't handle this
					local damage = DamageInfo()
					damage:SetDamage(dmgInfo:GetDamage())
					damage:SetAttacker(attacker)
					damage:SetInflictor(dmgInfo:GetInflictor())
					damage:SetDamageType(dmgInfo:GetDamageType())
					damage:SetDamagePosition(customTr.HitPos)
					damage:SetDamageForce(data.Dir * dmgInfo:GetDamage() * 100)

					customTr.Entity:TakeDamageInfo(damage)

					-- Create blood effect at hit position
					local effectData = EffectData()
					effectData:SetOrigin(customTr.HitPos)
					effectData:SetNormal(customTr.Normal)
					util.Effect("BloodImpact", effectData)

					return { damage = true, effects = true }
				end
			end
		end

		return data
	end)
else
	-- Table to store entities that need custom rendering with their render positions
	Schema.chunk.customRenderEntities = Schema.chunk.customRenderEntities or {}

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
	hook.Add("ShouldInstanceHideEntity", "ChunkSystemNeighborRendering", function(localPlayer, entity, shouldHide)
		if (not IsValid(localPlayer) or not IsValid(entity)) then
			return
		end

		local function restore()
			-- Restore original render mode and color if modified
			if (entity.expOldRenderMode) then
				entity:SetRenderMode(entity.expOldRenderMode)
				entity.expOldRenderMode = nil
			end

			if (entity.expOldColor) then
				entity:SetColor(entity.expOldColor)
				entity.expOldColor = nil
			end

			-- Remove from custom render table if it was there
			Schema.chunk.customRenderEntities[entity] = nil
		end

		-- Only handle players in different instances
		if (not entity:IsPlayer() or not shouldHide) then
			-- Remove from custom render table if it was there
			if (Schema.chunk.customRenderEntities[entity]) then
				restore()
			end

			return
		end

		local localChunk = Schema.chunk.GetPlayerChunkNetworked(localPlayer)
		local targetChunk = Schema.chunk.GetPlayerChunkNetworked(entity)

		-- Check if the target player is in a neighboring chunk
		if (Schema.chunk.IsNeighboringChunk(localChunk, targetChunk)) then
			-- Calculate the render position
			local renderPos = Schema.chunk.GetNeighborRenderPosition(localChunk, targetChunk, entity)

			if (renderPos) then
				-- Add to custom render table instead of trying to use SetRenderOrigin
				Schema.chunk.customRenderEntities[entity] = renderPos

				-- In order to preserve animations that are active, we cannot use SetNoDraw here since it would hang on the last known animation.
				entity.expOldRenderMode = entity.expOldRenderMode or entity:GetRenderMode()
				entity.expOldColor = entity.expOldColor or entity:GetColor()
				entity:SetRenderMode(RENDERMODE_TRANSALPHA)
				entity:SetColor(Color(255, 255, 255, 0))
				return false
			end
		else
			restore()
		end
	end)

	-- Custom rendering hook for entities with custom positions
	hook.Add("PostDrawOpaqueRenderables", "ChunkSystemCustomRender", function()
		for entity, renderPos in pairs(Schema.chunk.customRenderEntities) do
			if (not IsValid(entity)) then
				Schema.chunk.customRenderEntities[entity] = nil
				continue
			end

			-- Store original position
			local originalPos = entity:GetPos()
			local originalAngles = entity:GetAngles()

			-- Set render position
			entity:SetPos(renderPos)

			-- Draw the entity manually
			entity:DrawModel()

			-- Restore original position
			entity:SetPos(originalPos)
		end
	end)

	-- Also handle transparent renderables (for any transparent parts of player models)
	hook.Add("PostDrawTranslucentRenderables", "ChunkSystemCustomRenderTranslucent", function()
		for entity, renderPos in pairs(Schema.chunk.customRenderEntities) do
			if (not IsValid(entity)) then
				Schema.chunk.customRenderEntities[entity] = nil
				continue
			end

			-- Store original position
			local originalPos = entity:GetPos()
			local originalAngles = entity:GetAngles()

			-- Set render position
			entity:SetPos(renderPos)

			-- Draw translucent parts
			entity:DrawModel()

			-- Restore original position
			entity:SetPos(originalPos)
		end
	end)

	-- Clean up custom render table when entities are removed or chunks change
	hook.Add("EntityRemoved", "ChunkSystemCustomRenderCleanup", function(entity)
		if (Schema.chunk.customRenderEntities[entity]) then
			Schema.chunk.customRenderEntities[entity] = nil
		end
	end)

	-- Clean up when local player's chunk changes
	hook.Add("PlayerChangedChunk", "ChunkSystemCustomRenderChunkChange", function(client)
		local localPlayer = LocalPlayer()
		if (client == localPlayer) then
			-- Clear all custom render entities when our chunk changes
			-- They'll be re-evaluated in the next ShouldInstanceHideEntity call
			table.Empty(Schema.chunk.customRenderEntities)
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

	do
		local COMMAND = {}

		COMMAND.description = "Debug PVS origins for the current player."
		COMMAND.arguments = {}
		COMMAND.superAdminOnly = true

		function COMMAND:OnRun(client)
			local pvsOrigins = Schema.chunk.GetPVSOriginsForPlayer(client)
			local pos = client:GetPos()
			local chunk = Schema.chunk.GetPlayerChunk(client)

			client:Notify(string.format("Player position: %.1f, %.1f, %.1f", pos.x, pos.y, pos.z))
			client:Notify(string.format("Current chunk: (%d, %d)", chunk.x, chunk.y))
			client:Notify(string.format("PVS origins count: %d", #pvsOrigins))

			for i, origin in ipairs(pvsOrigins) do
				client:Notify(string.format("PVS Origin %d: %.1f, %.1f, %.1f", i, origin.x, origin.y, origin.z))
			end
		end

		ix.command.Add("ChunkDebugPVS", COMMAND)
	end
end
