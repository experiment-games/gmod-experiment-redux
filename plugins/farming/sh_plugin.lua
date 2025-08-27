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

	ix.util.AddResourceFile("materials/experiment-redux/icons/silk_plant.png")
	ix.util.AddResourceFile("materials/experiment-redux/icons/silk_fertilize.png")

	ix.util.AddResourceFile("materials/experiment-redux/icons/plant.png")
	ix.util.AddResourceFile("materials/experiment-redux/icons/water.png")
	ix.util.AddResourceFile("materials/experiment-redux/icons/fertilizer.png")
	ix.util.AddResourceFile("materials/experiment-redux/icons/harvest.png")
	ix.util.AddResourceFile("materials/experiment-redux/icons/rotten.png")
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
	Hooks
--]]

function PLUGIN:CanPlayerUseBusiness(client, uniqueID)
	local itemTable = ix.item.list[uniqueID]

	if (itemTable.requiresFarmingPerk and not Schema.perk.GetOwned("farmhand", client)) then
		return false
	end
end

-- Auto-generate seed items for all crop items on initialization
function PLUGIN:InitializedPlugins()
	local items = ix.item.list

	-- Build crop config from crop items
	for _, item in pairs(items) do
		local productInfo = item.generateProductItem
		local rottenInfo = item.generateRottenItem

		if (item.base ~= "base_crop_seeds" or not productInfo) then
			local productItemID = item.productItemID

			if (productItemID) then
				local productItem = ix.item.list[productItemID]

				if (productItem) then
					productItem.seedItemID = item.uniqueID
				end
			end

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

		-- Create product item
		local productItemID = productInfo.uniqueID
		local productItem = ix.item.Register(productItemID, "base_crops", false, nil, true)
		productItem.name = productInfo.name
		productItem.description = productInfo.description
		productItem.model = productInfo.model
		productItem.skin = productInfo.skin
		productItem.width = 1
		productItem.height = 1

		for k, v in pairs(productInfo) do
			productItem[k] = v
		end

		if (productItem.modelScale) then
			function productItem:OnEntityCreated(entity)
				entity:SetModelScale(self.modelScale)
			end
		end

		-- Create rotten item if specified
		local rottenItemID = nil
		if (rottenInfo) then
			if (not rottenInfo.name or not rottenInfo.description or not rottenInfo.model) then
				local missingRottenFields = {}

				if (not rottenInfo.name) then
					table.insert(missingRottenFields, "name")
				end

				if (not rottenInfo.description) then
					table.insert(missingRottenFields, "description")
				end

				if (not rottenInfo.model) then
					table.insert(missingRottenFields, "model")
				end

				ix.util.SchemaErrorNoHalt(
					string.format("Farming plugin: Crop seed item '%s' rotten item is missing fields: %s",
						item.uniqueID,
						table.concat(missingRottenFields, ", ")
					)
				)
			else
				rottenItemID = rottenInfo.uniqueID
				local rottenItem = ix.item.Register(rottenItemID, "base_crops", false, nil, true)
				rottenItem.name = rottenInfo.name
				rottenItem.description = rottenInfo.description
				rottenItem.model = rottenInfo.model
				rottenItem.skin = rottenInfo.skin
				rottenItem.width = 1
				rottenItem.height = 1

				for k, v in pairs(rottenInfo) do
					rottenItem[k] = v
				end

				if (rottenItem.modelScale) then
					function rottenItem:OnEntityCreated(entity)
						entity:SetModelScale(self.modelScale)
						-- Set rotten skin if specified
						if (rottenInfo.skin ~= nil) then
							entity:SetSkin(rottenInfo.skin)
						end
					end
				else
					function rottenItem:OnEntityCreated(entity)
						-- Set rotten skin if specified
						if (rottenInfo.skin ~= nil) then
							entity:SetSkin(rottenInfo.skin)
						end
					end
				end

				-- Place a reference to the seed item in the rotten item
				rottenItem.seedItemID = item.uniqueID
			end
		end

		-- Place references between items
		item.productItemID = productItem.uniqueID
		productItem.seedItemID = item.uniqueID

		if (rottenItemID) then
			item.rottenItemID = rottenItemID
		end

		-- Track the largest planting radius
		self.largestPlantingRadius = math.max(self.largestPlantingRadius, item.plantingRadius)
	end
end

--[[
	Crop interaction functions
--]]

function PLUGIN:WaterSpecificCrop(crop)
	if (crop:GetIsRotten()) then
		return false, "Cannot water a rotten crop."
	end

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
	if (crop:GetIsRotten()) then
		return false, "Cannot fertilize a rotten crop."
	end

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

function PLUGIN:PreventCropRotSpecific(crop)
	if (crop:GetIsRotten()) then
		return false, "This crop is already rotten."
	end

	if (crop.rotPrevented) then
		return false, "This crop already has rot prevention applied."
	end

	crop.rotPrevented = true

	-- Create prevention effect
	local effectData = EffectData()
	effectData:SetOrigin(crop:GetPos() + Vector(0, 0, 15))
	effectData:SetScale(0.3)
	util.Effect("GlassImpact", effectData)

	return true, "You applied rot prevention to the crop. It won't rot anymore!"
end

function PLUGIN:PreventCropRot(client, target)
	if (target:DistToSqr(client:GetPos()) > ix.config.Get("maxInteractionDistance") ^ 2) then
		client:Notify("You're too far away to apply rot prevention.")
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
		local success, message = self:PreventCropRotSpecific(nearestCrop)

		client:Notify(message)
		return success
	else
		client:Notify("No crops found nearby to apply rot prevention.")
		return false
	end
end

function PLUGIN:CureCropRotSpecific(crop)
	if (not crop:GetIsRotten()) then
		return false, "This crop is not rotten."
	end

	if (crop:CureRot()) then
		-- Create cure effect
		local effectData = EffectData()
		effectData:SetOrigin(crop:GetPos() + Vector(0, 0, 15))
		effectData:SetScale(0.5)
		util.Effect("Sparks", effectData)

		return true, "You cured the crop's rot! It will continue growing."
	else
		return false, "Failed to cure the crop's rot."
	end
end

function PLUGIN:CureCropRot(client, target)
	if (target:DistToSqr(client:GetPos()) > ix.config.Get("maxInteractionDistance") ^ 2) then
		client:Notify("You're too far away to apply rot cure.")
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
		local success, message = self:CureCropRotSpecific(nearestCrop)

		client:Notify(message)
		return success
	else
		client:Notify("No crops found nearby to cure.")
		return false
	end
end

function PLUGIN:IsValidCropSoil(trace, resourceTypeID)
	if (IsValid(trace.Entity) and trace.Entity.ValidSoilFor == resourceTypeID) then
		return true
	end

	local position = trace.HitPos
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
