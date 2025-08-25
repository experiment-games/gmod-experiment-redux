local ITEM = ITEM

ITEM.name = "Poisonous Acid Recipe"
ITEM.description = "Instructions for creating deadly poisonous acid from organic compounds."
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.category = "Recipes"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 750

ITEM.craftingCombination = {
	output = { poisonous_acid = 1 },
	components = { phenolic_acid = 3, ascorbic_acid = 1 }
}

ITEM.craftingTime = 45
