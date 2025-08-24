local PANEL = {}

AccessorFunc(PANEL, "backgroundColor", "BackgroundColor", FORCE_COLOR)
AccessorFunc(PANEL, "textColor", "TextColor", FORCE_COLOR)
AccessorFunc(PANEL, "text", "Text", FORCE_STRING)
AccessorFunc(PANEL, "iconMaterial", "IconMaterial")
AccessorFunc(PANEL, "iconSize", "IconSize", FORCE_NUMBER)
AccessorFunc(PANEL, "spacing", "Spacing", FORCE_NUMBER)

function PANEL:Init()
	self:SetTall(26)
	self:SetBackgroundColor(Color(50, 50, 50, 0))
	self:SetTextColor(color_white)
	self:SetText("")
	self:SetIcon("")
	self:SetIconSize(16)
	self:SetSpacing(4)
end

function PANEL:SetIcon(path)
	if (path and path ~= "") then
		self.iconPath = path
		self.iconMaterial = ix.util.GetMaterial(path)
		self.iconAspectRatio = self.iconMaterial:Width() / self.iconMaterial:Height()
	else
		self.iconPath = nil
		self.iconMaterial = nil
	end
end

function PANEL:GetIcon()
	return self.iconPath
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(self:GetBackgroundColor())
	surface.DrawRect(0, 0, w, h)

	local iconMaterial = self:GetIconMaterial()
	local text = self:GetText()
	local iconSize = self:GetIconSize()
	local spacing = self:GetSpacing()
	local xPos = 4

	-- Draw icon if specified
	if (iconMaterial) then
		surface.SetMaterial(iconMaterial)
		surface.SetDrawColor(color_white)
		surface.DrawTexturedRect(xPos, (h - iconSize) * 0.5, iconSize * self.iconAspectRatio, iconSize)
		xPos = xPos + (iconSize * self.iconAspectRatio) + spacing
	end

	-- Draw text
	if (text and text ~= "") then
		draw.SimpleTextOutlined(
			text,
			"ixSmallFont",
			xPos,
			h * 0.5,
			self:GetTextColor(),
			TEXT_ALIGN_LEFT,
			TEXT_ALIGN_CENTER,
			1,
			color_black
		)
	end
end

function PANEL:SizeToContents()
	local text = self:GetText()
	local iconSize = self:GetIconSize()
	local spacing = self:GetSpacing()
	local width = 8 -- Padding

	if (self:GetIconMaterial()) then
		width = width + (iconSize * self.iconAspectRatio) + spacing
	end

	if (text and text ~= "") then
		surface.SetFont("ixSmallFont")
		local textWidth, _ = surface.GetTextSize(text)
		width = width + textWidth
	end

	self:SetWide(width)
end

vgui.Register("expIconText", PANEL, "EditablePanel")
