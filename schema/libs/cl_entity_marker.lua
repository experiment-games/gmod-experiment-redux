Schema.entityMarker = ix.util.GetOrCreateLibrary("entityMarker", {
	markers = {},

	POINTER_TRIANGLE_SIZE = math.max(20, ScreenScale(10)),
	POINTER_DISTANCE_FROM_EDGE = math.max(20, ScreenScale(5)),
	HALO_BLUR = 2,
	HALO_SIZE = 2,
	HALO_PASSES = 5
})

local function WorldToScreenReliable(worldPos)
	local camPos = EyePos()
	local camAng = EyeAngles()

	-- Transform world position to camera-relative coordinates
	local relativePos = WorldToLocal(worldPos, Angle(0, 0, 0), camPos, camAng)

	-- Check if behind camera
	local isBehind = relativePos.x < 0

	-- Get screen dimensions
	local scrW, scrH = ScrW(), ScrH()
	local centerX, centerY = scrW * 0.5, scrH * 0.5

	-- Calculate FOV (field of view) scaling
	local fov = math.rad(LocalPlayer():GetFOV())
	local aspectRatio = scrW / scrH

	-- Project to screen coordinates
	local screenX, screenY

	if (math.abs(relativePos.x) > 0.001) then -- Avoid division by zero
		-- Fixed projection math
		local fovScale = math.tan(fov * 0.5)
		screenX = centerX - (relativePos.y / relativePos.x) * centerX / fovScale
		screenY = centerY - (relativePos.z / relativePos.x) * centerY / (fovScale / aspectRatio)
	else
		-- Entity is very close to camera plane, use fallback
		screenX = centerX
		screenY = centerY
	end

	return { x = screenX, y = screenY }, isBehind
end

local function ClampToScreen(x, y, margin)
	local w, h = ScrW(), ScrH()
	return math.Clamp(x, margin, w - margin), math.Clamp(y, margin, h - margin)
end

local function GetEntityScreenInfo(entity)
	local pos = entity:LocalToWorld(entity:OBBCenter())
	local screenPos, isBehind = WorldToScreenReliable(pos)

	-- Calculate direction from screen center to entity position
	local centerX, centerY = ScrW() * 0.5, ScrH() * 0.5
	local dx = screenPos.x - centerX
	local dy = screenPos.y - centerY

	-- For behind camera entities, we need to flip the direction
	if (isBehind) then
		dx = -dx
		dy = -dy
	end

	local dir = Vector(dx, dy, 0):GetNormalized()

	return screenPos, isBehind, dir
end

local function DrawPointer(color, direction)
	if (not direction) then
		return
	end

	local w, h = ScrW(), ScrH()
	local edgeDist = Schema.entityMarker.POINTER_DISTANCE_FROM_EDGE
	local triangleSize = Schema.entityMarker.POINTER_TRIANGLE_SIZE

	local centerX, centerY = w * 0.5, h * 0.5
	local dx, dy = direction.x, direction.y

	-- Calculate angle for the pointer direction
	local angle = math.atan2(dy, dx)
	local cosA = math.cos(angle)
	local sinA = math.sin(angle)

	-- Find intersection with screen edge
	local maxDistX = math.huge
	local maxDistY = math.huge

	if (math.abs(cosA) > 0.001) then
		maxDistX = (centerX - edgeDist) / math.abs(cosA)
	end

	if (math.abs(sinA) > 0.001) then
		maxDistY = (centerY - edgeDist) / math.abs(sinA)
	end

	local maxDist = math.min(maxDistX, maxDistY)

	local x = centerX + cosA * maxDist
	local y = centerY + sinA * maxDist

	-- Ensure pointer stays within screen bounds
	x, y = ClampToScreen(x, y, edgeDist)

	local triangleSize = math.max(triangleSize, 20)

	-- Calculate triangle points
	local tipX, tipY = x, y
	local baseX = x - cosA * triangleSize
	local baseY = y - sinA * triangleSize

	-- Perpendicular for triangle width
	local perpX = -sinA * (triangleSize * 0.5)
	local perpY = cosA * (triangleSize * 0.5)

	local leftX = baseX + perpX
	local leftY = baseY + perpY
	local rightX = baseX - perpX
	local rightY = baseY - perpY

	local thickness = 2

	-- Draw triangle using lines
	surface.SetDrawColor(color)

	for i = 1, thickness do
		local offset = i - 1
		-- Tip to left
		surface.DrawLine(tipX + offset, tipY, leftX + offset, leftY)
		surface.DrawLine(tipX, tipY + offset, leftX, leftY + offset)
		-- Left to right
		surface.DrawLine(leftX + offset, leftY, rightX + offset, rightY)
		surface.DrawLine(leftX, leftY + offset, rightX, rightY + offset)
		-- Right to tip
		surface.DrawLine(rightX + offset, rightY, tipX + offset, tipY)
		surface.DrawLine(rightX, rightY + offset, tipX, tipY + offset)
	end
end

--- Mark an entity with highlighting and pointing
--- @param entityOrIndex Entity|number Entity or EntIndex to mark
--- @param color? Color Color of the highlight (default is yellow)
--- @return boolean # True if the entity was successfully marked
function Schema.entityMarker.Mark(entityOrIndex, color)
	if (isentity(entityOrIndex)) then
		entityOrIndex = entityOrIndex:EntIndex()
	end

	Schema.entityMarker.markers[entityOrIndex] = {
		entity = entityOrIndex,
		color = color or Color(255, 255, 0)
	}

	return true
end

--- Remove marking from an entity
--- @param entityOrIndex Entity|number Entity or EntIndex to unmark
--- @return boolean # True if the entity was successfully unmarked
function Schema.entityMarker.Unmark(entityOrIndex)
	if (isentity(entityOrIndex)) then
		entityOrIndex = entityOrIndex:EntIndex()
	end

	Schema.entityMarker.markers[entityOrIndex] = nil

	return true
end

--- Clear all markers
function Schema.entityMarker.ClearAll()
	Schema.entityMarker.markers = {}
end

--- Get all marked entities
--- @return table<number, { entity: number, color: Color }>
function Schema.entityMarker.GetMarkers()
	return Schema.entityMarker.markers
end

--- Get all marked entities that are currently valid (in PVS)
--- @return Entity[]
function Schema.entityMarker.GetMarkedEntities()
	local markedEntities = {}

	for _, markerData in pairs(Schema.entityMarker.markers) do
		if (IsValid(Entity(markerData.entity))) then
			table.insert(markedEntities, Entity(markerData.entity))
		end
	end

	return markedEntities
end

--- Check if entity is marked
--- @param entity Entity Entity to check
--- @return boolean # True if the entity is marked, false otherwise
function Schema.entityMarker.IsMarked(entity)
	if (not IsValid(entity)) then
		return false
	end

	return Schema.entityMarker.markers[entity:EntIndex()] ~= nil
end

--[[
	Hooks
--]]

-- Unmark entities being removed
hook.Add("EntityRemoved", "expEtityMarkerEntityRemoved", function(entity)
	if (not IsValid(entity)) then
		return
	end

	Schema.entityMarker.Unmark(entity)
end)

-- Hook for drawing halos around marked entities
hook.Add("PreDrawHalos", "expEntityMarkerPreDrawHalos", function()
	for entIndex, markerData in pairs(Schema.entityMarker.markers) do
		local entity = Entity(entIndex)

		if (IsValid(entity)) then
			halo.Add(
				{ entity },
				markerData.color,
				Schema.entityMarker.HALO_BLUR,
				Schema.entityMarker.HALO_SIZE,
				Schema.entityMarker.HALO_PASSES,
				true,
				false
			)
		else
			-- Clean up invalid entities
			Schema.entityMarker.markers[entIndex] = nil
		end
	end
end)

-- Hook for drawing directional pointers
hook.Add("HUDPaint", "expEntityMarkerHUDPaint", function()
	for entIndex, markerData in pairs(Schema.entityMarker.markers) do
		local entity = Entity(entIndex)

		if (IsValid(entity)) then
			local screenPos, isBehind, direction = GetEntityScreenInfo(entity)

			-- Only draw pointer if entity is off-screen or behind camera
			local w, h = ScrW(), ScrH()
			local margin = 50 -- Add some margin to consider "off-screen"
			local isOffScreen = screenPos.x < margin or screenPos.x > (w - margin) or
				screenPos.y < margin or screenPos.y > (h - margin)

			if (isOffScreen or isBehind) then
				DrawPointer(markerData.color, direction)
			end
		end
	end
end)

--[[
	Network Messages
--]]

net.Receive("expEntityMarkerForce", function(len, client)
	local entityIndex = net.ReadUInt(MAX_EDICT_BITS)

	Schema.entityMarker.Mark(entityIndex)
end)
