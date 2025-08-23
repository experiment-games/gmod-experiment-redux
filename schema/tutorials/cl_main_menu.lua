local TUTORIAL = TUTORIAL

TUTORIAL.uniqueID = "main_menu"
-- disabled until we get to that mission
-- TUTORIAL.activateOn = "OnSpawnSelectSuccess"
-- TUTORIAL.activateOnDelay = 5
-- TUTORIAL.deactivateOn = "OnMainMenuCreated"

-- Don't activate unless the prologue is finished
function TUTORIAL:ShouldActivate()
	local client = LocalPlayer()
	local character = client:GetCharacter()

	if (character and not character:GetData("prologue_finished")) then
		return false
	end
end

function TUTORIAL:GetText()
	local menuKey = Schema.util.LookupBinding("+showscores") or "TAB"

	return {
		"Great! You've spawned in safely.",
		"Let's check how you're doing.",
		Schema.tutorial.ImportantText("Press " .. menuKey .. " once to open the main menu."),
	}
end
