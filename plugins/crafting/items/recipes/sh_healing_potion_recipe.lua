local ITEM = ITEM

ITEM.name = "Healing Potion Recipe"
ITEM.description = "A recipe for creating powerful healing compounds from basic chemicals."
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.category = "Recipes"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 300

ITEM.craftingCombination = {
	output = { healing_compound = 2 },
	components = { phenolic_acid = 1, ascorbic_acid = 2 },
	station = "exp_chemistry_station",
}

ITEM.craftingTime = 30
