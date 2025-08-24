local PLUGIN = PLUGIN

include("shared.lua")

ENT.PopulateEntityInfo = true

function ENT:OnPopulateEntityInfo(tooltip)
	local config = PLUGIN:GetCropConfig(self:GetCropType())
	local cropName = config and config.name or "Unknown Crop"

	-- Crop name
	local name = tooltip:AddRow("name")
	name:SetImportant()
	name:SetText(cropName)
	name:SizeToContents()

	-- Growth stage
	local stage = self:GetCropStage()
	local maxStages = config and config.stages or 3
	local stageRow = tooltip:AddRow("stage")
	stageRow:SetText("Stage " .. stage .. "/" .. maxStages)
	stageRow:SizeToContents()

	-- Growth status
	local statusRow = tooltip:AddRow("status")
	if (stage >= maxStages) then
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
		waterRow:SetIcon("icon16/water.png")
		waterRow:SizeToContents()
		waterRow:Dock(BOTTOM)
	end

	-- Fertilizer status with icon
	if (self:GetIsFertilized()) then
		local fertRow = tooltip:Add("expIconText")
		fertRow:SetText("Fertilized")
		fertRow:SetTextColor(Color(100, 255, 100))
		fertRow:SetIcon("icon16/arrow_refresh.png")
		fertRow:SizeToContents()
		fertRow:Dock(BOTTOM)
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

	local maxAlpha = 50
	local alpha = math.max(0, maxAlpha - (distance / 200) * maxAlpha)

	cam.Start3D2D(pos, Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.25)
	local xOffset = 0

	-- Ready to harvest icon
	local config = PLUGIN:GetCropConfig(self:GetCropType())

	if (config and self:GetCropStage() >= config.stages) then
		surface.SetDrawColor(255, 200, 100, alpha)
		surface.SetMaterial(Material("icon16/basket.png"))
		surface.DrawTexturedRect(xOffset, 0, 16, 16)
	else
		-- Water icon
		if (self:GetIsWatered()) then
			surface.SetDrawColor(100, 150, 255, alpha)
			surface.SetMaterial(Material("icon16/water.png"))
			surface.DrawTexturedRect(xOffset, 0, 16, 16)
			xOffset = xOffset + 20
		end

		-- Fertilizer icon
		if (self:GetIsFertilized()) then
			surface.SetDrawColor(100, 255, 100, alpha)
			surface.SetMaterial(Material("icon16/arrow_refresh.png"))
			surface.DrawTexturedRect(xOffset, 0, 16, 16)
			xOffset = xOffset + 20
		end
	end

	cam.End3D2D()
end

function ENT:GetEntityMenu()
	local config = PLUGIN:GetCropConfig(self:GetCropType())

	local options = {}

	if (not config) then
		return options
	end

	-- Harvestable if fully grown
	if (self:GetCropStage() >= config.stages) then
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

	return options
end
