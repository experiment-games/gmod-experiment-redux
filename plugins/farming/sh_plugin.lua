local PLUGIN = PLUGIN

PLUGIN.name = "Farming"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Adds crops and farming mechanics."

if (SERVER) then
	-- Fallout 4: Crop Plants (https://steamcommunity.com/sharedfiles/filedetails/?id=1864310649)
	resource.AddWorkshop("1864310649")
end

--[[
	For all except the marked models they all have these skins:
		0 - Rotten
		1 - Fresh

	Carrot
	crop: models/a31/fallout4/props/plants/carrot.mdl
		(should grow in size with model size for all stages)
	item: models/a31/fallout4/props/plants/carrot_item.mdl

	Corn:
	crop: models/a31/fallout4/props/plants/corn_stalk01.mdl
		- bodygroups:
			2 small (should grow with model size for first 2 stages)
			1 growing (then transition to this)
			0 ripe (then this for 1 stage, then attach the corn items)
	item: models/a31/fallout4/props/plants/corn_item.mdl

	Melon:
	crop:
		growing: models/a31/fallout4/props/plants/melon_vine.mdl
		- bodygroups:
			1 few leaves
			0 many leaves (should have this for last 2 stages)

		ripe: models/a31/fallout4/props/plants/melon_vinefull.mdl
	item: models/a31/fallout4/props/plants/melon_item.mdl

	Tomato:
	crop: models/a31/fallout4/props/plants/tatoplant01.mdl
	- bodygroups:
		1 small
		0 grown (should have this for last 2 stages, then attach the tomato items)
	item: models/a31/fallout4/props/plants/tato_item.mdl

	Grain:
	crop: models/a31/fallout4/props/plants/razorgrain_pile.mdl
	- bodygroups
		3 small
		2 medium
		1 large
		0 grown
	item: models/props/de_dust/grainbasket01b.mdl (should be scaled to 0.5 its size)
--]]

--[[
	Crop configuration
--]]

PLUGIN.cropConfig = {
	carrot = {
		name = "Carrot",
		stages = 3,
		growthTime = 120, -- seconds per stage
		harvestItems = 1,
		plantingRadius = 10,
		cropModel = "models/a31/fallout4/props/plants/carrot.mdl",
		itemModel = "models/a31/fallout4/props/plants/carrot_item.mdl",
		stageConfig = {
			[1] = { modelScale = 0.5, bodygroup = nil, skin = 1 },
			[2] = { modelScale = 0.75, bodygroup = nil, skin = 1 },
			[3] = { modelScale = 1.0, bodygroup = nil, skin = 1 }
		}
	},
	corn = {
		name = "Corn",
		stages = 4,
		growthTime = 180,
		harvestItems = 3,
		plantingRadius = 60,
		cropModel = "models/a31/fallout4/props/plants/corn_stalk01.mdl",
		itemModel = "models/a31/fallout4/props/plants/corn_item.mdl",
		stageConfig = {
			[1] = { modelScale = 0.6, bodygroup = 2, skin = 1 },
			[2] = { modelScale = 0.8, bodygroup = 2, skin = 1 },
			[3] = { modelScale = 1.0, bodygroup = 1, skin = 1 },
			[4] = { modelScale = 1.0, bodygroup = 0, skin = 1 }
		}
	},
	melon = {
		name = "Melon",
		stages = 4,
		growthTime = 150,
		harvestItems = 2,
		plantingRadius = 60,
		cropModel = "models/a31/fallout4/props/plants/melon_vine.mdl",
		itemModel = "models/a31/fallout4/props/plants/melon_item.mdl",
		stageConfig = {
			[1] = { modelScale = 1.0, bodygroup = 1, skin = 1 },
			[2] = { modelScale = 1.0, bodygroup = 1, skin = 1 },
			[3] = { modelScale = 1.0, bodygroup = 0, skin = 1 },
			[4] = { modelScale = 1.0, bodygroup = 0, skin = 1, model = "models/a31/fallout4/props/plants/melon_vinefull.mdl" }
		}
	},
	tomato = {
		name = "Tomato",
		stages = 3,
		growthTime = 100,
		harvestItems = 2,
		plantingRadius = 30,
		cropModel = "models/a31/fallout4/props/plants/tatoplant01.mdl",
		itemModel = "models/a31/fallout4/props/plants/tato_item.mdl",
		stageConfig = {
			[1] = { modelScale = 1.0, bodygroup = 1, skin = 1 },
			[2] = { modelScale = 1.0, bodygroup = 0, skin = 1 },
			[3] = { modelScale = 1.0, bodygroup = 0, skin = 1 }
		}
	},
	grain = {
		name = "Grain",
		stages = 4,
		growthTime = 200,
		harvestItems = 4,
		plantingRadius = 100,
		cropModel = "models/a31/fallout4/props/plants/razorgrain_pile.mdl",
		itemModel = "models/props/de_dust/grainbasket01b.mdl",
		itemModelScale = 0.5,
		stageConfig = {
			[1] = { modelScale = 1.0, bodygroup = 3, skin = 1 },
			[2] = { modelScale = 1.0, bodygroup = 2, skin = 1 },
			[3] = { modelScale = 1.0, bodygroup = 1, skin = 1 },
			[4] = { modelScale = 1.0, bodygroup = 0, skin = 1 }
		}
	}
}

function PLUGIN:GetCropConfig(cropType)
	return self.cropConfig[cropType]
end

--[[
	Crop interaction functions
--]]

function PLUGIN:WaterSpecificCrop(crop)
	if (crop:GetIsWatered()) then
		return false, "This crop has already been watered."
	end

	crop:SetWatered(true)
	crop:StartGrowthTimer()

	-- Create water effect
	local effectData = EffectData()
	effectData:SetOrigin(crop:GetPos() + Vector(0, 0, 10))
	effectData:SetScale(0.5)
	util.Effect("WaterSplash", effectData)

	return true, "You watered the crop. It will grow faster for a while!"
end

function PLUGIN:WaterCrop(client, target)
	if (isentity(target)) then
		local success, message = self:WaterSpecificCrop(target)

		client:Notify(message)
		return success
	end

	if (target:DistToSqr(client:GetPos()) > ix.config.Get("maxInteractionDistance") ^ 2) then
		client:Notify("You're too far away to water these crops.")
		return false
	end

	-- Find nearby crops
	local nearestCrop = nil
	local nearestDist = math.huge

	for _, ent in pairs(ents.FindInSphere(target, 50)) do
		if (ent:GetClass() == "exp_crop") then
			local dist = ent:GetPos():Distance(target)
			if (dist < nearestDist) then
				nearestDist = dist
				nearestCrop = ent
			end
		end
	end

	if (not IsValid(nearestCrop)) then
		client:Notify("No crops found nearby to water.")
		return false
	end

	local success, message = self:WaterSpecificCrop(nearestCrop)

	client:Notify(message)
	return success
end

function PLUGIN:FertilizeSpecificCrop(crop)
	if (crop:GetIsFertilized()) then
		return false, "This crop has already been fertilized."
	end

	crop:SetFertilized(true)
	crop:StartGrowthTimer()

	-- Create fertilizer effect
	local effectData = EffectData()
	effectData:SetOrigin(crop:GetPos())
	util.Effect("ThumperDust", effectData)

	return true, "You applied fertilizer to the crop. It will grow faster now!"
end

function PLUGIN:FertilizeCrop(client, target)
	if (isentity(target)) then
		local success, message = self:FertilizeSpecificCrop(target)

		client:Notify(message)
		return success
	end

	if (target:DistToSqr(client:GetPos()) > ix.config.Get("maxInteractionDistance") ^ 2) then
		client:Notify("You're too far away to apply fertilizer.")
		return false
	end

	-- Find nearby crops
	local nearestCrop = nil
	local nearestDist = math.huge

	for _, ent in pairs(ents.FindInSphere(target, 50)) do
		if (ent:GetClass() == "exp_crop") then
			local dist = ent:GetPos():Distance(target)
			if (dist < nearestDist) then
				nearestDist = dist
				nearestCrop = ent
			end
		end
	end

	if (IsValid(nearestCrop)) then
		local success, message = self:FertilizeSpecificCrop(nearestCrop)

		client:Notify(message)
		return success
	else
		client:Notify("No crops found nearby to fertilize.")
		return false
	end
end

--[[
	Items
--]]

-- Create seed items
for cropType, config in pairs(PLUGIN.cropConfig) do
	local ITEM = ix.item.Register("seeds_" .. cropType, "base_crop_seed", false, nil, true)
	ITEM.name = config.name .. " Seeds"
	ITEM.description = "Seeds for growing " .. config.name .. "s. Plant these on designated farming areas."
	ITEM.model = "models/props_lab/jar01b.mdl"
	ITEM.width = 1
	ITEM.height = 1
	ITEM.cropType = cropType
end

-- Create crop items (harvestable products)
for cropType, config in pairs(PLUGIN.cropConfig) do
	local ITEM = ix.item.Register(cropType, nil, false, nil, true)
	ITEM.name = config.name
	ITEM.description = "A fresh " .. string.lower(config.name) .. " harvested from your farm."
	ITEM.category = "Farming"
	ITEM.model = config.itemModel
	ITEM.width = 1
	ITEM.height = 1

	if (config.itemModelScale) then
		function ITEM:OnEntityCreated(entity)
			entity:SetModelScale(config.itemModelScale)
		end
	end
end

function PLUGIN:CheckValidGround(position, resourceTypeID)
	local triggers = ents.FindInSphere(position, 512)

	resourceTypeID = resourceTypeID or "crops"

	for _, trigger in ipairs(triggers) do
		if (IsValid(trigger) and trigger:GetClass() == "exp_resource_area") then
			local mins, maxs = trigger:GetCollisionBounds()
			local triggerMins = trigger:GetPos() + mins
			local triggerMaxs = trigger:GetPos() + maxs

			-- Check if crop is inside trigger bounds
			if (position.x >= triggerMins.x and position.x <= triggerMaxs.x and
					position.y >= triggerMins.y and position.y <= triggerMaxs.y and
					position.z >= triggerMins.z and position.z <= triggerMaxs.z) then
				if (trigger:GetResourceTypeID() == resourceTypeID) then
					return true
				end
			end
		end
	end

	return false
end
