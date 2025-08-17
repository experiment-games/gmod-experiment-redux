local TUTORIAL = TUTORIAL

TUTORIAL.uniqueID = "main_menu"
TUTORIAL.activateOn = "OnSpawnSelectSuccess"
TUTORIAL.activateOnDelay = 5
TUTORIAL.deactivateOn = "OnMainMenuCreated"

function TUTORIAL:GetText()
	local menuKey = Schema.util.LookupBinding("+showscores") or "TAB"

	return {
		"Great! You've spawned in safely.",
		"Let's check how you're doing.",
		Schema.tutorial.ImportantText("Press " .. menuKey .. " once to open the main menu."),
	}
end
