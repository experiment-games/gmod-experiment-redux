local PANEL = {}

AccessorFunc(PANEL, "drawValueText", "DrawValueText", FORCE_BOOL)

function PANEL:Init()
	self:SetTall(26)
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)
	self.value = 0
	self.maxValue = 0
	self.prefix = "Value: "
	self:SetDrawValueText(true)

	-- Default color thresholds
	self.progressColors = {
		{ threshold = 0.25, color = derma.GetColor("Error", self) },
		{ threshold = 0.5,  color = derma.GetColor("Warning", self) },
		{ threshold = 1.0,  color = derma.GetColor("Info", self) }
	}
end

function PANEL:SetValue(value)
	self.value = value
end

function PANEL:SetMaxValue(maxValue)
	self.maxValue = maxValue
end

function PANEL:GetValue()
	if (isfunction(self.value)) then
		return self.value()
	end

	return self.value
end

function PANEL:SetPrefix(prefix)
	self.prefix = prefix or "Value: "
end

--- Example colorTable: {{threshold = 0.3, color = Color(255, 0, 0)}, {threshold = 0.7, color = Color(255, 255, 0)}, {threshold = 1.0, color = Color(0, 255, 0)}}
--- @param colorTable table should be a table of {threshold = number, color = Color}
function PANEL:SetProgressColors(colorTable)
	-- Sort by threshold to ensure proper color selection
	table.sort(colorTable, function(a, b)
		return a.threshold < b.threshold
	end)

	self.progressColors = colorTable
end

function PANEL:GetColorForValue()
	local valueFraction = self:GetValue() / self.maxValue

	-- Find the appropriate color based on the current value fraction
	for i, colorData in ipairs(self.progressColors) do
		if (valueFraction <= colorData.threshold) then
			return colorData.color
		end
	end

	-- Fallback to the last color if no threshold matches
	return self.progressColors[#self.progressColors].color
end

function PANEL:GetText()
	local value = self:GetValue()
	local maxValue = self.maxValue
	local prefix = self.prefix

	return prefix .. value .. " / " .. maxValue
end

function PANEL:Paint(w, h)
	local value = self:GetValue()
	local maxValue = self.maxValue
	local prefix = self.prefix
	local valueFraction = value / maxValue
	local valueColor = self:GetColorForValue()

	surface.SetDrawColor(ColorAlpha(valueColor, 50))
	surface.DrawRect(0, 0, w * valueFraction, h)

	if (valueFraction == 0) then
		local pulse = math.abs(math.sin(RealTime() * 2) * 50)
		surface.SetDrawColor(valueColor.r, valueColor.g, valueColor.b, pulse)
		surface.DrawRect(0, 0, w, h)
	end

	if (not self:GetDrawValueText()) then
		return
	end

	draw.SimpleTextOutlined(
		self:GetText(),
		"ixSmallFont",
		4,
		h * .5,
		color_white,
		TEXT_ALIGN_LEFT,
		TEXT_ALIGN_CENTER,
		1,
		color_black
	)
end

function PANEL:SizeToContents()
	surface.SetFont("ixSmallFont")
	local textWidth, textHeight = surface.GetTextSize(self:GetText())
	self:SetWide(textWidth + 8)
	self:SetTall(textHeight + 8)
end

vgui.Register("expProgressBar", PANEL, "EditablePanel")
