local PLUGIN = PLUGIN

PLUGIN.name = "Grenades"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Adds flash, smoke, tear gas, and flare grenades."

function PLUGIN:CanPlayerUseBusiness(client, uniqueID)
	local itemTable = ix.item.list[uniqueID]

	if (itemTable.requiresExplosives and not Schema.perk.GetOwned("explosives", client)) then
		return false
	end
end
