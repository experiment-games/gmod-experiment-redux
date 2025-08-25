local ITEM = ITEM

ITEM.name = "Explosive Ammunition Recipe"
ITEM.description = "Recipe for creating explosive bullets."
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.category = "Recipes"
ITEM.width = 1
ITEM.height = 1
ITEM.noBusiness = true

ITEM.craftingCombination = {
	output = { ammo_9x19mm_single = 1 },
	components = { ammo_9x19mm_single = 1, explosive_compound = 1 },
	station = "exp_workbench",
}

ITEM.craftingTime = 20

function ITEM:GetCraftingOutputData(outputItemID)
	return {
		explosive = true,
		blastRadius = 200,
		blastDamage = 30,
	}
end
