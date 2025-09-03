local PLUGIN = PLUGIN

PLUGIN.name = "Dog Companions"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Adds dog companions to the game."

if (SERVER) then
	--- Fallout Dogs (https://steamcommunity.com/sharedfiles/filedetails/?id=1135558573)
	resource.AddWorkshop("1135558573")
end
