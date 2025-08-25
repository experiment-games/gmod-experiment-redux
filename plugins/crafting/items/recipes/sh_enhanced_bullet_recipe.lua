local ITEM = ITEM

ITEM.name = "Enhanced Ammunition Recipe"
ITEM.description = "Recipe for creating enhanced bullets with improved stopping power."
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.category = "Recipes"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 400

ITEM.craftingCombination = {
	output = { ammo_9x19mm_single = 1 },
	components = { ammo_9x19mm_single = 1, healing_compound = 1 },
	station = "exp_workbench",
}

ITEM.craftingTime = 20

function ITEM:GetCraftingOutputData(outputItemID)
	return {
		enhanced = true,
		damage_multiplier = 1.5
	}
end
