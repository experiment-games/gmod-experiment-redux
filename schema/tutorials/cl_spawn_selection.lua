local TUTORIAL = TUTORIAL

TUTORIAL.uniqueID = "spawn_selection"
TUTORIAL.activateOn = "OnSpawnSelectOpen"
TUTORIAL.activateOnDelay = 0.5
TUTORIAL.deactivateOn = "OnSpawnSelectSuccess"

function TUTORIAL:GetText()
	return {
		"You get to choose where you spawn.",
		Schema.tutorial.ImportantText("Click any safe spawn point to continue."),
	}
end

function TUTORIAL:DrawFocusAreas(scrW, scrH, alpha)
	if not IsValid(ix.gui.spawnSelection) then
		return
	end

	local x, y = ix.gui.spawnSelection:LocalToScreen(0, 0)
	local w, h = ix.gui.spawnSelection:GetSize()

	Schema.draw.DrawUndimmedRect(x, y, w, h, alpha)
end
