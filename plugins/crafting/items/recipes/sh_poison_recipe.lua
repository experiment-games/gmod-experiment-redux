local ITEM = ITEM

ITEM.name = "Poisonous Acid Recipe"
ITEM.description = "Instructions for creating deadly poisonous acid from organic compounds."
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.category = "Recipes"
ITEM.width = 1
ITEM.height = 1
ITEM.noBusiness = true

ITEM.craftingCombination = {
	output = { poisonous_acid = 1 },
	components = { phenolic_acid = 2, ascorbic_acid = 1 },
	station = "exp_chemistry_station",
}

ITEM.craftingTime = 45
