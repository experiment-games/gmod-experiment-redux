local PLUGIN = PLUGIN

include("shared.lua")

ENT.PopulateEntityInfo = true

local iconHarvest = ix.util.GetMaterial("experiment-redux/icons/harvest.png")
local iconWater = ix.util.GetMaterial("experiment-redux/icons/water.png")
local iconFertilizer = ix.util.GetMaterial("experiment-redux/icons/fertilizer.png")
local iconRotten = ix.util.GetMaterial("experiment-redux/icons/rotten.png")

local iconHarvestAspect = iconHarvest:Width() / iconHarvest:Height()
local iconWaterAspect = iconWater:Width() / iconWater:Height()
local iconFertilizerAspect = iconFertilizer:Width() / iconFertilizer:Height()
local iconRottenAspect = iconRotten:Width() / iconRotten:Height()

function ENT:OnPopulateEntityInfo(tooltip)
	local seedItem = self:GetItemTable()
	local cropName = seedItem:GetCropName()

	-- Crop name
	local name = tooltip:AddRow("name")
	name:SetImportant()
	name:SetText(cropName)
	name:SizeToContents()

	-- Growth stage
	local maxStages = seedItem:GetStages()

	local stageBar = tooltip:Add("expProgressBar")
	stageBar:SetValue(function()
		if (not IsValid(self)) then
			return 0
		end

		return self:GetCropStage()
	end)
	stageBar:SetMaxValue(maxStages)
	stageBar:SetPrefix(L("cropStage"))
	stageBar:Dock(BOTTOM)

	-- Growth status
	local statusRow = tooltip:AddRow("status")
	if (self:GetIsRotten()) then
		statusRow:SetText("Rotten!")
		statusRow:SetTextColor(Color(150, 50, 50))
	elseif (self:GetCropStage() >= maxStages) then
		statusRow:SetText("Ready to Harvest!")
		statusRow:SetTextColor(Color(100, 255, 100))
	else
		statusRow:SetText("Growing...")
		statusRow:SetTextColor(Color(200, 200, 100))
	end
	statusRow:SizeToContents()

	-- Water status with icon
	if (self:GetIsWatered()) then
		local waterRow = tooltip:Add("expIconText")
		waterRow:SetText("Watered")
		waterRow:SetTextColor(Color(100, 150, 255))
		waterRow:SetIcon("experiment-redux/icons/water.png")
		waterRow:SizeToContents()
		waterRow:Dock(BOTTOM)
	end

	-- Fertilizer status with icon
	if (self:GetIsFertilized()) then
		local fertRow = tooltip:Add("expIconText")
		fertRow:SetText("Fertilized")
		fertRow:SetTextColor(Color(100, 255, 100))
		fertRow:SetIcon("experiment-redux/icons/fertilizer.png")
		fertRow:SizeToContents()
		fertRow:Dock(BOTTOM)
	end

	-- Rotten status with icon
	if (self:GetIsRotten()) then
		local rottenRow = tooltip:Add("expIconText")
		rottenRow:SetText("Rotten")
		rottenRow:SetTextColor(Color(150, 50, 50))
		rottenRow:SetIcon("experiment-redux/icons/rotten.png")
		rottenRow:SizeToContents()
		rottenRow:Dock(BOTTOM)
	end
end

function ENT:Draw()
	self:DrawModel()

	-- Draw status icons above the crop
	local pos = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 15)
	local distance = LocalPlayer():GetPos():Distance(self:GetPos())

	if (distance > 200) then
		return
	end

	local iconSize = 32
	local iconPadding = 8
	local maxAlpha = 80

	local alpha = math.max(0, maxAlpha - (distance / 200) * maxAlpha)

	cam.Start3D2D(pos, Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.25)

	local seedItem = self:GetItemTable()

	-- Determine which icons to show and calculate total width
	local iconsToShow = {}
	local totalWidth = 0

	if (self:GetIsRotten()) then
		-- Rotten icon
		table.insert(iconsToShow, {
			material = iconRotten,
			color = { 150, 50, 50, alpha },
			width = iconSize * iconRottenAspect,
			height = iconSize
		})
		totalWidth = iconSize * iconRottenAspect
	elseif (self:GetCropStage() >= seedItem:GetStages()) then
		-- Ready to harvest icon
		table.insert(iconsToShow, {
			material = iconHarvest,
			color = { 255, 200, 100, alpha },
			width = iconSize * iconHarvestAspect,
			height = iconSize
		})
		totalWidth = iconSize * iconHarvestAspect
	else
		-- Water icon
		if (self:GetIsWatered()) then
			table.insert(iconsToShow, {
				material = iconWater,
				color = { 100, 150, 255, alpha },
				width = iconSize * iconWaterAspect,
				height = iconSize
			})
			totalWidth = totalWidth + iconSize * iconWaterAspect
		end

		-- Fertilizer icon
		if (self:GetIsFertilized()) then
			table.insert(iconsToShow, {
				material = iconFertilizer,
				color = { 100, 255, 100, alpha },
				width = iconSize * iconFertilizerAspect,
				height = iconSize
			})

			if totalWidth > 0 then
				totalWidth = totalWidth + iconPadding
			end

			totalWidth = totalWidth + iconSize * iconFertilizerAspect
		end
	end

	-- Calculate starting X position to center all icons
	local startX = -totalWidth / 2
	local xOffset = startX

	-- Draw all icons
	for i, icon in ipairs(iconsToShow) do
		surface.SetDrawColor(icon.color[1], icon.color[2], icon.color[3], icon.color[4])
		surface.SetMaterial(icon.material)
		surface.DrawTexturedRect(xOffset, 0, icon.width, icon.height)
		xOffset = xOffset + icon.width + iconPadding
	end

	cam.End3D2D()
end

function ENT:GetEntityMenu()
	local seedItem = self:GetItemTable()
	local options = {}

	if (self:GetIsRotten()) then
		-- If the local player has rot cure, add option
		local character = LocalPlayer():GetCharacter()
		local inventory = character:GetInventory()

		if (inventory:HasItem("rot_cure")) then
			options["Cure Rot"] = function() end
		end

		options["Remove"] = function() end
	else
		-- Harvestable if fully grown
		if (self:GetCropStage() >= seedItem:GetStages()) then
			options["Harvest"] = function() end
		else
			-- If the local player has water or fertilizer, add options
			local character = LocalPlayer():GetCharacter()
			local inventory = character:GetInventory()

			if (not self:GetIsWatered() and inventory:HasItem("water")) then
				options["Water"] = function() end
			end

			if (not self:GetIsFertilized() and inventory:HasItem("fertilizer")) then
				options["Fertilize"] = function() end
			end
		end
	end

	return options
end
