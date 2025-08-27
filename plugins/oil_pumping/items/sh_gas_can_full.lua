local ITEM = ITEM

ITEM.name = "Gas Can (50L)"
ITEM.description =
"A metal gas can filled with 50 liters of crude oil. Perfect for small-scale operations or personal use."
ITEM.model = "models/props_junk/metalgascan.mdl"
ITEM.skin = 0
ITEM.category = "Oil & Fuel"
ITEM.width = 1
ITEM.height = 2
ITEM.noBusiness = true

ITEM.functions.Empty = {
	name = "Empty Oil",
	tip = "Empty the oil from this gas can.",
	icon = "icon16/cup.png",
	OnRun = function(item)
		local client = item.player
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		-- Give back empty gas can
		if (inventory:Add("gas_can_empty")) then
			client:Notify("You emptied the gas can.")
			return true
		else
			client:Notify("No space in inventory for empty gas can.")
			return false
		end
	end,
	OnCanRun = function(item)
		return IsValid(item.player) and item.player:Alive()
	end
}
