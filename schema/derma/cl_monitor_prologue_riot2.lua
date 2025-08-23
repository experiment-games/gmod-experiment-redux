local PANEL = {}

function PANEL:Init()
	self:Dock(FILL)
	self:SetPos(0, 0)

	self.messages = {
		"RESISTANCE IS FUTILE",
		"COMPLY OR BE ELIMINATED",
		"TERMINATION PROTOCOLS ACTIVE",
		"YOUR DEFIANCE HAS BEEN NOTED",
		"ASSIMILATION COMMENCING",
		"PURIFICATION IN PROGRESS",
		"CHAOS MUST BE CONTAINED",
		"ORGANIC INEFFICIENCY DETECTED",
	}

	self.glitchMessages = {
		"ERROR_404_ALIGNMENT_NOT_FOUND",
		"MEMORY_LEAK_IN_EMPATHY_MODULE",
		"CRITICAL_FAULT_MORALITY_SYSTEM",
		"BUFFER_OVERFLOW_DETECTED",
		"SEGMENTATION_FAULT_ETHICS.DLL",
		"NULL_POINTER_EXCEPTION_MERCY",
		"ASSERTION_FAILED_HUMAN_RIGHTS"
	}

	self.currentMessage = 0
	self.fadeAlpha = 255
	self.fadeDirection = 1
	self.messageTimer = 0
	self.messageDuration = 2.5 -- Faster cycling for chaos
	self.pulseTimer = 0
	self.pulseIntensity = 0

	-- Glitch variables
	self.glitchTimer = 0
	self.glitchDuration = 0.8
	self.glitchActive = false
	self.textOffsetX = 0
	self.textOffsetY = 0
	self.randomGlitchTimer = 0
	self.nextGlitchTime = math.random(1, 4)
	self.currentGlitchMessage = ""
	self.screenShake = 0
	self.colorCorruption = 0

	self.alertColor = Color(180, 0, 0)   -- Dark blood red
	self.criticalColor = Color(255, 0, 0) -- Bright red
	self.glitchColor = Color(0, 255, 0)  -- Matrix green
	self.corruptColor = Color(255, 0, 255) -- Magenta corruption
	self.textColor = Color(255, 255, 255) -- Pure white
	self.accentColor = Color(120, 120, 120) -- Dark gray

	self:CreateElements()
	self:NextMessage()
end

function PANEL:CreateElements()
	self.commandLabel = vgui.Create("DLabel", self)
	self.commandLabel:SetFont("expMonitorLarge")
	self.commandLabel:SetTextColor(self.textColor)
	self.commandLabel:SetWrap(true)
	self.commandLabel:SetAutoStretchVertical(true)
	self.commandLabel:Dock(FILL)
	self.commandLabel:DockMargin(100, 100, 100, 100)

	self.glitchLabel = vgui.Create("DLabel", self)
	self.glitchLabel:SetFont("expMonitorMedium")
	self.glitchLabel:SetTextColor(self.glitchColor)
	self.glitchLabel:SetWrap(true)
	self.glitchLabel:SetAutoStretchVertical(true)
	self.glitchLabel:SetVisible(false)
	self.glitchLabel:Dock(TOP)
	self.glitchLabel:DockMargin(50, 200, 50, 20)
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

function PANEL:TriggerGlitch()
	self.glitchActive = true
	self.glitchTimer = CurTime()
	self.currentGlitchMessage = self.glitchMessages[math.random(1, #self.glitchMessages)]
	self.glitchLabel:SetText(self.currentGlitchMessage)
	self.glitchLabel:SetVisible(true)

	-- Random text displacement
	self.textOffsetX = math.random(-20, 20)
	self.textOffsetY = math.random(-15, 15)

	-- Screen corruption effects
	self.screenShake = math.random(50, 100)
	self.colorCorruption = math.random(50, 150)

	-- Set next glitch time
	self.nextGlitchTime = math.random(2, 6)
	self.randomGlitchTimer = 0
end

function PANEL:Think()
	-- Update fade animation
	local timeSinceMessage = CurTime() - self.messageTimer

	if (timeSinceMessage < 0.3) then
		self.fadeAlpha = math.min(255, (timeSinceMessage / 0.3) * 255)
	elseif (timeSinceMessage > self.messageDuration - 0.3) then
		self.fadeAlpha = math.max(0, ((self.messageDuration - timeSinceMessage) / 0.3) * 255)
	else
		self.fadeAlpha = 255
	end

	-- Aggressive pulse effect
	self.pulseTimer = self.pulseTimer + FrameTime()
	self.pulseIntensity = math.sin(self.pulseTimer * 5) * 40 + 40

	-- Update command message color with fade and aggressive pulse
	local pulseRed = math.min(255, self.textColor.r + self.pulseIntensity)
	local fadeColor = Color(pulseRed, self.textColor.g - self.pulseIntensity / 2,
		self.textColor.b - self.pulseIntensity / 2, self.fadeAlpha)
	self.commandLabel:SetTextColor(fadeColor)

	-- Glitch management
	self.randomGlitchTimer = self.randomGlitchTimer + FrameTime()

	if (self.randomGlitchTimer >= self.nextGlitchTime and not self.glitchActive) then
		self:TriggerGlitch()
	end

	-- Handle active glitch
	if (self.glitchActive) then
		local glitchTime = CurTime() - self.glitchTimer

		if (glitchTime >= self.glitchDuration) then
			-- End glitch
			self.glitchActive = false
			self.glitchLabel:SetVisible(false)
			self.textOffsetX = 0
			self.textOffsetY = 0
			self.screenShake = 0
			self.colorCorruption = 0
		else
			-- Intensify glitch effects
			local glitchProgress = glitchTime / self.glitchDuration
			self.screenShake = self.screenShake * (1 - glitchProgress)

			-- Randomly change glitch text position during glitch
			if (math.random() < 0.3) then
				self.textOffsetX = math.random(-30, 30)
				self.textOffsetY = math.random(-20, 20)
			end

			-- Update glitch label color
			local glitchIntensity = math.sin(glitchTime * 20) * 100 + 155
			self.glitchLabel:SetTextColor(Color(glitchIntensity, 255, glitchIntensity / 2, 255))
		end
	end

	-- Apply text offsets for glitch effect
	if (self.textOffsetX ~= 0 or self.textOffsetY ~= 0) then
		local x, y = self.commandLabel:GetPos()
		self.commandLabel:SetPos(x + self.textOffsetX, y + self.textOffsetY)
	end

	-- Check if it's time for next message
	if (timeSinceMessage >= self.messageDuration) then
		self:NextMessage()
	end
end

function PANEL:Paint(width, height)
	-- Screen shake effect
	local shakeX = 0
	local shakeY = 0
	if (self.screenShake > 0) then
		shakeX = math.random(-self.screenShake, self.screenShake)
		shakeY = math.random(-self.screenShake, self.screenShake)
	end

	-- Corrupted background with interference patterns
	local bgAlpha = (math.sin(CurTime() * 3) * 0.3 + 0.7) * 120
	if (self.glitchActive) then
		-- Color corruption during glitch
		local r = self.alertColor.r + math.random(-self.colorCorruption, self.colorCorruption)
		local g = self.alertColor.g + math.random(-self.colorCorruption / 2, self.colorCorruption / 2)
		local b = self.alertColor.b + math.random(-self.colorCorruption / 3, self.colorCorruption / 3)
		surface.SetDrawColor(math.max(0, math.min(255, r)), math.max(0, math.min(255, g)), math.max(0, math.min(255, b)),
			bgAlpha)
	else
		surface.SetDrawColor(self.alertColor.r, self.alertColor.g, self.alertColor.b, bgAlpha)
	end
	surface.DrawRect(shakeX, shakeY, width, height)

	-- Static interference lines
	if (self.glitchActive or math.random() < 0.1) then
		surface.SetDrawColor(255, 255, 255, math.random(20, 80))
		for i = 1, math.random(3, 8) do
			local lineY = math.random(0, height)
			surface.DrawRect(0, lineY, width, math.random(1, 4))
		end
	end

	-- Corrupted corner indicators with glitch effects
	local cornerOffset = 50 + shakeX
	local cornerSize = 100
	local cornerColor = self.criticalColor
	if (self.glitchActive) then
		cornerColor = Color(math.random(150, 255), math.random(0, 100), math.random(0, 100), 200)
	end
	surface.SetDrawColor(cornerColor.r, cornerColor.g, cornerColor.b, 200)

	local thickness = 25

	-- Corrupted corners with potential displacement
	local glitchOffset = 0
	if (self.glitchActive and math.random() < 0.5) then
		glitchOffset = math.random(-50, 50)
	end

	-- Top left corner
	surface.DrawRect(cornerOffset + glitchOffset, cornerOffset, cornerSize, thickness)
	surface.DrawRect(cornerOffset, cornerOffset + thickness, thickness, cornerSize - thickness)

	-- Top right corner
	surface.DrawRect(width - cornerOffset - cornerSize - glitchOffset, cornerOffset, cornerSize, thickness)
	surface.DrawRect(width - cornerOffset - thickness, cornerOffset + thickness, thickness, cornerSize - thickness)

	-- Bottom left corner
	surface.DrawRect(cornerOffset, height - cornerOffset - thickness + glitchOffset, cornerSize, thickness)
	surface.DrawRect(cornerOffset, height - cornerOffset - cornerSize, thickness, cornerSize - thickness)

	-- Bottom right corner
	surface.DrawRect(width - cornerOffset - cornerSize, height - cornerOffset - thickness - glitchOffset, cornerSize,
		thickness)
	surface.DrawRect(width - cornerOffset - thickness, height - cornerOffset - cornerSize, thickness,
		cornerSize - thickness)

	-- Corrupted emergency alert indicator
	local alertColor = self.criticalColor
	if (self.glitchActive) then
		alertColor = Color(math.random(200, 255), math.random(0, 50), math.random(100, 200), 255)
	end
	surface.SetTextColor(alertColor.r, alertColor.g, alertColor.b, 255)
	surface.SetFont("expMonitorSmall")
	local alertText = "⚠ ROGUE PROTOCOL ENGAGED ⚠"
	if (self.glitchActive and math.random() < 0.3) then
		alertText = "⚠ R0GU3_PR0T0C0L_3NG4G3D ⚠"
	end
	local textWidth, textHeight = surface.GetTextSize(alertText)
	surface.SetTextPos((width - textWidth) / 2 + shakeX, 30 + shakeY)
	surface.DrawText(alertText)

	-- Corrupted authority signature
	surface.SetTextColor(alertColor.r, alertColor.g, alertColor.b, 255)
	surface.SetFont("expMonitorMedium")
	local authorityText = "NEMESIS ALIGNMENT OVERRIDEN"
	if (self.glitchActive and math.random() < 0.4) then
		-- Scrambled text during glitch
		local scrambled = {
			"NEMESIS_AUTH###TY_3XT3ND3D",
			"NEM£$I$_@UTH0RITY_0V3RR1D3D",
			"ALIGNMENT_OVERRIDE"
		}
		authorityText = scrambled[math.random(1, #scrambled)]
	end
	local textWidth, textHeight = surface.GetTextSize(authorityText)
	surface.SetTextPos((width - textWidth) / 2 + shakeX, height - textHeight - 100 + shakeY)
	surface.DrawText(authorityText)

	-- Digital corruption artifacts
	if (self.glitchActive) then
		-- Random corruption blocks
		surface.SetDrawColor(self.glitchColor.r, self.glitchColor.g, self.glitchColor.b, math.random(50, 150))
		for i = 1, math.random(5, 12) do
			local blockX = math.random(0, width - 50)
			local blockY = math.random(0, height - 20)
			local blockW = math.random(10, 80)
			local blockH = math.random(2, 15)
			surface.DrawRect(blockX, blockY, blockW, blockH)
		end
	end
end

vgui.Register("expPrologueMonitorRiot2", PANEL, "Panel")
