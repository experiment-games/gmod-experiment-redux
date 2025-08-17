local SCENE = SCENE
local TUTORIAL = TUTORIAL

TUTORIAL.uniqueID = "prologue_riot3_raise_weapon"

local timerName = "prologue_riot3_raise_weapon_timer"

function TUTORIAL:ShouldActivate()
	-- If the menu is still open, no need for the tutorial yet
	if (IsValid(ix.gui.menu)) then
		return false
	end
end

function TUTORIAL:OnActivate()
	timer.Create(timerName, 0, 0, function()
		-- If the weapon is raised, deactivate this tutorial
		if (LocalPlayer():IsWepRaised()) then
			self:Deactivate()
		end
	end)
end

function TUTORIAL:OnDeactivate()
	timer.Remove(timerName)
end

function TUTORIAL:GetText()
	local reloadKey = Schema.util.LookupBinding("reload") or "R"

	local texts = {
		"Your weapon needs to be raised to shoot.",
	}

	if (IsValid(ix.gui.menu) and not ix.gui.menu.bClosing) then
		table.insert(texts, Schema.tutorial.ImportantText("Close the main menu to continue."))
	else
		table.insert(texts, Schema.tutorial.ImportantText("Press and hold " .. reloadKey .. " to raise your weapon."))
	end

	return texts
end
