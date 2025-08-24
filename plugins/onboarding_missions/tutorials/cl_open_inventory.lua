local PLUGIN = PLUGIN
local TUTORIAL = TUTORIAL

TUTORIAL.uniqueID = "prologue_riot3_open_inventory"

local timerName = "prologue_riot3_open_inventory_timer"

function TUTORIAL:OnActivate()
	timer.Create(timerName, 0, 0, function()
		-- If the menu is opened, deactivate this tutorial
		if (IsValid(ix.gui.menu)) then
			self:Deactivate()
			return
		end

		local glockEquipped = Schema.progression.Check("prologue", PLUGIN.PROGRESSION_GLOCK_EQUIPPED, true)
		local ammoLoaded = Schema.progression.Check("prologue", PLUGIN.PROGRESSION_AMMO_LOADED, true)

		-- If the glock is equipped and ammo is loaded, deactivate this tutorial
		if (glockEquipped and ammoLoaded) then
			self:Deactivate()
			return
		end
	end)
end

function TUTORIAL:OnDeactivate()
	timer.Remove(timerName)
end

function TUTORIAL:GetText()
	local menuKey = Schema.util.LookupBinding("+showscores") or "TAB"

	return {
		"To equip your weapon and load your ammo go to your inventory.",
		Schema.tutorial.ImportantText("Press " .. menuKey .. " once to open the main menu."),
	}
end
