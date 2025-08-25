local ITEM = ITEM

ITEM.name = "Explosive Compound Recipe"
ITEM.description = "Dangerous instructions for creating explosive compounds. Handle with extreme care."
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.category = "Recipes"
ITEM.width = 1
ITEM.height = 1
ITEM.noBusiness = true

ITEM.craftingCombination = {
	output = { explosive_compound = 1 },
	components = { phenolic_acid = 1, ascorbic_acid = 1, poisonous_acid = 1 },
	station = "exp_chemistry_station",
}

ITEM.craftingTime = 60

function ITEM:GetCraftingOutputData(outputItemID)
	return {
		explosive_power = 150,
		blast_radius = 200
	}
end
