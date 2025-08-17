local SCENE = SCENE
local TUTORIAL = TUTORIAL

TUTORIAL.uniqueID = "prologue_riot3_equip_weapon_and_ammo"

local timerName = "prologue_riot3_equip_weapon_and_ammo_timer"

function TUTORIAL:OnActivate()
	timer.Create(timerName, 0, 0, function()
		local glockEquipped = Schema.progression.Check("prologue", SCENE.PROGRESSION_GLOCK_EQUIPPED, true)
		local ammoLoaded = Schema.progression.Check("prologue", SCENE.PROGRESSION_AMMO_LOADED, true)

		-- If the glock is equipped and ammo is loaded, deactivate this tutorial
		if (glockEquipped and ammoLoaded) then
			self:Deactivate()
		end
	end)
end

function TUTORIAL:OnDeactivate()
	timer.Remove(timerName)
end

function TUTORIAL:DrawFocusAreas(scrW, scrH, alpha)
	if (not IsValid(ix.gui.inv1)) then
		return
	end

	local x, y = ix.gui.inv1:LocalToScreen(0, 0)
	local w, h = ix.gui.inv1:GetSize()

	Schema.draw.DrawUndimmedRect(x, y, w, h, alpha)
end

function TUTORIAL:GetText()
	local menuPanel = ix.gui.menu

	if (not IsValid(menuPanel) or menuPanel.bClosing) then
		local menuKey = Schema.util.LookupBinding("+showscores") or "TAB"

		return {
			Schema.tutorial.ImportantText("Press " .. menuKey .. " once to open the main menu."),
		}
	end

	if (not IsValid(ix.gui.inv1) or not ix.gui.inv1:IsVisible()) then
		return {
			Schema.tutorial.ImportantText("Click on the inventory tab to continue."),
		}
	end

	local x, y = ix.gui.inv1:LocalToScreen(0, 0)
	local w, h = ix.gui.inv1:GetSize()

	local glockEquipped = Schema.progression.Check("prologue", SCENE.PROGRESSION_GLOCK_EQUIPPED, true)
	local ammoLoaded = Schema.progression.Check("prologue", SCENE.PROGRESSION_AMMO_LOADED, true)

	local texts = {
		"Here you see your inventory. Hover over an item to show more information.",
		"Right click an item to see what you can do with it.",
	}

	if (not glockEquipped) then
		table.insert(
			texts,
			Schema.tutorial.ImportantText("Right-click the weapon, then select 'Equip' to continue.")
		)
	end

	if (not ammoLoaded) then
		table.insert(
			texts,
			Schema.tutorial.ImportantText("Right-click the ammo, then select 'Load' to continue.")
		)
	end

	return texts, x, y + h, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
end
