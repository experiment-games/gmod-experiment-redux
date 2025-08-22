local PLUGIN = PLUGIN
local TUTORIAL = TUTORIAL

TUTORIAL.uniqueID = "you_tab_contents"
TUTORIAL.deactivateOn = "PopulatedBuffTooltip"

function TUTORIAL:ShouldActivate()
	return PLUGIN.MISSION_2_TRACKER_GOAL_1:CheckProgress(player)
		and not PLUGIN.MISSION_2_TRACKER_GOAL_2:CheckProgress()
		and not IsValid(ix.gui.spawnSelection)
end

function TUTORIAL:OnActivate()
	if (not IsValid(ix.gui.characterBuffs)) then
		ix.util.SchemaErrorNoHalt("Tried to activate the 'You' tab tutorial, but the buffs panel was not found.")
		self:Deactivate()
		return
	end

	self.buffsPanel = ix.gui.characterBuffs:GetParent()
end

function TUTORIAL:OnDeactivate(menuPanel)
	net.Start("expOnboardingMissionProgress")
	net.WriteString("mission2.2")
	net.SendToServer()
end

function TUTORIAL:DrawFocusAreas(scrW, scrH, alpha)
	local menuPanel = ix.gui.menu

	if (not IsValid(menuPanel) or not IsValid(menuPanel.tabs) or menuPanel.bClosing) then
		return
	end

	if (not IsValid(self.buffsPanel)) then
		return
	end

	local x, y = self.buffsPanel:LocalToScreen(0, 0)
	local w, h = self.buffsPanel:GetSize()

	Schema.draw.DrawUndimmedRect(
		x,
		y,
		w,
		h,
		alpha
	)
end

function TUTORIAL:GetText()
	if (not IsValid(self.buffsPanel)) then
		local menuKey = Schema.util.LookupBinding("+showscores") or "TAB"

		return {
			Schema.tutorial.ImportantText("Press " .. menuKey .. " once to open the main menu."),
		}
	end

	local x, y = self.buffsPanel:LocalToScreen(0, 0)
	local w, h = self.buffsPanel:GetSize()

	return {
		"Through nano technology you can be (de)buffed.",
		"Hovering over a buff will show how it affects you.",
		Schema.tutorial.ImportantText("Hover over a nano buff to view what it does."),
	}, x + (w * .5), y + h, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP
end
