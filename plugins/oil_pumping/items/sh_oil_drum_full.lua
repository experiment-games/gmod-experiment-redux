local ITEM = ITEM

ITEM.name = "Oil Drum (500L)"
ITEM.description = "A metal drum filled with 500 liters of crude oil. Heavy and valuable."
ITEM.model = "models/props_c17/oildrum001.mdl"
ITEM.skin = 1
ITEM.category = "Oil & Fuel"
ITEM.width = 2
ITEM.height = 2
ITEM.noBusiness = true

ITEM.functions.Empty = {
	name = "Empty Oil",
	tip = "Empty the oil from this drum.",
	icon = "icon16/cup.png",
	OnRun = function(item)
		local client = item.player
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		-- Give back empty drum
		if (inventory:Add("oil_drum_empty")) then
			client:Notify("You emptied the oil drum.")
			return true
		else
			client:Notify("No space in inventory for empty drum.")
			return false
		end
	end,
	OnCanRun = function(item)
		return IsValid(item.player) and item.player:Alive()
	end
}
