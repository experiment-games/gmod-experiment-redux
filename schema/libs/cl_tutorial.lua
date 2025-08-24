Schema.tutorial = ix.util.GetOrCreateCommonLibrary("tutorial", nil, {
	currentTutorial = nil,
	currentFade = 0,
	tutorialQueue = {},
	isDisabled = false,
	skipButtonDownAt = nil,
	hasAlreadyNotShown = false,
	registeredHooks = {}
})

ix.option.Add("showTutorial", ix.type.bool, true, {
	category = "general",
	OnChanged = function(oldValue, newValue)
		if (newValue) then
			Schema.tutorial.isDisabled = false
			ix.util.Notify("The tutorial will now be shown when you rejoin the server.")
		end
	end,
})

-- Helper function for important text styling
function Schema.tutorial.ImportantText(text)
	return {
		important = true,
		text = text,
		color = ix.config.Get("color"),
	}
end

function Schema.tutorial.OnPreRegister(tutorial)
	tutorial.active = false

	function tutorial:Deactivate()
		if (self.active) then
			Schema.tutorial.HideTutorial(self.uniqueID)
		end
	end
end

function Schema.tutorial.OnPostRegister(tutorial)
	-- Register hooks for activateOn and deactivateOn
	if (tutorial.activateOn) then
		local activateOn = istable(tutorial.activateOn) and tutorial.activateOn or { tutorial.activateOn }

		for _, hookName in ipairs(activateOn) do
			hook.Add(hookName, "expTutorial" .. "#" .. tutorial.uniqueID .. ":" .. hookName, function(...)
				local args = { ... }

				if (tutorial.ShouldActivate) then
					if (tutorial.ShouldActivate(unpack(args)) == false) then
						return
					end
				end

				local delay = tutorial.activateOnDelay or 0

				timer.Simple(delay, function()
					if (not tutorial.active and not Schema.tutorial.isDisabled) then
						Schema.tutorial.ShowTutorial(tutorial.uniqueID, unpack(args))
					end
				end)
			end)
		end
	end

	if (tutorial.deactivateOn) then
		local deactivateOn = istable(tutorial.deactivateOn) and tutorial.deactivateOn or { tutorial.deactivateOn }

		for _, hookName in ipairs(deactivateOn) do
			hook.Add(hookName, "expTutorialDeactivate" .. "#" .. tutorial.uniqueID .. ":" .. hookName, function(...)
				if (tutorial.active) then
					if (tutorial.ShouldDeactivate) then
						if (tutorial.ShouldDeactivate(...) == false) then
							return
						end
					end

					Schema.tutorial.HideTutorial(tutorial.uniqueID)
				end
			end)
		end
	end
end

function Schema.tutorial.DisableTutorial()
	if (Schema.tutorial.isDisabled) then
		return
	end

	Schema.tutorial.isDisabled = true
	ix.option.Set("showTutorial", false)

	-- Clear current tutorial and queue
	Schema.tutorial.HideCurrentTutorial()
	Schema.tutorial.tutorialQueue = {}
end

function Schema.tutorial.ShowTutorial(tutorialID, ...)
	if (Schema.tutorial.isDisabled) then
		return
	end

	local tutorial = Schema.tutorial.Find(tutorialID)

	if (not tutorial) then
		return
	end

	if (tutorial.ShouldActivate) then
		if (tutorial.ShouldActivate(...) == false) then
			return
		end
	end

	-- If a tutorial is currently active, queue this one
	if (Schema.tutorial.currentTutorial) then
		-- TODO: Queuing by default is glitchy since it might open a tutorial in an unexpected place
		-- -- Don't queue if its already queued
		-- if (Schema.tutorial.IsTutorialQueued(tutorialID)) then
		-- 	return
		-- end

		-- table.insert(Schema.tutorial.tutorialQueue, {
		-- 	tutorial = tutorial,
		-- 	args = { ... }
		-- })

		return
	end

	-- Show the tutorial immediately
	Schema.tutorial.SetCurrentTutorial(tutorial, ...)
end

function Schema.tutorial.QueueTutorial(tutorialID, ...)
	if (Schema.tutorial.isDisabled) then
		return
	end

	local tutorial = Schema.tutorial.Find(tutorialID)

	if (not tutorial) then
		return
	end

	table.insert(Schema.tutorial.tutorialQueue, {
		tutorial = tutorial,
		args = { ... }
	})
end

function Schema.tutorial.HideTutorial(tutorialID)
	local tutorial = Schema.tutorial.Find(tutorialID)

	if (not tutorial or not tutorial.active) then
		return
	end

	-- If this is the current tutorial, hide it
	if (Schema.tutorial.currentTutorial == tutorial) then
		Schema.tutorial.HideCurrentTutorial()
	else
		-- Remove from queue if it's there
		for i, queuedItem in ipairs(Schema.tutorial.tutorialQueue) do
			if (queuedItem.tutorial == tutorial) then
				table.remove(Schema.tutorial.tutorialQueue, i)
				break
			end
		end
	end
end

function Schema.tutorial.SetCurrentTutorial(tutorial, ...)
	Schema.tutorial.HideCurrentTutorial()

	Schema.tutorial.currentTutorial = tutorial
	tutorial.active = true

	if (tutorial.OnActivate) then
		tutorial:OnActivate(...)
	end
end

function Schema.tutorial.HideCurrentTutorial()
	if (not Schema.tutorial.currentTutorial or not Schema.tutorial.currentTutorial.active) then
		return
	end

	local tutorial = Schema.tutorial.currentTutorial
	tutorial.active = false
	Schema.tutorial.currentFade = 0

	Schema.tutorial.currentTutorial = nil

	if (tutorial.OnDeactivate) then
		tutorial:OnDeactivate()
	end

	-- Show next tutorial in queue if any
	if (#Schema.tutorial.tutorialQueue > 0) then
		local nextItem = table.remove(Schema.tutorial.tutorialQueue, 1)
		Schema.tutorial.SetCurrentTutorial(nextItem.tutorial, unpack(nextItem.args))
	end
end

function Schema.tutorial.GetCurrentTutorial()
	return Schema.tutorial.currentTutorial
end

function Schema.tutorial.IsCurrentTutorial(tutorialID)
	return Schema.tutorial.currentTutorial and Schema.tutorial.currentTutorial.uniqueID == tutorialID
end

function Schema.tutorial.IsTutorialQueued(tutorialID)
	for _, queuedItem in ipairs(Schema.tutorial.tutorialQueue) do
		if (queuedItem.tutorial.uniqueID == tutorialID) then
			return true
		end
	end

	return false
end

function Schema.tutorial.FindMenuButton(buttonName)
	local menuPanel = ix.gui.menu

	if (not IsValid(menuPanel) or not IsValid(menuPanel.tabs) or menuPanel.bClosing) then
		return
	end

	for k, tabButton in pairs(menuPanel.tabs.buttons) do
		if (tabButton.name == buttonName) then
			return tabButton
		end
	end
end

-- Think hook for skip functionality
hook.Add("Think", "expTutorialsThink", function()
	local tutorials = Schema.tutorial

	if (tutorials.isDisabled) then
		return
	end

	if (not tutorials.skipButtonDownAt and input.IsKeyDown(KEY_BACKSPACE)) then
		tutorials.skipButtonDownAt = CurTime()
	elseif (tutorials.skipButtonDownAt and not input.IsKeyDown(KEY_BACKSPACE)) then
		tutorials.skipButtonDownAt = nil
	elseif (tutorials.skipButtonDownAt and CurTime() - tutorials.skipButtonDownAt >= 3) then
		ix.util.Notify("Tutorial disabled, you can always re-enable it in the settings.")
		tutorials:DisableTutorial()
	end
end)

-- Drawing hook
hook.Add("DrawOverlay", "expTutorialsDrawOverlay", function()
	local tutorials = Schema.tutorial
	local showTutorial = ix.option.Get("showTutorial")

	if (not showTutorial or tutorials.hasAlreadyNotShown) then
		-- Prevent the tutorial from starting during gameplay
		tutorials.hasAlreadyNotShown = true
		return
	end

	local currentTutorial = tutorials:GetCurrentTutorial()

	if (not currentTutorial or not currentTutorial.active) then
		return
	end

	tutorials.currentFade = math.Approach(tutorials.currentFade, 1, FrameTime())
	local scrW, scrH = ScrW(), ScrH()

	-- Draw focus areas or dim overlay
	if (currentTutorial.DrawFocusAreas) then
		currentTutorial:DrawFocusAreas(scrW, scrH, tutorials.currentFade * 230)
	else
		surface.SetDrawColor(0, 0, 0, tutorials.currentFade * 230)
		surface.DrawRect(0, 0, scrW, scrH)
	end

	-- Get text and positioning
	local text, textX, textY, textAlignX, textAlignY

	if (currentTutorial.GetText) then
		text, textX, textY, textAlignX, textAlignY = currentTutorial:GetText()
	end

	text = text or currentTutorial.text
	textX = textX or scrW * .5
	textY = textY or scrH * .5
	textAlignX = textAlignX or TEXT_ALIGN_CENTER
	textAlignY = textAlignY or TEXT_ALIGN_CENTER

	if (isstring(text) or text.important) then
		text = { text }
	end

	-- Draw tutorial text
	for i = 1, #text do
		local line = textAlignY == TEXT_ALIGN_BOTTOM and text[#text - i + 1] or text[i]
		local yOffset = textAlignY == TEXT_ALIGN_BOTTOM and -1 or 1
		local color = color_white

		if (istable(line)) then
			if (line.color) then
				color = line.color
			end

			line = line.text
		end

		color = Color(color.r, color.g, color.b, tutorials.currentFade * 255)

		draw.SimpleTextOutlined(line, "ixMediumFont", textX, textY + (i - 1) * 20 * yOffset, color, textAlignX,
			textAlignY, 1, color_black)
	end

	-- Show disable tutorial hint
	local disableTutorialText = "Hold BACKSPACE for 3 seconds to disable the tutorial."
	draw.SimpleTextOutlined(disableTutorialText, "expSmallerFont", scrW - 8, scrH - 8, color_white, TEXT_ALIGN_RIGHT,
		TEXT_ALIGN_BOTTOM, 1, color_black)

	-- Draw skip button if tutorial is skippable
	if (not currentTutorial.Skippable) then
		return
	end

	local skipX, skipY = textX, textY + (#text + 1) * 20
	local textWidth, textHeight = Schema.GetCachedTextSize("ixMediumFont", "Close")
	local buttonWidth = math.max(textWidth + 8, 200)

	local cursorX, cursorY = input.GetCursorPos()
	local color = ix.config.Get("color")

	if (cursorX >= skipX - buttonWidth * .5 and cursorX <= skipX + buttonWidth * .5 and
			cursorY >= skipY - textHeight * .5 - 4 and cursorY <= skipY + textHeight * .5 + 4) then
		if (input.IsMouseDown(MOUSE_LEFT)) then
			tutorials:HideCurrentTutorial()

			return
		end

		color = Color(255, 255, 255, 255)
	end

	surface.SetDrawColor(color.r, color.g, color.b, tutorials.currentFade * 255)
	surface.DrawRect(skipX - buttonWidth * .5, skipY - textHeight * .5 - 4, buttonWidth, textHeight + 8)

	draw.SimpleText("Close", "ixMediumFont", skipX, skipY, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
