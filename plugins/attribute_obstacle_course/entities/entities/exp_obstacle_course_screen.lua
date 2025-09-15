local PLUGIN = PLUGIN

AddCSLuaFile()

ENT.Base = "base_anim"
ENT.PrintName = "Obstacle Course Screen"
ENT.Author = "Experiment Redux"
ENT.Spawnable = false

TEST_QUEUE_DATA = TEST_QUEUE_DATA or {}
TEST_SURVIVORS_DATA = TEST_SURVIVORS_DATA or {}

local function GET_RANDOM_NAME()
	local names = {
		"Jane Doe", "John Smith", "Alice Johnson", "Bob Brown",
		"Larry Levinson", "Marry Poppins", "Peter Pan",
		"Frodo Baggins", "Samwise Gamgee", "Gandalf the Grey",
		"Bilbo Baggins", "Aragorn, son of Arathorn", "Legolas Greenleaf",
		"Gimli, son of Glóin", "Boromir of Gondor", "Sauron the Great",
	}

	return names[math.random(1, #names)]
end

function TEST_ADD_QUEUED(count)
	TEST_QUEUE_DATA = {}
	for i = 1, count do
		table.insert(TEST_QUEUE_DATA, {
			id = "test_queue_" .. i,
			name = GET_RANDOM_NAME() .. "#" .. i,
		})
	end
	print("Added " .. count .. " queued test players")
end

function TEST_ADD_SURVIVORS(count)
	TEST_SURVIVORS_DATA = {}
	local baseTime = CurTime()

	for i = 1, count do
		if (i <= math.ceil(count * 0.3)) then
			TEST_SURVIVORS_DATA["test_active_" .. i] = {
				type = "active",
				name = GET_RANDOM_NAME() .. "#" .. i,
				startedAt = baseTime - (i * 15)
			}
		else
			table.insert(TEST_SURVIVORS_DATA, {
				type = "finished",
				name = GET_RANDOM_NAME() .. "#" .. i,
				position = i - math.ceil(count * 0.3),
				finishTime = 30 + (i * 10)
			})
		end
	end
	print("Added " .. count .. " survivor test players")
end

function TEST_CLEAR_ALL()
	TEST_QUEUE_DATA = {}
	TEST_SURVIVORS_DATA = {}
	print("Cleared all test data")
end

function ENT:SetupDataTables()
	self:NetworkVar("String", "CourseID")
	self:NetworkVar("Int", "ScreenWidth")
	self:NetworkVar("Int", "ScreenHeight")
	self:NetworkVar("Float", "ScreenScale")
end

if (SERVER) then
	function ENT:Initialize()
		self:SetSolid(SOLID_NONE)
		self:SetMoveType(MOVETYPE_NONE)
	end

	function ENT:KeyValue(key, value)
		if (key == "courseID") then
			self:SetCourseID(value)
		elseif (key == "screenWidth") then
			self:SetScreenWidth(tonumber(value) or 200)
		elseif (key == "screenHeight") then
			self:SetScreenHeight(tonumber(value) or 150)
		elseif (key == "screenScale") then
			self:SetScreenScale(tonumber(value) or 0.1)
		end
	end
else
	ENT.CameraRenderTargets = ENT.CameraRenderTargets or {}

	ENT.survivorsCurrentPage = ENT.survivorsCurrentPage or 1
	ENT.survivorsTransitionStart = ENT.survivorsTransitionStart or 0
	ENT.survivorsTransitionDuration = 0.5
	ENT.survivorsPageHoldTime = 3.0
	ENT.survivorsLastPageChange = ENT.survivorsLastPageChange or 0

	ENT.queueCurrentPage = ENT.queueCurrentPage or 1
	ENT.queueTransitionStart = ENT.queueTransitionStart or 0
	ENT.queueTransitionDuration = 0.5
	ENT.queuePageHoldTime = 3.0
	ENT.queueLastPageChange = ENT.queueLastPageChange or 0

	local gradient = Material("vgui/gradient-l")
	local function DrawGradientBox(x, y, w, h, dir, col1, col2)
		surface.SetMaterial(gradient)
		surface.SetDrawColor(col1)

		if (dir == 1) then
			surface.DrawTexturedRectRotated(x + w * .5, y + h * .5, w, h, 0)
		else
			surface.DrawTexturedRectRotated(x + w * .5, y + h * .5, h, w, 90)
		end
	end

	local function FormatTime(seconds)
		local mins = math.floor(seconds / 60)
		local secs = seconds % 60
		return string.format("%d:%02d", mins, secs)
	end

	local function EaseInOut(t)
		if (t < 0.5) then
			return 2 * t * t
		else
			return -1 + (4 - 2 * t) * t
		end
	end

	function ENT:GetCameras()
		local cameras = {}
		local courseID = self:GetCourseID()

		for _, ent in ipairs(ents.FindByClass("exp_obstacle_course_camera")) do
			if (ent:GetCourseID() == courseID) then
				table.insert(cameras, ent)
			end
		end

		return cameras
	end

	function ENT:GetCurrentCamera()
		local cameras = self:GetCameras()
		if (#cameras == 0) then return nil end

		local cycleTime = 5
		local currentTime = CurTime()
		local index = math.floor(currentTime / cycleTime) % #cameras + 1

		return cameras[index]
	end

	function ENT:GetCourseData()
		local courseID = self:GetCourseID()
		if (not courseID or courseID == "") then return nil end

		local courseData = PLUGIN.obstacleCoursesClient and PLUGIN.obstacleCoursesClient[courseID]

		if (courseData and (table.Count(TEST_QUEUE_DATA) > 0 or table.Count(TEST_SURVIVORS_DATA) > 0)) then
			courseData = table.Copy(courseData)

			if (table.Count(TEST_QUEUE_DATA) > 0) then
				courseData.waitingPlayers = courseData.waitingPlayers or {}
				for _, playerData in ipairs(TEST_QUEUE_DATA) do
					courseData.waitingPlayers[playerData.id] = { name = playerData.name }
				end
			end

			if (table.Count(TEST_SURVIVORS_DATA) > 0) then
				courseData.activePlayers = courseData.activePlayers or {}
				courseData.finishedPlayers = courseData.finishedPlayers or {}

				for id, playerData in pairs(TEST_SURVIVORS_DATA) do
					if (playerData.type == "active") then
						courseData.activePlayers[id] = {
							name = playerData.name,
							startedAt = playerData.startedAt
						}
					elseif (playerData.type == "finished") then
						table.insert(courseData.finishedPlayers, {
							name = playerData.name,
							position = playerData.position,
							finishTime = playerData.finishTime
						})
					end
				end
			end
		end

		return courseData
	end

	function ENT:DrawPlayerList(courseData, x, y, w, h)
		local headerHeight = 30
		local lineHeight = 25
		local padding = 8

		local allPlayers = {}

		local sortedFinished = {}
		for _, player in ipairs(courseData.finishedPlayers or {}) do
			table.insert(sortedFinished, player)
		end
		table.sort(sortedFinished, function(a, b) return a.position < b.position end)

		for _, clientInfo in ipairs(sortedFinished) do
			local timeStr = FormatTime(math.ceil(clientInfo.finishTime))
			table.insert(allPlayers, {
				type = "finished",
				position = "#" .. clientInfo.position,
				name = clientInfo.name,
				time = timeStr,
				bgColor = Color(0, 150, 0, 100)
			})
		end

		for _, clientInfo in pairs(courseData.activePlayers or {}) do
			local currentTime = CurTime() - clientInfo.startedAt
			local timeStr = FormatTime(math.ceil(currentTime))
			table.insert(allPlayers, {
				type = "active",
				position = "",
				name = clientInfo.name,
				time = timeStr,
				bgColor = Color(255, 165, 0, 100)
			})
		end

		local contentHeight = h - headerHeight - padding
		local maxVisibleLines = math.floor(contentHeight / (lineHeight + 2))
		local totalPages = math.ceil(#allPlayers / maxVisibleLines)

		local currentTime = CurTime()
		if (totalPages > 1) then
			if (currentTime - self.survivorsLastPageChange > self.survivorsPageHoldTime) then
				if (self.survivorsTransitionStart == 0) then
					self.survivorsTransitionStart = currentTime
				end

				if (currentTime - self.survivorsTransitionStart > self.survivorsTransitionDuration) then
					self.survivorsCurrentPage = self.survivorsCurrentPage + 1
					if (self.survivorsCurrentPage > totalPages) then
						self.survivorsCurrentPage = 1
					end
					self.survivorsLastPageChange = currentTime
					self.survivorsTransitionStart = 0
				end
			end
		else
			self.survivorsCurrentPage = 1
			self.survivorsTransitionStart = 0
		end

		surface.SetDrawColor(30, 30, 30, 200)
		surface.DrawRect(x, y, w, headerHeight)

		local headerText = "SURVIVORS"
		if (totalPages > 1) then
			headerText = headerText .. " (" .. self.survivorsCurrentPage .. "/" .. totalPages .. ")"
		end

		draw.SimpleText(
			headerText,
			"DermaDefaultBold",
			x + w * .5,
			y + headerHeight * .5,
			Color(255, 255, 255),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)

		-- Calculate transition offset for smooth scrolling
		local transitionOffset = 0
		if (self.survivorsTransitionStart > 0) then
			local transitionProgress = (currentTime - self.survivorsTransitionStart) / self.survivorsTransitionDuration
			transitionProgress = math.Clamp(transitionProgress, 0, 1)
			transitionProgress = EaseInOut(transitionProgress)
			transitionOffset = -contentHeight * transitionProgress
		end

		-- Define the drawable area bounds
		local drawAreaY = y + headerHeight + padding
		local drawAreaHeight = contentHeight
		local drawAreaBottom = drawAreaY + drawAreaHeight

		-- Helper function to draw a page of survivors with bounds checking
		local function DrawSurvivorsPage(pageNum, offsetY)
			local startIndex = (pageNum - 1) * maxVisibleLines + 1
			local endIndex = math.min(startIndex + maxVisibleLines - 1, #allPlayers)

			local yPos = drawAreaY + offsetY
			for i = startIndex, endIndex do
				if (allPlayers[i]) then
					local player = allPlayers[i]
					local itemTop = yPos
					local itemBottom = yPos + lineHeight

					-- Calculate visibility factor based on how much of the item is within bounds
					local visibilityFactor = 1
					local drawHeight = lineHeight
					local drawY = yPos

					-- Check if item is completely outside bounds
					if (itemBottom < drawAreaY or itemTop > drawAreaBottom) then
						visibilityFactor = 0
						-- Check if item is partially outside bounds
					elseif (itemTop < drawAreaY or itemBottom > drawAreaBottom) then
						-- Calculate how much of the item is visible
						local visibleTop = math.max(itemTop, drawAreaY)
						local visibleBottom = math.min(itemBottom, drawAreaBottom)
						local visibleHeight = math.max(0, visibleBottom - visibleTop)

						visibilityFactor = visibleHeight / lineHeight
						drawHeight = visibleHeight
						drawY = visibleTop
					end

					-- Only draw if there's something visible
					if (visibilityFactor > 0) then
						local alpha = math.floor(player.bgColor.a * visibilityFactor)
						local textAlpha = math.floor(255 * visibilityFactor)

						surface.SetDrawColor(player.bgColor.r, player.bgColor.g, player.bgColor.b, alpha)
						surface.DrawRect(x, drawY, w, drawHeight)

						-- Draw text with adjusted alpha, but only if visibility is reasonable
						if (visibilityFactor > 0.3) then -- Only show text if at least 30% visible
							if (player.position ~= "") then
								draw.SimpleText(player.position, "DermaDefault", x + 5, yPos + lineHeight * .5,
									Color(255, 255, 255, textAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
								draw.SimpleText(player.name, "DermaDefault", x + 35, yPos + lineHeight * .5,
									Color(255, 255, 255, textAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
							else
								draw.SimpleText(player.name, "DermaDefault", x + 5, yPos + lineHeight * .5,
									Color(255, 255, 255, textAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
							end

							draw.SimpleText(player.time, "DermaDefault", x + w - 5, yPos + lineHeight * .5,
								Color(255, 255, 255, textAlpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
						end
					end

					yPos = yPos + lineHeight + 2
				end
			end
		end

		DrawSurvivorsPage(self.survivorsCurrentPage, transitionOffset)

		if (self.survivorsTransitionStart > 0) then
			local nextPage = self.survivorsCurrentPage + 1
			if (nextPage > totalPages) then nextPage = 1 end
			DrawSurvivorsPage(nextPage, transitionOffset + contentHeight)
		end

		return y + h
	end

	function ENT:DrawQueueList(courseData, x, y, w, h)
		local headerHeight = 25
		local padding = 5
		local itemPadding = 8
		local itemSpacing = 4
		local lineHeight = 20

		local waitingPlayers = {}
		for _, clientInfo in pairs(courseData.waitingPlayers or {}) do
			table.insert(waitingPlayers, clientInfo.name)
		end

		if (#waitingPlayers == 0) then
			surface.SetDrawColor(50, 50, 50, 200)
			surface.DrawRect(x, y, w, headerHeight)
			draw.SimpleText("QUEUE", "DermaDefaultBold", x + w * .5, y + headerHeight * .5,
				Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			return
		end

		local contentHeight = h - headerHeight - padding * 2
		local availableWidth = w - padding * 2
		local maxPlayersPerLine = math.floor(availableWidth / 80)
		local maxLines = math.floor(contentHeight / (lineHeight + itemSpacing))
		local maxPlayersPerPage = maxPlayersPerLine * maxLines
		local totalPages = math.ceil(#waitingPlayers / maxPlayersPerPage)

		local currentTime = CurTime()

		if (totalPages > 1) then
			if (currentTime - self.queueLastPageChange > self.queuePageHoldTime) then
				if (self.queueTransitionStart == 0) then
					self.queueTransitionStart = currentTime
				end

				if (currentTime - self.queueTransitionStart > self.queueTransitionDuration) then
					self.queueCurrentPage = self.queueCurrentPage + 1
					if (self.queueCurrentPage > totalPages) then
						self.queueCurrentPage = 1
					end
					self.queueLastPageChange = currentTime
					self.queueTransitionStart = 0
				end
			end
		else
			self.queueCurrentPage = 1
			self.queueTransitionStart = 0
		end

		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(x, y, w, headerHeight)

		local headerText = "QUEUE"
		if (totalPages > 1) then
			headerText = headerText .. " (" .. self.queueCurrentPage .. "/" .. totalPages .. ")"
		end

		draw.SimpleText(headerText, "DermaDefaultBold", x + w * .5, y + headerHeight * .5,
			Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local transitionOffset = 0
		if (self.queueTransitionStart > 0) then
			local transitionProgress = (currentTime - self.queueTransitionStart) / self.queueTransitionDuration
			transitionProgress = math.Clamp(transitionProgress, 0, 1)
			transitionProgress = EaseInOut(transitionProgress)
			transitionOffset = -w * transitionProgress
		end

		-- Define the drawable area bounds for queue
		local drawAreaX = x
		local drawAreaY = y + headerHeight + padding
		local drawAreaWidth = w - padding * 2
		local drawAreaHeight = contentHeight
		local drawAreaRight = drawAreaX + drawAreaWidth
		local drawAreaBottom = drawAreaY + drawAreaHeight + (padding * 2) -- (this padding * 2 is just eyeballing it)

		local function DrawQueuePage(pageNum, offsetX)
			local startIndex = (pageNum - 1) * maxPlayersPerPage + 1
			local endIndex = math.min(startIndex + maxPlayersPerPage - 1, #waitingPlayers)

			local currentX = drawAreaX + offsetX
			local currentY = drawAreaY

			surface.SetFont("DermaDefault")

			for i = startIndex, endIndex do
				local name = waitingPlayers[i]
				if (not name) then break end

				local textWidth, textHeight = surface.GetTextSize(name)
				local boxWidth = textWidth + itemPadding * 2
				local boxHeight = lineHeight

				if (currentX + boxWidth > drawAreaRight + offsetX and currentX > drawAreaX + offsetX) then
					currentX = drawAreaX + offsetX
					currentY = currentY + boxHeight + itemSpacing
				end

				local itemLeft = currentX
				local itemRight = currentX + boxWidth
				local itemTop = currentY
				local itemBottom = currentY + boxHeight

				-- Calculate visibility factors for both X and Y axes
				local xVisibility = 1
				local yVisibility = 1
				local drawWidth = boxWidth
				local drawHeight = boxHeight
				local drawX = currentX
				local drawY = currentY

				-- Check X bounds (horizontal transition)
				if (itemRight < drawAreaX or itemLeft > drawAreaRight) then
					xVisibility = 0
				elseif (itemLeft < drawAreaX or itemRight > drawAreaRight) then
					local visibleLeft = math.max(itemLeft, drawAreaX)
					local visibleRight = math.min(itemRight, drawAreaRight)
					local visibleWidth = math.max(0, visibleRight - visibleLeft)
					xVisibility = visibleWidth / boxWidth
					drawWidth = visibleWidth
					drawX = visibleLeft
				end

				-- Check Y bounds (vertical overflow)
				if (itemBottom < drawAreaY or itemTop > drawAreaBottom) then
					yVisibility = 0
				elseif (itemTop < drawAreaY or itemBottom > drawAreaBottom) then
					local visibleTop = math.max(itemTop, drawAreaY)
					local visibleBottom = math.min(itemBottom, drawAreaBottom)
					local visibleHeight = math.max(0, visibleBottom - visibleTop)
					yVisibility = visibleHeight / boxHeight
					drawHeight = visibleHeight
					drawY = visibleTop
				end

				local totalVisibility = xVisibility * yVisibility

				-- Only draw if there's something visible
				if (totalVisibility > 0) then
					local alpha = math.floor(80 * totalVisibility) -- Base alpha of 80
					local textAlpha = math.floor(200 * totalVisibility) -- Base alpha of 200

					-- Draw background with adjusted alpha and size
					surface.SetDrawColor(100, 100, 100, alpha)
					surface.DrawRect(drawX, drawY, drawWidth, drawHeight)

					-- Only draw text if visibility is reasonable and within original item bounds
					if (totalVisibility > 0.4 and drawY >= currentY and drawY + drawHeight <= currentY + boxHeight) then
						local textX = math.max(drawX, currentX + itemPadding)
						local textY = currentY + boxHeight * .5

						-- Make sure text position is within drawable area
						if (textX < drawAreaRight and textY >= drawAreaY and textY <= drawAreaBottom) then
							draw.SimpleText(name, "DermaDefault", textX, textY,
								Color(200, 200, 200, textAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
						end
					end
				end

				currentX = currentX + boxWidth + itemSpacing
			end
		end

		DrawQueuePage(self.queueCurrentPage, transitionOffset)

		if (self.queueTransitionStart > 0) then
			local nextPage = self.queueCurrentPage + 1
			if (nextPage > totalPages) then nextPage = 1 end
			DrawQueuePage(nextPage, transitionOffset + w)
		end
	end

	ENT.CameraRenderTargets = ENT.CameraRenderTargets or {}

	function ENT:UpdateCameraRenderTarget()
		local camera = self:GetCurrentCamera()
		if (not camera) then return end

		local rtName = "obstacle_camera_" .. camera:EntIndex()
		local screenWidth = self:GetScreenWidth()
		local screenHeight = self:GetScreenHeight()

		local leftWidth = screenWidth * 0.4
		local rightWidth = screenWidth - leftWidth - 30
		local rightHeight = screenHeight - 60

		local rt = GetRenderTarget(rtName, rightWidth, rightHeight)
		if (not rt) then return end

		self.CameraRenderTargets[camera:EntIndex()] = {
			renderTarget = rt,
			lastUpdate = CurTime(),
			camera = camera
		}

		if (not self.lastCameraUpdate or (CurTime() - self.lastCameraUpdate) > (1 / 30)) then
			local oldRT = render.GetRenderTarget()
			render.SetRenderTarget(rt)
			render.Clear(0, 0, 0, 255, true, true)

			local cameraPos = camera:GetPos()
			local cameraAngles = camera:GetViewAngles()
			local fov = camera:GetFOV()

			render.RenderView({
				origin = cameraPos,
				angles = cameraAngles,
				x = 0,
				y = 0,
				w = rightWidth,
				h = rightHeight,
				fov = fov,
				aspectratio = rightWidth / rightHeight,
				znear = 1,
				zfar = 16384,
				drawviewmodel = false
			})

			render.SetRenderTarget(oldRT)
			self.lastCameraUpdate = CurTime()
		end
	end

	function ENT:GetOrCreateCameraMaterial(renderTarget)
		local matName = "exp_obstacle_course_camera_" .. renderTarget:GetName()
		local material = Material("!" .. matName)

		if (not material:IsError()) then
			return material
		end

		material = CreateMaterial(matName, "UnlitGeneric", {
			["$basetexture"] = renderTarget:GetName(),
		})

		return material
	end

	function ENT:DrawCameraView(x, y, w, h)
		local camera = self:GetCurrentCamera()
		if (not camera) then
			surface.SetDrawColor(50, 50, 50, 200)
			surface.DrawRect(x, y, w, h)

			draw.SimpleText("NO CAMERAS", "DermaDefaultBold", x + w * .5, y + h * .5,
				Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			return
		end

		surface.SetDrawColor(20, 20, 20, 220)
		surface.DrawRect(x, y, w, h)

		local cameraData = self.CameraRenderTargets[camera:EntIndex()]
		if (cameraData and cameraData.renderTarget) then
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(self:GetOrCreateCameraMaterial(cameraData.renderTarget))
			surface.DrawTexturedRect(x, y, w, h)
		else
			draw.SimpleText("LOADING CAMERA...", "DermaDefault", x + w * .5, y + h * .5,
				Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local cameraName = camera:GetCameraName()
		if (cameraName and cameraName ~= "") then
			local textWidth, textHeight = Schema.GetCachedTextSize("DermaDefault", "CAM: " .. cameraName)

			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(x + 5, y + 5, textWidth + 10, textHeight + 10)

			draw.SimpleText("CAM: " .. cameraName, "DermaDefault", x + 10, y + 15,
				Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local liveText = "● LIVE"
		local liveColor = Color(255, 50, 50)
		local textWidth, textHeight = Schema.GetCachedTextSize("DermaDefault", liveText)

		local pulse = math.sin(CurTime() * 3) * 0.3 + 0.7
		liveColor.a = 255 * pulse

		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(x + w - textWidth - 15, y + h - textHeight - 5, textWidth + 10, textHeight + 10)

		draw.SimpleText(liveText, "DermaDefault", x + w - 10, y + h - 5,
			liveColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)

		local borderColor = Color(255, 0, 0, 100 * pulse)
		surface.SetDrawColor(borderColor)
		surface.DrawOutlinedRect(x, y, w, h, 2)
	end

	function ENT:Initialize()
		local screenWidth = self:GetScreenWidth()
		local screenHeight = self:GetScreenHeight()
		local scale = self:GetScreenScale()

		local worldWidth = screenWidth * scale
		local worldHeight = screenHeight * scale

		-- Set rendering bounds so screen keeps rendering when entity is outside PVS
		local mins = Vector(-worldWidth / 2, -worldHeight / 2, -10)
		local maxs = Vector(worldWidth / 2, worldHeight / 2, 10)

		self:SetRenderBounds(mins, maxs)

		self.survivorsCurrentPage = 1
		self.survivorsTransitionStart = 0
		self.survivorsLastPageChange = CurTime()

		self.queueCurrentPage = 1
		self.queueTransitionStart = 0
		self.queueLastPageChange = CurTime()
	end

	function ENT:Think()
		self:UpdateCameraRenderTarget()
	end

	function ENT:Draw()
		local courseID = self:GetCourseID()
		if (not courseID or courseID == "") then return end

		local courseData = self:GetCourseData()
		if (not courseData) then return end

		local pos = self:GetPos()
		local ang = self:GetAngles()
		local originalForward = ang:Forward()

		ang:RotateAroundAxis(ang:Up(), 90)
		ang:RotateAroundAxis(ang:Forward(), 90)

		local screenWidth = self:GetScreenWidth()
		local screenHeight = self:GetScreenHeight()
		local scale = self:GetScreenScale()

		pos = pos - (ang:Forward() * screenWidth * .5 * scale)
		pos = pos - (ang:Right() * screenHeight * .5 * scale)

		pos = pos + (originalForward * 0.5)

		cam.Start3D2D(pos, ang, scale)

		surface.SetDrawColor(15, 15, 15, 240)
		surface.DrawRect(0, 0, screenWidth, screenHeight)

		surface.SetDrawColor(60, 60, 60, 255)
		surface.DrawOutlinedRect(0, 0, screenWidth, screenHeight, 2)

		local titleHeight = 40
		local course = courseID:gsub("_", " "):upper()
		DrawGradientBox(0, 0, screenWidth, titleHeight, 1, Color(40, 40, 40, 200), Color(20, 20, 20, 200))
		draw.SimpleText(course, "DermaLarge", screenWidth * .5, 5 + titleHeight * .5,
			Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local leftWidth = screenWidth * 0.5
		local leftX = 10
		local listY = titleHeight + 10

		local survivorsHeight = screenHeight * 0.5
		self:DrawPlayerList(courseData, leftX, listY, leftWidth, survivorsHeight)

		local queueY = listY + survivorsHeight + 5
		local queueHeight = screenHeight - queueY - 20
		self:DrawQueueList(courseData, leftX, queueY, leftWidth, queueHeight)

		local rightX = leftX + leftWidth + 10
		local rightWidth = screenWidth - rightX - 10
		local rightHeight = screenHeight - titleHeight - 20

		self:DrawCameraView(rightX, listY, rightWidth, rightHeight)

		cam.End3D2D()
	end
end
