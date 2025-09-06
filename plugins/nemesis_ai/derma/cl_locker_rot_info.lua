local PLUGIN = PLUGIN
local PANEL = {}

local TEST_DATA = {
	START = {
		phaseKey = "START",
		forceStartTime = CurTime() + 10,
	},
	WAITING_FOR_ANTIVIRUS = {
		phaseKey = "WAITING_FOR_ANTIVIRUS",
		target = "Test Character",
		reveilTime = CurTime() + 20,
	},
	ANTIVIRUS_REVEALED = {
		phaseKey = "ANTIVIRUS_REVEALED",
		target = "Test Character",
		finishTime = CurTime() + 30,
	},
}

--- Returns the current phase and the stage data.
--- @return table? # phase
--- @return table? # stageData
local function getCurrentPhase()
	if (TEST_LOCKER_ROT_PANEL) then
		-- For testing purposes, we use the TEST_DATA
		local phaseKey = TEST_LOCKER_ROT_PANEL or "START"
		return PLUGIN.PHASES[phaseKey], TEST_DATA[phaseKey]
	end

	local phaseInfo = GetNetVar("locker_rot_event")

	if (not phaseInfo) then
		return nil, nil
	end

	local phaseKey = phaseInfo.phaseKey

	return PLUGIN.PHASES[phaseKey], phaseInfo
end

-- Stage Container Component
local STAGE_CONTAINER = {}

DEFINE_BASECLASS("DSizeToContents")

function STAGE_CONTAINER:Init()
	self:SetSizeX(false)
	self:Dock(TOP)
	self.Paint = function() end -- Transparent background

	-- Initialize state
	self.phaseKey = nil
	self.phase = nil
	self.stageData = nil
	self.isActive = false
	self.isPassed = false

	self:CreateElements()
end

function STAGE_CONTAINER:CreateElements()
	-- Create prefix label (right-aligned)
	self.prefixLabel = vgui.Create("DLabel", self)
	self.prefixLabel:SetFont("ixSmallFont")
	self.prefixLabel:SetText("")
	self.prefixLabel:SetPos(80 - self.prefixLabel:GetWide(), 0)
	self.prefixLabel:SizeToContents()

	-- Create stage labels panel with proper sizing
	self.stageLabelsPanel = vgui.Create("DSizeToContents", self)
	self.stageLabelsPanel:SetSizeX(false)

	-- Create main stage text label
	self.stageLabel = vgui.Create("DLabel", self.stageLabelsPanel)
	self.stageLabel:SetFont("ixSmallFont")
	self.stageLabel:SetText("")
	self.stageLabel:Dock(TOP)
	self.stageLabel:SetAutoStretchVertical(true)
	self.stageLabel:SetWrap(true)

	-- Create time label (will be shown/hidden as needed)
	self.timeLabel = vgui.Create("DLabel", self.stageLabelsPanel)
	self.timeLabel:SetFont("ixSmallFont")
	self.timeLabel:SetText("")
	self.timeLabel:Dock(TOP)
	self.timeLabel:SetAutoStretchVertical(true)
	self.timeLabel:SetWrap(true)
	self.timeLabel:SetVisible(false)
end

function STAGE_CONTAINER:PerformLayout()
	self.stageLabelsPanel:SetX(self.prefixLabel:GetWide() + 20)                  -- Position after prefix label
	self.stageLabelsPanel:SetWide(self:GetWide() - self.prefixLabel:GetWide() - 40) -- Leave margin on right
	self.stageLabel:InvalidateLayout(true)
	self.timeLabel:InvalidateLayout(true)

	BaseClass.PerformLayout(self)
end

function STAGE_CONTAINER:SetData(phaseKey, phase, stageData)
	if (self.phaseKey == phaseKey and self.phase == phase and self.stageData == stageData) then
		return -- No changes needed
	end

	self.phaseKey = phaseKey
	self.phase = phase
	self.stageData = stageData or {}

	-- Update prefix text
	local prefixText = "Phase " .. phase.order .. ": "
	self.prefixLabel:SetText(prefixText)
	self.prefixLabel:SizeToContents()

	-- Update stage text
	local targetText = self.isActive and phase.text or (phase.inactiveText or phase.text)
	local stageText = ""

	if (type(targetText) == "function") then
		stageText = targetText(self.stageData)
	else
		stageText = targetText
	end

	self.stageLabel:SetText(stageText)

	-- Force layout update on container
	self:InvalidateLayout(true)

	-- Update colors based on current state
	self:UpdateVisuals()
end

function STAGE_CONTAINER:SetActive(isActive, isPassed)
	if (self.isActive == isActive and self.isPassed == isPassed) then
		-- Still need to update time label even if state hasn't changed
		if (isActive) then
			self:UpdateTimeLabel()
		end
		return
	end

	local oldActive = self.isActive

	self.isActive = isActive
	self.isPassed = isPassed

	-- If active state changed, we need to refresh text (might switch between active/inactive text)
	if (oldActive ~= isActive and self.phase) then
		local targetText = isActive and self.phase.text or (self.phase.inactiveText or self.phase.text)
		local stageText = ""

		if (type(targetText) == "function") then
			stageText = targetText(self.stageData or {})
		else
			stageText = targetText
		end

		self.stageLabel:SetText(stageText)

		-- Force proper sizing after text change
		local parentWidth = self:GetParent() and self:GetParent():GetWide() or 400
		local availableWidth = parentWidth - 120

		self.stageLabel:SetWide(availableWidth)
		self.stageLabel:InvalidateLayout(true)
		self.stageLabelsPanel:InvalidateLayout(true)
		self:InvalidateLayout(true)
	end

	self:UpdateVisuals()
	self:UpdateTimeLabel()
end

function STAGE_CONTAINER:UpdateVisuals()
	if (not self.phase) then return end

	-- Calculate alpha based on state
	local alpha = self.isActive and 255 or self.isPassed and 40 or 100
	local textColor = Color(255, 255, 255, alpha)

	-- Update colors
	self.prefixLabel:SetTextColor(textColor)
	self.stageLabel:SetTextColor(textColor)

	-- Handle crossed-out effect for passed phases - only draw within our bounds
	if (self.isPassed) then
		self.PaintOver = function(this, w, h)
			-- Only draw lines within the actual content area
			surface.SetDrawColor(Color(255, 255, 255, alpha))
			surface.DrawLine(6, 6, w - 40, h - 6)
			surface.DrawLine(6, h - 6, w - 40, 6)
		end
	else
		self.PaintOver = nil
	end
end

function STAGE_CONTAINER:UpdateTimeLabel()
	if (not self.phase or not self.isActive) then
		if (self.timeLabel:IsVisible()) then
			self.timeLabel:SetVisible(false)
			self.stageLabelsPanel:InvalidateLayout(true)
			self:InvalidateLayout(true)
		end
		return
	end

	if (self.phase.timeRemaining and self.stageData) then
		local timeText = "Time remaining: " .. self.phase.timeRemaining(self.stageData)
		self.timeLabel:SetText(timeText)
		self.timeLabel:SetTextColor(Color(255, 200, 50, 255))

		if (not self.timeLabel:IsVisible()) then
			self.timeLabel:SetVisible(true)
		end

		-- Ensure proper sizing for time label
		local parentWidth = self:GetParent() and self:GetParent():GetWide() or 400
		local availableWidth = parentWidth - 120

		self.timeLabel:SetWide(availableWidth)
		self.timeLabel:InvalidateLayout(true)
		self.stageLabelsPanel:InvalidateLayout(true)
		self:InvalidateLayout(true)
	else
		if (self.timeLabel:IsVisible()) then
			self.timeLabel:SetVisible(false)
			self.stageLabelsPanel:InvalidateLayout(true)
			self:InvalidateLayout(true)
		end
	end
end

vgui.Register("expStageContainer", STAGE_CONTAINER, "DSizeToContents")

-- Main Panel
function PANEL:Init()
	self:SetSize(400, ScrH())
	self:SetSizeX(false)

	self.headerPanel = vgui.Create("DPanel", self)
	self.headerPanel:SetTall(50)
	self.headerPanel:Dock(TOP)
	self.headerPanel.Paint = function(panel, w, h)
		surface.SetMaterial(PLUGIN.lockerRotIcon)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(5, 5, 40, 40)
	end

	self.headerLabel = vgui.Create("DLabel", self.headerPanel)
	self.headerLabel:SetFont("ixMenuButtonFont")
	self.headerLabel:SetTextColor(Color(255, 50, 50, 255))
	self.headerLabel:SetText("Locker Rot Virus is Active!")
	self.headerLabel:SetPos(60, 8) -- Position after icon
	self.headerLabel:SizeToContents()

	self.stagePanel = vgui.Create("DSizeToContents", self)
	self.stagePanel:SetSizeX(false)
	self.stagePanel:Dock(TOP)
	self.stagePanel:DockMargin(0, 5, 0, 0)
	self.stagePanel.Paint = function() end -- Transparent background

	self.stageContainers = {}
	self:CreateStageContainers()

	-- Store last known state for comparison
	self.lastPhase = nil
	self.lastStageData = nil
end

function PANEL:CreateStageContainers()
	local phases = PLUGIN.PHASES

	for phaseKey, phase in SortedPairsByMemberValue(phases, "order") do
		local stageContainer = vgui.Create("expStageContainer", self.stagePanel)
		stageContainer:SetData(phaseKey, phase, nil)
		self.stageContainers[phaseKey] = stageContainer
	end
end

function PANEL:UpdateStages()
	local currentPhase, stageData = getCurrentPhase()

	-- Only update if something has changed
	if (currentPhase == self.lastPhase and stageData == self.lastStageData) then
		-- Still update time labels for active phases (they might have time remaining)
		if (currentPhase and self.stageContainers[currentPhase.key]) then
			self.stageContainers[currentPhase.key]:UpdateTimeLabel()
		end

		return
	end

	self.lastPhase = currentPhase
	self.lastStageData = stageData

	local phases = PLUGIN.PHASES

	for phaseKey, phase in pairs(phases) do
		local stageContainer = self.stageContainers[phaseKey]
		if (stageContainer) then
			local isActive = currentPhase and currentPhase.key == phaseKey
			local isPassed = currentPhase and currentPhase.order > phase.order

			-- Update data (will only update if changed)
			stageContainer:SetData(phaseKey, phase, isActive and stageData or nil)

			-- Update active/passed state (will only update if changed)
			stageContainer:SetActive(isActive, isPassed)
		end
	end
end

function PANEL:Think()
	-- Update the panel periodically to refresh time remaining
	self.nextUpdate = self.nextUpdate or 0

	if (CurTime() > self.nextUpdate) then
		self:UpdateStages()
		self.nextUpdate = CurTime() + 1 -- Update every second
	end
end

vgui.Register("expLockerRotEventPanel", PANEL, "DSizeToContents")
