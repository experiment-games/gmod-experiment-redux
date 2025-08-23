local PANEL = {}

local ICON_SIZE = 16
local ICON_SIZE_HALF = ICON_SIZE * .5
local ICON_SIZE_PADDING = 8
local ICON_SIZE_PADDING_DOUBLE = ICON_SIZE_PADDING * 2

function PANEL:Init()
	if (IsValid(ix.gui.spawnSelection)) then
		ix.gui.spawnSelection:Remove()
	end

	local scrW = ScrW()
	local scrH = ScrH()

	self:SetPos(0, 0)
	self:SetSize(scrW, scrH)
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)
	self:ParentToHUD()

	self.mapDetails = Schema.spawnPoints.GetMapDetails()

	self:MakePopup()

	ix.gui.spawnSelection = self
end

function PANEL:GetSpawns()
	return self.spawns
end

function PANEL:SetSpawns(spawns)
	self.spawns = spawns
	self:Rebuild()
end

function PANEL:GetMapMaterial()
	return self.mapDetails.backgroundMaterial
end

function PANEL:Rebuild()
	if (not self.spawns) then return end

	self:Clear()
	self:SetLoading(false)

	local scrW = ScrW()
	local scrH = ScrH()

	self:SetSize(scrW, scrH)

	local mapHeight = scrH * .9
	local mapScale = mapHeight / self.mapDetails.backgroundOriginalHeight
	local mapWidth = self.mapDetails.backgroundOriginalWidth * mapScale
	local mapRotation = self.mapDetails.backgroundRotation or 0

	self.mapBackground = self:Add("EditablePanel")
	self.mapBackground:SetSize(mapWidth, mapHeight)
	self.mapBackground:SetPos((scrW * .5) - (mapWidth * .5), scrH - mapHeight)
	self.mapBackground.Paint = function(panel, w, h)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(self:GetMapMaterial())

		if (mapRotation == 0) then
			surface.DrawTexturedRect(0, 0, w, h)
		else
			local centerX = w * .5
			local centerY = h * .5

			surface.DrawTexturedRectRotated(centerX, centerY, w, h, -mapRotation)
		end
	end

	self.infoLabel = self:Add("DLabel")
	self.infoLabel:SetText("Spawn Selection")
	self.infoLabel:SetFont("ixBigFont")
	self.infoLabel:SetTextColor(ix.config.Get("color"))
	self.infoLabel:SizeToContents()
	self.infoLabel:SetPos(
		(scrW * .5) - (self.infoLabel:GetWide() * .5),
		scrH * .1
	)

	self.spawnLocationPanels = {}

	for spawnKey, spawn in pairs(self.spawns) do
		local index = #self.spawnLocationPanels + 1
		local spawnIcon = self.mapBackground:Add("DButton")
		self.spawnLocationPanels[index] = spawnIcon
		local status, icon, color

		if (spawn.status == Schema.spawnPoints.spawnStatus.SAFE) then
			icon = Material("icon16/flag_green.png")
			color = Color(150, 255, 150, 255)
			status = "It should be safe to spawn here."
		elseif (spawn.status == Schema.spawnPoints.spawnStatus.CHAOS) then
			icon = Material("icon16/flag_orange.png")
			color = Color(226, 120, 49, 255)
			status = "Its chaos. You can spawn here but be careful for hostile denizens."
		else
			icon = Material("icon16/flag_red.png")
			color = Color(255, 150, 150, 255)
			status = "This location is unsafe, you cannot spawn here."

			if (spawn.unsafeUntil) then
				status = status .. "\n\nThis location will become safe in at most "
					.. string.NiceTime(spawn.unsafeUntil - CurTime()) .. "."
			end
		end

		local x, y = 0, 0

		if (self.mapDetails.TransformSpawnPositionToUI) then
			x, y = self.mapDetails:TransformSpawnPositionToUI(spawn.position, mapWidth, mapHeight)
		end

		-- Rotate x and y around the center of the map
		local centerX = mapWidth * .5
		local centerY = mapHeight * .5

		local xRotated = math.cos(math.rad(mapRotation)) * (x - centerX) -
			math.sin(math.rad(mapRotation)) * (y - centerY) + centerX
		local yRotated = math.sin(math.rad(mapRotation)) * (x - centerX) +
			math.cos(math.rad(mapRotation)) * (y - centerY) + centerY

		x = xRotated
		y = yRotated

		spawnIcon:SetText("")
		spawnIcon:SetPos(x - ICON_SIZE_HALF, y - ICON_SIZE_HALF)
		spawnIcon:SetSize(ICON_SIZE + ICON_SIZE_PADDING_DOUBLE, ICON_SIZE + ICON_SIZE_PADDING_DOUBLE)
		spawnIcon:SetHelixTooltip(function(tooltip)
			local name = tooltip:AddRow("name")
			name:SetImportant()
			name:SetText(spawn.name)
			name:SetBackgroundColor(color)
			name:SizeToContents()

			local description = tooltip:AddRow("description")
			description:SetText(status)
			description:SizeToContents()
		end)

		spawnIcon.Paint = function(panel, w, h)
			local pulse = math.sin(CurTime()) * .1 + 1
			local radius = (w * .5) * pulse
			surface.SetDrawColor(color)
			draw.NoTexture()
			Schema.draw.DrawCircle(w * .5, h * .5, radius, 5)

			surface.SetDrawColor(color_white)
			surface.SetMaterial(icon)
			surface.DrawTexturedRect(ICON_SIZE_PADDING, ICON_SIZE_PADDING, ICON_SIZE, ICON_SIZE)
		end

		spawnIcon.DoClick = function(button)
			self:SetLoading(true)

			net.Start("expSpawnRequestSelect")
			net.WriteUInt(spawnKey, 8)
			net.SendToServer()
		end
	end
end

function PANEL:SetLoading(loading)

end

function PANEL:Paint(w, h)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, w, h)
end

vgui.Register("expSpawnSelection", PANEL, "EditablePanel")

if (IsValid(ix.gui.spawnSelection)) then
	local spawns = ix.gui.spawnSelection:GetSpawns()
	ix.gui.spawnSelection = vgui.Create("expSpawnSelection")
	ix.gui.spawnSelection:SetSpawns(spawns)
end
