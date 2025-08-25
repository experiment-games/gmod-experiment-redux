local ITEM = ITEM

ITEM.name = "Poisoned Ammunition Recipe"
ITEM.description = "Instructions for creating poisoned bullets using toxic compounds."
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.category = "Recipes"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 500

ITEM.craftingCombination = {
	output = { ammo_9x19mm_single = 1 },
	components = { ammo_9x19mm_single = 1, poisonous_acid = 1 },
	station = "exp_workbench",
}

ITEM.craftingTime = 15

function ITEM:GetCraftingOutputData(outputItemID)
	return {
		poisoned = true,
		poisonDamage = 25
	}
end
