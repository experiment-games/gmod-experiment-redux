local PANEL = {}

function PANEL:Init()
	self:Dock(FILL)
	self:SetPos(0, 0)

	self.messages = {
		"Welcome to this Experiment",
		"Don't forget to sign your waiver",
		"Safety is our priority during this simulation",
		"Approach our staff if you feel unsafe during a simulated riot",
		"Please follow all posted safety guidelines",
		"Emergency exits are clearly marked",
		"Medical personnel are standing by",
		"Thank you for participating in our research"
	}

	self.currentMessage = 0
	self.fadeAlpha = 255
	self.fadeDirection = 1
	self.messageTimer = 0
	self.messageDuration = 4

	self.accentColor = Color(65, 145, 200) -- Professional blue
	self.textColor = Color(220, 220, 220) -- Light gray
	self.headerColor = Color(255, 255, 255) -- White

	self:CreateElements()
	self:NextMessage()
end

function PANEL:CreateElements()
	self.headerLabel = vgui.Create("DLabel", self)
	self.headerLabel:SetText("GUARDIAN RESEARCH FACILITY")
	self.headerLabel:SetFont("expMonitorMedium")
	self.headerLabel:SetTextColor(self.headerColor)
	self.headerLabel:SetWrap(true)
	self.headerLabel:SetAutoStretchVertical(true)
	self.headerLabel:Dock(TOP)
	self.headerLabel:DockMargin(100, 100, 100, 0)

	self.subtitleLabel = vgui.Create("DLabel", self)
	self.subtitleLabel:SetText("Experimental Crowd Control Simulation")
	self.subtitleLabel:SetFont("expMonitorMedium")
	self.subtitleLabel:SetTextColor(self.accentColor)
	self.subtitleLabel:SetWrap(true)
	self.subtitleLabel:SetAutoStretchVertical(true)
	self.subtitleLabel:Dock(TOP)
	self.subtitleLabel:DockMargin(100, 50, 100, 100)

	self.messageLabel = vgui.Create("DLabel", self)
	self.messageLabel:SetFont("expMonitorLarge")
	self.messageLabel:SetTextColor(self.textColor)
	self.messageLabel:SetWrap(true)
	self.messageLabel:Dock(FILL)
	self.messageLabel:DockMargin(100, 100, 100, 100)
end

function PANEL:NextMessage()
	self.currentMessage = self.currentMessage + 1
	if (self.currentMessage > #self.messages) then
		self.currentMessage = 1
	end

	self.fadeAlpha = 0
	self.fadeDirection = 1
	self.messageTimer = CurTime()

	self.messageLabel:SetText(self.messages[self.currentMessage])
	self.messageLabel:SizeToContents()
end

function PANEL:Think()
	local timeSinceMessage = CurTime() - self.messageTimer

	if (timeSinceMessage < 0.5) then
		self.fadeAlpha = math.min(255, (timeSinceMessage / 0.5) * 255)
	elseif (timeSinceMessage > self.messageDuration - 0.5) then
		self.fadeAlpha = math.max(0, ((self.messageDuration - timeSinceMessage) / 0.5) * 255)
	else
		self.fadeAlpha = 255
	end

	local fadeColor = Color(self.textColor.r, self.textColor.g, self.textColor.b, self.fadeAlpha)
	self.messageLabel:SetTextColor(fadeColor)

	if (timeSinceMessage >= self.messageDuration) then
		self:NextMessage()
	end
end

function PANEL:Paint(width, height)
	surface.SetTextColor(self.accentColor.r, self.accentColor.g, self.accentColor.b, 255)
	surface.SetFont("expMonitorSmall")
	local textWidth, textHeight = surface.GetTextSize("SYSTEM STATUS: OPERATIONAL")
	surface.SetTextPos(width - textWidth - 100, height - textHeight - 100)
	surface.DrawText("SYSTEM STATUS: OPERATIONAL")
end

vgui.Register("expPrologueMonitorGateway", PANEL, "Panel")
