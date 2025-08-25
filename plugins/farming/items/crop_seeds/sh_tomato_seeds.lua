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
	[1] = { modelScale = 1.0, bodygroup = 1, skin = 1, rotChance = 0 },
	[2] = { modelScale = 1.0, bodygroup = 0, skin = 1, rotChance = 10 },
	[3] = { modelScale = 1.0, bodygroup = 0, skin = 1, rotChance = 15 }
}

ITEM.generateProductItem = {
	uniqueID = "tomato",
	name = "Tomato",
	description = "A ripe tomato harvested from your farm.",
	model = "models/a31/fallout4/props/plants/tato_item.mdl",

	-- Distillation configuration
	craftingDistillation = {
		time = 90,           -- 90 seconds to distill
		output = {
			ascorbic_acid = { 1, 3 }, -- Random 1-3 ascorbic acid
			phenolic_acid = 1 -- Always 1 phenolic acid
		}
	}
}

ITEM.generateRottenItem = {
	uniqueID = "rotten_tomato",
	name = "Rotten Tomato",
	description = "A rotten tomato that is no longer usable.",
	model = "models/a31/fallout4/props/plants/mutfruit_item.mdl",
}
