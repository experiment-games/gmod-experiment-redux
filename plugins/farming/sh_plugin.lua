local PLUGIN = PLUGIN

PLUGIN.name = "Farming"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Adds crops and farming mechanics."

PLUGIN.largestPlantingRadius = 0

ix.lang.AddTable("english", {
	cropStage = "Stage: ",
})

if (SERVER) then
	-- Fallout 4: Crop Plants (https://steamcommunity.com/sharedfiles/filedetails/?id=1864310649)
	resource.AddWorkshop("1864310649")

	ix.util.AddResourceFile("materials/experiment-redux/icons/plant.png")
	ix.util.AddResourceFile("materials/experiment-redux/icons/water.png")
	ix.util.AddResourceFile("materials/experiment-redux/icons/fertilizer.png")
	ix.util.AddResourceFile("materials/experiment-redux/icons/harvest.png")
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
	Auto-generate seed items for all crop items
--]]

function PLUGIN:InitializedPlugins()
	local items = ix.item.list

	-- Build crop config from crop items
	for _, item in pairs(items) do
		local productInfo = item.generateProductItem

		if (item.base ~= "base_crop_seeds" or not productInfo) then
			continue
		end

		if (not productInfo.name or not productInfo.description or not productInfo.model) then
			local missingFields = {}

			if (not productInfo.name) then
				table.insert(missingFields, "name")
			end

			if (not productInfo.description) then
				table.insert(missingFields, "description")
			end

			if (not productInfo.model) then
				table.insert(missingFields, "model")
			end

			ix.util.SchemaErrorNoHalt(
				string.format("Farming plugin: Crop seed item '%s' is missing fields: %s",
					item.uniqueID,
					table.concat(missingFields, ", ")
				)
			)
			continue
		end

		local productItemID = productInfo.uniqueID
		local productItem = ix.item.Register(productItemID, "base_crops", false, nil, true)
		productItem.name = productInfo.name
		productItem.description = productInfo.description
		productItem.model = productInfo.model
		productItem.width = 1
		productItem.height = 1
		productItem.modelScale = productInfo.modelScale

		if (productItem.modelScale) then
			function productItem:OnEntityCreated(entity)
				entity:SetModelScale(self.modelScale)
			end
		end

		-- Place a reference to the product item in the seed item and vice versa
		item.productItemID = productItem.uniqueID
		productItem.seedItemID = item.uniqueID

		-- Track the largest planting radius
		self.largestPlantingRadius = math.max(self.largestPlantingRadius, item.plantingRadius)
	end
end

--[[
	Crop interaction functions
--]]

function PLUGIN:WaterSpecificCrop(crop)
	if (crop:CanHarvest()) then
		return false, "No need to water a fully grown crop."
	end

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
	if (crop:CanHarvest()) then
		return false, "No need to fertilize a fully grown crop."
	end

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

function PLUGIN:IsValidCropSoil(position, resourceTypeID)
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
