local ITEM = ITEM

ITEM.name = "Tomato Seeds"
ITEM.description = "Seeds for growing tomatoes."
ITEM.price = 50

ITEM.cropName = "Tomato Plant"
ITEM.stages = 3
ITEM.growthTime = 100
ITEM.harvestItems = 2
ITEM.plantingRadius = 30
ITEM.cropModel = "models/a31/fallout4/props/plants/tatoplant01.mdl"
ITEM.stageConfig = {
	[1] = { modelScale = 1.0, bodygroup = 1, skin = 1 },
	[2] = { modelScale = 1.0, bodygroup = 0, skin = 1 },
	[3] = { modelScale = 1.0, bodygroup = 0, skin = 1 }
}

ITEM.generateProductItem = {
	uniqueID = "tomato",
	name = "Tomato",
	description = "A ripe tomato harvested from your farm.",
	model = "models/a31/fallout4/props/plants/tato_item.mdl",
}
