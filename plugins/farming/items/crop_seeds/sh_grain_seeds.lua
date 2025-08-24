local ITEM = ITEM

ITEM.name = "Grain Seeds"
ITEM.description = "Seeds for growing nutritious grain."
ITEM.price = 50

ITEM.cropName = "Grain Stalk"
ITEM.stages = 4
ITEM.growthTime = 200
ITEM.harvestItems = 4
ITEM.plantingRadius = 100
ITEM.cropModel = "models/a31/fallout4/props/plants/razorgrain_pile.mdl"

ITEM.stageConfig = {
	[1] = { modelScale = 1.0, bodygroup = 3, skin = 1 },
	[2] = { modelScale = 1.0, bodygroup = 2, skin = 1 },
	[3] = { modelScale = 1.0, bodygroup = 1, skin = 1 },
	[4] = { modelScale = 1.0, bodygroup = 0, skin = 1 }
}

ITEM.generateProductItem = {
	uniqueID = "grain",
	name = "Grain",
	description = "Nutritious grain harvested from your farm.",
	model = "models/props/de_dust/grainbasket01b.mdl",
	modelScale = 0.5,
}
