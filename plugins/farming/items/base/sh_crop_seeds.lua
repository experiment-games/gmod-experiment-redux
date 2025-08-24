local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Jar of Seeds"
ITEM.model = Model("models/props_lab/jar01b.mdl")
ITEM.category = "Farming"
ITEM.width = 1
ITEM.height = 1
ITEM.description = "A jar filled with seeds."

-- Crop configuration properties
ITEM.stages = 3                     -- Number of growth stages
ITEM.growthTime = 120               -- Seconds per stage
ITEM.harvestItems = 1               -- Number of items harvested
ITEM.plantingRadius = 10            -- Minimum distance between crops
ITEM.cropModel = "models/error.mdl" -- Model used for the growing crop

-- Stage configuration - array of stage definitions
-- Each stage can have: modelScale, bodygroup, skin, model (optional override), rotChance
ITEM.stageConfig = {
	[1] = { modelScale = 0.5, bodygroup = nil, skin = 1, rotChance = 5 }, -- 5% chance to rot
	[2] = { modelScale = 0.75, bodygroup = nil, skin = 1, rotChance = 10 }, -- 10% chance to rot
	[3] = { modelScale = 1.0, bodygroup = nil, skin = 1, rotChance = 15 } -- 15% chance to rot
}

function ITEM:GetCropName()
	return self.cropName or string.format("Growing %s", self.name)
end

function ITEM:GetProductItemID()
	-- This is set in sh_plugin.lua
	return self.productItemID
end

function ITEM:GetProductItemTable()
	return ix.item.list[self:GetProductItemID()]
end

function ITEM:GetRottenItemID()
	-- This is set in sh_plugin.lua
	return self.rottenItemID
end

function ITEM:GetRottenItemTable()
	return ix.item.list[self:GetRottenItemID()]
end

function ITEM:GetStages()
	return self.stages
end

function ITEM:GetGrowthTime()
	return self.growthTime
end

function ITEM:GetHarvestItems()
	return self.harvestItems
end

function ITEM:GetPlantingRadius()
	return self.plantingRadius
end

function ITEM:GetCropModel()
	return self.cropModel
end

function ITEM:GetStageConfig(stage)
	return self.stageConfig[stage]
end

ITEM.functions.Plant = {
	name = "Plant",
	tip = "Plant these seeds in the ground.",
	icon = "experiment-redux/icons/silk_plant.png",
	OnRun = function(item)
		local client = item.player
		local trace = client:GetEyeTrace()

		if (trace.HitPos:DistToSqr(client:GetPos()) > ix.config.Get("maxInteractionDistance") ^ 2) then
			client:Notify("You're too far away to plant seeds there.")
			return false
		end

		if (not PLUGIN:IsValidCropSoil(trace.HitPos)) then
			client:Notify("You can only plant seeds in farming soils.")
			return false
		end

		-- Check if there's already a crop nearby and we can place nearby it
		for _, ent in ipairs(ents.FindInSphere(trace.HitPos, PLUGIN.largestPlantingRadius)) do
			if (ent:GetClass() == "exp_crop") then
				local seedItem = ent:GetItemTable()

				if (seedItem and trace.HitPos:DistToSqr(ent:GetPos()) < (seedItem:GetPlantingRadius() ^ 2)) then
					client:Notify(
						string.format(
							"Can't plant here, because there's already a %s growing too close.",
							seedItem:GetCropName()
						)
					)
					return false
				end
			end
		end

		-- Create the crop entity
		local crop = ents.Create("exp_crop")
		crop:SetPos(trace.HitPos)
		crop:SetItemID(item.uniqueID)
		crop:Spawn()

		client:Notify("You planted " .. item.name .. "!")
	end,
	OnCanRun = function(item)
		return IsValid(item.player) and item.player:Alive()
	end,
}
