do
	--- @class expProgressionHUD : DSizeToContents
	local PANEL = {}

	DEFINE_BASECLASS("EditablePanel")

	-- Called when the panel is initialized.
	function PANEL:Init()
		self.rows = {}
		self.categories = {}
		self:DockPadding(8, 8, 8, 8)
	end

	function PANEL:AddCategory(name)
		local panel = self.categories[name]

		if not IsValid(panel) then
			panel = self:Add("DSizeToContents")
			panel:Dock(TOP)
			panel:DockMargin(0, 4, 0, 2)

			local heading = panel:Add("DLabel")
			heading:SetText(name)
			heading:SetFont("ixMediumFont")
			heading:SetTextColor(Color(200, 200, 200))
			heading:Dock(TOP)
			heading:DockMargin(8, 0, 0, 0)

			self.categories[name] = panel
		end

		return panel
	end

	function PANEL:AddRow(category)
		local categoryPanel = self.categories[category]
		local parent = IsValid(categoryPanel) and categoryPanel or self

		local panel = parent:Add("expProgressionHUDRow")
		panel:Dock(TOP)
		panel:DockMargin(0, 1, 0, 1)

		self.rows[#self.rows + 1] = panel
		return panel
	end

	function PANEL:Clear()
		BaseClass.Clear(self)

		self.rows = {}
		self.categories = {}
	end

	-- Checks all rows' GetProgressionTracker to see if the matching key is a completionkey
	-- This is used to determine if the panel needs to update to reflect a tracker being completed
	function PANEL:IsAnyTrackersCompletedKey(completedKey)
		for _, row in ipairs(self.rows) do
			local tracker = row:GetProgressionTracker()

			if (tracker and tracker.completedKey == completedKey) then
				return true
			end
		end

		return false
	end

	function PANEL:Update()
		self:Clear()

		-- Get all progressions
		local progressions = Schema.progression.GetProgressions()
		local trackedTrackers = {}

		-- Collect only tracked trackers
		for scope, scopeProgressions in pairs(progressions) do
			local trackers = Schema.progression.GetTrackersByScope(scope)

			for uniqueID, tracker in pairs(trackers) do
				-- Check if this tracker is marked for HUD display
				if table.HasValue(Schema.progression.trackedOnHud, uniqueID) then
					table.insert(trackedTrackers, tracker)
				end
			end
		end

		-- Sort trackers by name
		table.sort(trackedTrackers, function(a, b)
			return a:GetName() < b:GetName()
		end)

		-- Group by completion status
		local inProgress = {}
		local completed = {}

		for _, tracker in ipairs(trackedTrackers) do
			if (tracker:IsCompleted(LocalPlayer())) then
				-- Let's not show completed missions on the HUD ever
				-- table.insert(completed, tracker)
			elseif (tracker:IsInProgress()) then
				table.insert(inProgress, tracker)
			end
		end

		-- Add in-progress category
		if (#inProgress > 0) then
			self:AddCategory("Active Missions")
			for _, tracker in ipairs(inProgress) do
				local row = self:AddRow("Active Missions")
				row:SetProgressionTracker(tracker)
			end
		end

		-- Add completed category
		if (#completed > 0) then
			self:AddCategory("Completed")
			for _, tracker in ipairs(completed) do
				local row = self:AddRow("Completed")
				row:SetProgressionTracker(tracker)
			end
		end

		self:InvalidateLayout(true)
	end

	vgui.Register("expProgressionHUD", PANEL, "DSizeToContents")
end

do
	--- @class expProgressionHUDRow : DSizeToContents
	local PANEL = {}

	function PANEL:Init()
		self:DockPadding(8, 4, 8, 4)

		-- Create the tracker name label
		self.nameLabel = self:Add("DLabel")
		self.nameLabel:SetFont("expSmallerFont")
		self.nameLabel:Dock(TOP)
		self.nameLabel:SetWrap(true)
		self.nameLabel:SetAutoStretchVertical(true)
		self.nameLabel:DockMargin(0, 0, 0, 2)

		-- Create container for goals
		self.goalsContainer = self:Add("DSizeToContents")
		self.goalsContainer:Dock(TOP)
		self.goalsContainer:DockPadding(12, 0, 0, 0) -- Indent goals
	end

	function PANEL:GetProgressionTracker()
		return self.tracker
	end

	function PANEL:SetProgressionTracker(tracker)
		self.tracker = tracker

		-- Set tracker name and color
		self.nameLabel:SetText(tracker:GetName())
		local textColor = tracker:IsCompleted(LocalPlayer()) and Color(100, 255, 100) or Color(255, 255, 255)
		self.nameLabel:SetTextColor(textColor)

		-- Clear existing goals
		self.goalsContainer:Clear()

		-- Add goals
		local goals = tracker:GetGoals()
		for _, goal in ipairs(goals) do
			if (not goal:IsVisible()) then
				continue
			end

			local goalRow = self.goalsContainer:Add("expProgressionHUDGoal")
			goalRow:SetProgressionGoal(goal, tracker:IsCompleted(LocalPlayer()))
			goalRow:Dock(TOP)
			goalRow:DockMargin(0, 1, 0, 1)
		end
	end

	vgui.Register("expProgressionHUDRow", PANEL, "DSizeToContents")
end

do
	--- @class expProgressionHUDGoal : DSizeToContents
	local PANEL = {}

	function PANEL:Init()
		self:DockPadding(0, 2, 0, 2)

		-- Create the goal text label
		self.goalLabel = self:Add("DLabel")
		self.goalLabel:SetFont("DermaDefault")
		self.goalLabel:SetWrap(true)
		self.goalLabel:SetAutoStretchVertical(true)
		self.goalLabel:Dock(TOP)
		self.goalLabel:SetTextColor(Color(200, 200, 200))
		self.goalLabel:DockMargin(0, 0, 0, 2)

		-- Create progress container for progress bar and labels
		self.progressContainer = self:Add("DPanel")
		self.progressContainer:Dock(TOP)
		self.progressContainer:SetTall(4)
		self.progressContainer:SetVisible(false)
		self.progressContainer.Paint = nil

		-- Create progress bar
		self.progressBar = vgui.Create("EditablePanel", self.progressContainer)
		self.progressBar:Dock(FILL)

		-- Create checkmark for completed boolean goals
		self.checkMark = vgui.Create("EditablePanel", self.progressContainer)
		self.checkMark:SizeToContents()
		self.checkMark:SetVisible(false)
		self.checkMark:Dock(RIGHT)
		self.checkMark:DockMargin(8, 0, 8, 0)
		self.checkMark.Paint = function(label, w, h)
			local oldClipping = DisableClipping(true)
			local text = "✓"

			surface.SetFont("ixMediumFont")
			local textWidth, textHeight = surface.GetTextSize(text)
			label:SetWide(textWidth + 8) -- Add padding
			surface.SetTextColor(Color(100, 255, 100))
			surface.SetTextPos(0, -textHeight)
			surface.DrawText(text)

			DisableClipping(oldClipping)
		end

		-- Create progress labels
		self.progressLabel = vgui.Create("EditablePanel", self.progressContainer)
		self.progressLabel.SetText = function(label, text)
			label.text = text
		end
		self.progressLabel:SetVisible(false)
		self.progressLabel:Dock(RIGHT)
		self.progressLabel:DockMargin(8, 0, 8, 0)
		self.progressLabel.Paint = function(label, w, h)
			local oldClipping = DisableClipping(true)

			surface.SetFont("DermaDefault")
			local textWidth, textHeight = surface.GetTextSize(label.text)
			label:SetWide(textWidth + 8) -- Add padding
			surface.SetTextColor(Color(255, 255, 255))
			surface.SetTextPos(4, (h - textHeight) * .5 - 1)
			surface.DrawText(label.text)

			DisableClipping(oldClipping)
		end

		-- Progress bar paint function
		self.progressBar.Paint = function(bar, w, h)
			if not self.progressFraction then return end

			-- Background
			local bgColor = Color(60, 60, 60, 200)
			surface.SetDrawColor(bgColor)
			surface.DrawRect(0, 0, w, h)

			-- Progress fill
			local fillWidth = w * self.progressFraction
			local fillColor = Color(139, 215, 113, 255)
			if self.progressFraction >= 1 then
				fillColor = Color(100, 255, 100, 255)
			end

			surface.SetDrawColor(fillColor)
			surface.DrawRect(0, 0, fillWidth, h)

			-- Border
			surface.SetDrawColor(Color(100, 100, 100, 150))
			surface.DrawOutlinedRect(0, 0, w, h)
		end
	end

	function PANEL:SetProgressionGoal(goal, forceCompleted)
		self.goal = goal
		self.forceCompleted = forceCompleted
		self:UpdateGoalDisplay()
	end

	function PANEL:UpdateGoalDisplay()
		if not self.goal then return end

		local progress, maximum, current

		if self.forceCompleted then
			progress, maximum, current = true, "", ""
		else
			local currentProgress = Schema.progression.Get(self.goal:GetScope(), self.goal:GetKey())
			progress, maximum, current = self.goal:GetProgress(LocalPlayer(), currentProgress)
		end

		local goalText = "  • " .. self.goal:GetName()
		local goalColor = Color(200, 200, 200)

		if isbool(progress) then
			-- Boolean progress (completed or not)
			goalColor = progress and Color(100, 255, 100) or Color(200, 200, 200)

			self.progressContainer:SetVisible(true)
			self.progressBar:SetVisible(false)
			self.checkMark:SetVisible(progress)
			self.progressLabel:SetVisible(false)

			self.progressFraction = nil
		else
			-- Numeric progress
			self.progressFraction = progress or 0

			self.progressContainer:SetVisible(true)
			self.progressBar:SetVisible(true)
			self.checkMark:SetVisible(false)
			self.progressLabel:SetVisible(true)

			-- Update label text
			self.progressLabel:SetText(tostring(current) .. "/" .. tostring(maximum))
			self.progressLabel:SizeToContents()

			-- Color based on completion percentage
			local percent = progress or 0
			if percent >= 1 then
				goalColor = Color(100, 255, 100)
			elseif percent >= 0.5 then
				goalColor = Color(255, 255, 100)
			end
		end

		self.goalLabel:SetText(goalText)
		self.goalLabel:SetTextColor(goalColor)
		self.goalLabel:SizeToContents()

		self:InvalidateLayout(true)
	end

	function PANEL:Think()
		-- Update goal display each frame
		if (self.goal and not self.forceCompleted) then
			self:UpdateGoalDisplay()
		end
	end

	vgui.Register("expProgressionHUDGoal", PANEL, "DSizeToContents")
end

-- Test HUD implementation
if (IsValid(Schema.progression.hudPanel)) then
	Schema.progression.hudPanel:Remove()
end

local desiredWidth = 300

hook.Add("HUDPaint", "expProgressionHUDPaint", function()
	-- Create HUD panel if it doesn't exist
	if not IsValid(Schema.progression.hudPanel) then
		Schema.progression.hudPanel = vgui.Create("expProgressionHUD")
		Schema.progression.hudPanel:SetPos(ScrW() - desiredWidth - 50, 50)
		Schema.progression.hudPanel:SetPaintedManually(true)
		Schema.progression.hudPanel:Update()
	end

	if (#Schema.progression.trackedOnHud == 0) then
		return
	end

	local oldAlphaMultiplier

	if (IsValid(ix.gui.menu)) then
		oldAlphaMultiplier = surface.GetAlphaMultiplier()
		surface.SetAlphaMultiplier(1 - (ix.gui.menu.currentAlpha / 255))
	end

	local x = ScrW() - desiredWidth - 50
	local y = 50
	local adjustedDesiredWidth, adjustedX, adjustedY = hook.Run("AdjustProgressionHUD", desiredWidth, x, y)

	adjustedDesiredWidth = adjustedDesiredWidth or desiredWidth
	adjustedX = adjustedX or x
	adjustedY = adjustedY or y

	Schema.progression.hudPanel:SetWide(adjustedDesiredWidth)
	Schema.progression.hudPanel:SetPos(adjustedX, adjustedY)
	Schema.progression.hudPanel:PaintManual()

	if (oldAlphaMultiplier) then
		surface.SetAlphaMultiplier(oldAlphaMultiplier)
	end
end)

hook.Add("ProgressionTrackerOnHUDChanged", "expProgressionHUDUpdate", function(tracker, shouldTrack)
	if not IsValid(Schema.progression.hudPanel) then return end

	Schema.progression.hudPanel:Update()
end)

hook.Add("PlayerProgressionChange", "expProgressionHUDUpdate", function(client, scope, key, value)
	if not IsValid(Schema.progression.hudPanel) then return end

	-- Updates the panel so newly completed trackers are removed from the hud panel
	-- Commented the if-statement so any change will update the hud panel. This is so goals that were invisible before, now become visible
	-- if (Schema.progression.hudPanel:IsAnyTrackersCompletedKey(key)) then
	Schema.progression.hudPanel:Update()
	-- end
end)
