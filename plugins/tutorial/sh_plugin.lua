local PLUGIN = PLUGIN

PLUGIN.name = "Tutorial"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Introduce new players to the server."

ix.lang.AddTable("english", {
	optShowTutorial = "Show Tutorial",
	optdShowTutorial = "Show the tutorial hints, intended for new players.",
})

ix.util.Include("cl_plugin.lua")

if (not SERVER) then
	return
end

ix.util.AddResourceFile("materials/experiment-redux/illustrations/apartment.png")
ix.util.AddResourceFile("materials/experiment-redux/illustrations/death.png")
ix.util.AddResourceFile("materials/experiment-redux/illustrations/generator.png")
ix.util.AddResourceFile("materials/experiment-redux/illustrations/gradient.png")
ix.util.AddResourceFile("materials/experiment-redux/illustrations/lockers.png")
ix.util.AddResourceFile("materials/experiment-redux/illustrations/raiding.png")
ix.util.AddResourceFile("materials/experiment-redux/illustrations/scavenging.png")
ix.util.AddResourceFile("materials/experiment-redux/illustrations/the-business.png")
ix.util.AddResourceFile("materials/experiment-redux/illustrations/vignette.png")

function PLUGIN:PlayerFillDefaultInventory(client, character, inventory)
	inventory:Add("tutorial", 1)
end
