local ITEM = ITEM

ITEM.name = "Melon Seeds"
ITEM.description = "Seeds for growing melons."
ITEM.price = 50

ITEM.cropName = "Melon Vine"
ITEM.stages = 4
ITEM.growthTime = 150
ITEM.harvestItems = 2
ITEM.plantingRadius = 60
ITEM.cropModel = "models/a31/fallout4/props/plants/melon_vine.mdl"
ITEM.stageConfig = {
	[1] = { modelScale = 1.0, bodygroup = 1, skin = 1, rotChance = 0 },
	[2] = { modelScale = 1.0, bodygroup = 1, skin = 1, rotChance = 5 },
	[3] = { modelScale = 1.0, bodygroup = 0, skin = 1, rotChance = 10 },
	[4] = { modelScale = 1.0, bodygroup = 0, skin = 1, model = "models/a31/fallout4/props/plants/melon_vinefull.mdl", rotChance = 20 }
}

ITEM.generateProductItem = {
	uniqueID = "melon",
	name = "Melon",
	description = "A juicy melon harvested from your farm.",
	model = "models/a31/fallout4/props/plants/melon_item.mdl",
	skin = 1,
}

ITEM.generateRottenItem = {
	uniqueID = "rotten_melon",
	name = "Rotten Melon",
	description = "A rotten melon that is no longer usable.",
	model = "models/a31/fallout4/props/plants/melon_item.mdl",
	skin = 0
}
