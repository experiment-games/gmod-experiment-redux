local ITEM = ITEM

ITEM.name = "Carrot Seeds"
ITEM.description = "Seeds for growing carrots."
ITEM.price = 50

ITEM.cropName = "Carrot Roots"
ITEM.stages = 3
ITEM.growthTime = 120
ITEM.harvestItems = 1
ITEM.plantingRadius = 10
ITEM.cropModel = "models/a31/fallout4/props/plants/carrot.mdl"
ITEM.stageConfig = {
	[1] = { modelScale = 0.5, bodygroup = nil, skin = 1 },
	[2] = { modelScale = 0.75, bodygroup = nil, skin = 1 },
	[3] = { modelScale = 1.0, bodygroup = nil, skin = 1 }
}

ITEM.generateProductItem = {
	uniqueID = "carrot",
	name = "Carrot",
	description = "A fresh carrot harvested from your farm.",
	model = "models/a31/fallout4/props/plants/carrot_item.mdl",
}
