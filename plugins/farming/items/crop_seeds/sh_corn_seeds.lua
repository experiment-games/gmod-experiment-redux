local ITEM = ITEM

ITEM.name = "Corn Seeds"
ITEM.description = "Seeds for growing corn."
ITEM.price = 50

ITEM.cropName = "Corn Stalk"
ITEM.stages = 4
ITEM.growthTime = 180
ITEM.harvestItems = 3
ITEM.plantingRadius = 60
ITEM.cropModel = "models/a31/fallout4/props/plants/corn_stalk01.mdl"
ITEM.stageConfig = {
	[1] = { modelScale = 0.6, bodygroup = 2, skin = 1 },
	[2] = { modelScale = 0.8, bodygroup = 2, skin = 1 },
	[3] = { modelScale = 1.0, bodygroup = 1, skin = 1 },
	[4] = { modelScale = 1.0, bodygroup = 0, skin = 1 }
}

ITEM.generateProductItem = {
	uniqueID = "corn",
	name = "Corn",
	description = "Fresh corn harvested from your farm.",
	model = "models/a31/fallout4/props/plants/corn_item.mdl",
}
