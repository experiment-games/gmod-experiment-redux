local TUTORIAL = TUTORIAL

TUTORIAL.uniqueID = "final_tutorial"
TUTORIAL.activateOn = "OnPlayerItemRead"
TUTORIAL.Skippable = true

function TUTORIAL:OnActivate(item, frame)
	Schema.tutorial.item = item

	if (item.uniqueID ~= "tutorial") then
		return
	end

	timer.Simple(5, function()
		self:Deactivate()
	end)
end

function TUTORIAL:GetText()
	if (Schema.tutorial.item.uniqueID ~= "tutorial") then
		return {
			"That's not the right item.",
			Schema.tutorial.ImportantText("Right click the piece of paper named 'An Introduction' then select 'Read'."),
		}
	end

	return {
		"This should help you get started.",
		"Good luck!",
	}, ScrW() * .5, ScrH() * .5
end

function TUTORIAL:OnDeactivate()
	-- After the last one, disable the tutorial system
	Schema.tutorial.DisableTutorial()
end
