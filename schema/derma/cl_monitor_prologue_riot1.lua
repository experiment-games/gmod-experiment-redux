local PANEL = {}

function PANEL:Init()
	self:Dock(FILL)
	self:SetPos(0, 0)

	self.messages = {
		"DISPERSE IMMEDIATELY",
		"RETURN TO YOUR HOMES",
		"UNAUTHORIZED ASSEMBLY",
		"COMPLY WITH ORDERS",
		"CLEAR THE AREA NOW",
		"MOVE ALONG DESIGNATED ROUTES",
		"CURFEW IN EFFECT",
		"AREA UNDER LOCKDOWN",
		"EVACUATE THE PREMISES",
		"MAINTAIN SAFE DISTANCE"
	}

	self.currentMessage = 0
	self.fadeAlpha = 255
	self.fadeDirection = 1
	self.messageTimer = 0
	self.messageDuration = 3
	self.pulseTimer = 0
	self.pulseIntensity = 0

	-- Authoritative color scheme
	self.alertColor = Color(220, 50, 50) -- Urgent red
	self.warningColor = Color(255, 165, 0) -- Warning orange
	self.textColor = Color(255, 255, 255) -- Pure white
	self.accentColor = Color(180, 180, 180) -- Light gray

	self:CreateElements()
	self:NextMessage()
end

function PANEL:CreateElements()
	self.authorityLabel = vgui.Create("DLabel", self)
	self.authorityLabel:SetText("CROWD CONTROL ACTIVE")
	self.authorityLabel:SetFont("expMonitorLarge")
	self.authorityLabel:SetTextColor(self.alertColor)
	self.authorityLabel:SetWrap(true)
	self.authorityLabel:SetAutoStretchVertical(true)
	self.authorityLabel:Dock(TOP)
	self.authorityLabel:DockMargin(100, 100, 100, 50)

	self.commandLabel = vgui.Create("DLabel", self)
	self.commandLabel:SetFont("expMonitorLarge")
	self.commandLabel:SetTextColor(self.textColor)
	self.commandLabel:SetWrap(true)
	self.commandLabel:SetAutoStretchVertical(true)
	self.commandLabel:Dock(FILL)
	self.commandLabel:DockMargin(100, 100, 100, 100)
end

function PANEL:NextMessage()
	self.currentMessage = self.currentMessage + 1
	if (self.currentMessage > #self.messages) then
		self.currentMessage = 1
	end

	self.fadeAlpha = 0
	self.fadeDirection = 1
	self.messageTimer = CurTime()

	self.commandLabel:SetText(self.messages[self.currentMessage])
	self.commandLabel:SizeToContents()
end

function PANEL:Think()
	local timeSinceMessage = CurTime() - self.messageTimer

	if (timeSinceMessage < 0.4) then
		self.fadeAlpha = math.min(255, (timeSinceMessage / 0.4) * 255)
	elseif (timeSinceMessage > self.messageDuration - 0.4) then
		self.fadeAlpha = math.max(0, ((self.messageDuration - timeSinceMessage) / 0.4) * 255)
	else
		self.fadeAlpha = 255
	end

	-- Pulse effect for urgency
	self.pulseTimer = self.pulseTimer + FrameTime()
	self.pulseIntensity = math.sin(self.pulseTimer * 3) * 30 + 30

	-- Update command message color with fade and pulse
	local pulseRed = math.min(255, self.textColor.r + self.pulseIntensity)
	local fadeColor = Color(pulseRed, self.textColor.g, self.textColor.b, self.fadeAlpha)
	self.commandLabel:SetTextColor(fadeColor)

	-- Check if it's time for next message
	if (timeSinceMessage >= self.messageDuration) then
		self:NextMessage()
	end
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(
		self.alertColor.r, self.alertColor.g, self.alertColor.b,
		(math.sin(CurTime() * 2) * 0.5 + 0.5) * 100
	)
	surface.DrawRect(0, 0, width, height)

	-- Draw corner indicators
	local cornerOffset = 50
	local cornerSize = 100
	surface.SetDrawColor(self.alertColor.r, self.alertColor.g, self.alertColor.b, 200)

	local thickness = 25

	-- Top left corner
	surface.DrawRect(cornerOffset, cornerOffset, cornerSize, thickness)
	surface.DrawRect(cornerOffset, cornerOffset + thickness, thickness, cornerSize - thickness)

	-- Top right corner
	surface.DrawRect(width - cornerOffset - cornerSize, cornerOffset, cornerSize, thickness)
	surface.DrawRect(width - cornerOffset - thickness, cornerOffset + thickness, thickness, cornerSize - thickness)

	-- Bottom left corner
	surface.DrawRect(cornerOffset, height - cornerOffset - thickness, cornerSize, thickness)
	surface.DrawRect(cornerOffset, height - cornerOffset - cornerSize, thickness, cornerSize - thickness)

	-- Bottom right corner
	surface.DrawRect(width - cornerOffset - cornerSize, height - cornerOffset - thickness, cornerSize, thickness)
	surface.DrawRect(width - cornerOffset - thickness, height - cornerOffset - cornerSize, thickness,
		cornerSize - thickness)

	-- Emergency alert indicator
	surface.SetTextColor(self.alertColor.r, self.alertColor.g, self.alertColor.b, 255)
	surface.SetFont("expMonitorSmall")
	local alertText = "⚠ EMERGENCY PROTOCOL ENGAGED ⚠"
	local textWidth, textHeight = surface.GetTextSize(alertText)
	surface.SetTextPos((width - textWidth) / 2, 30)
	surface.DrawText(alertText)

	-- Draw Nemesis Authority bottom
	surface.SetTextColor(self.alertColor.r, self.alertColor.g, self.alertColor.b, 255)
	surface.SetFont("expMonitorMedium")
	local authorityText = "BY ORDER OF NEMESIS AUTHORITY"
	local textWidth, textHeight = surface.GetTextSize(authorityText)
	surface.SetTextPos((width - textWidth) / 2, height - textHeight - 100)
	surface.DrawText(authorityText)
end

vgui.Register("expPrologueMonitorRiot1", PANEL, "Panel")
