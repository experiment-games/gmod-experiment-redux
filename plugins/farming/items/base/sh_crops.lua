local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Crop"
ITEM.model = "models/error.mdl"
ITEM.category = "Farming"
ITEM.width = 1
ITEM.height = 1
ITEM.description = "A harvested crop."
ITEM.noBusiness = true

function ITEM:GetSeedItemID()
	-- This is set in sh_plugin.lua
	return self.seedItemID
end
