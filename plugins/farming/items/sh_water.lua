local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Water Bottle"
ITEM.description = "Clean water for hydrating crops and improving their growth."
ITEM.category = "Farming"
ITEM.model = "models/props/cs_office/water_bottle.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 15
ITEM.shipmentSize = 6
ITEM.requiresFarmingPerk = true

ITEM.functions.Water = {
	name = "Water",
	tip = "Water nearby crops.",
	icon = "icon16/water.png",
	OnRun = function(item)
		local client = item.player
		local trace = client:GetEyeTrace()

		return PLUGIN:WaterCrop(client, trace.HitPos)
	end,
	OnCanRun = function(item)
		return IsValid(item.player) and item.player:Alive() and Schema.perk.GetOwned("farmhand", item.player)
	end,
}
