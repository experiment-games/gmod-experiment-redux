local PLUGIN = PLUGIN
local TUTORIAL = TUTORIAL

TUTORIAL.uniqueID = "you_tab"
TUTORIAL.activateOn = "PlayerProgressionChange"
TUTORIAL.deactivateOn = "CreateCharacterBuffInfo"

function TUTORIAL:ShouldActivate()
	return PLUGIN.MISSION_2_TRACKER_GOAL_1:CheckProgress(player)
		and not PLUGIN.MISSION_2_TRACKER_GOAL_2:CheckProgress()
		and not IsValid(ix.gui.spawnSelection)
end

function TUTORIAL:OnDeactivate()
	Schema.tutorial.ShowTutorial("you_tab_contents")
end

function TUTORIAL:DrawFocusAreas(scrW, scrH, alpha)
	local youButton = Schema.tutorial.FindMenuButton("you")

	if not youButton or not IsValid(youButton) then
		return
	end

	Schema.tutorial.youButton = youButton

	local x, y = youButton:LocalToScreen(0, 0)
	local w, h = youButton:GetSize()

	if youButton:GetSelected() then
		Schema.tutorial.HideCurrentTutorial()
		return
	end

	Schema.draw.DrawUndimmedRect(x, y, w, h, alpha)
end

function TUTORIAL:GetText()
	local menuPanel = ix.gui.menu

	if not IsValid(menuPanel) or menuPanel.bClosing then
		local menuKey = Schema.util.LookupBinding("+showscores") or "TAB"

		return {
			Schema.tutorial.ImportantText("Press " .. menuKey .. " once to open the main menu."),
		}
	end

	if not Schema.tutorial.youButton or not IsValid(Schema.tutorial.youButton) then
		return
	end

	local x, y = Schema.tutorial.youButton:LocalToScreen(0, 0)
	local w, h = Schema.tutorial.youButton:GetSize()

	return Schema.tutorial.ImportantText("Click on the 'You' tab to continue."), x + w + 8, y + (h * .5), TEXT_ALIGN_LEFT,
		TEXT_ALIGN_CENTER
end
