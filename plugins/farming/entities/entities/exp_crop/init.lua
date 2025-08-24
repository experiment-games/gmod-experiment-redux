local PLUGIN = PLUGIN

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel(self.cropModel or "models/a31/fallout4/props/plants/carrot.mdl")

	self:SetMoveType(MOVETYPE_NONE)
	self:PhysicsInit(SOLID_NONE)
	self:SetUseType(SIMPLE_USE)
	self:SetSolid(SOLID_VPHYSICS)

	self.cropType = self.cropType or "carrot"
	self:SetCropType(self.cropType)
	self:SetCropStage(1)
	self.lastGrowth = CurTime()
	self:SetIsWatered(false)
	self:SetIsFertilized(false)
	self.wateredTime = 0

	self:UpdateCropAppearance()
	self:StartGrowthTimer()
end

function ENT:StartGrowthTimer()
	if (not IsValid(self)) then
		return
	end

	local config = PLUGIN:GetCropConfig(self.cropType)
	if (not config) then
		return
	end

	local baseGrowthTime = config.growthTime
	local modifiedTime = baseGrowthTime

	-- Apply modifiers
	if (self:GetIsWatered()) then
		modifiedTime = modifiedTime * 0.8 -- 20% faster with water
	end

	if (self:GetIsFertilized()) then
		modifiedTime = modifiedTime * 0.6 -- 40% faster with fertilizer
	end

	self.nextGrowth = CurTime() + modifiedTime
end

function ENT:Think()
	if (self.nextGrowth and CurTime() >= self.nextGrowth) then
		self:GrowStage()
	end

	-- Reset water status after growth
	if (self:GetIsWatered() and CurTime() >= (self.wateredTime or 0) + 60) then
		self:SetIsWatered(false)
	end

	self:NextThink(CurTime() + 1)

	return true
end

function ENT:GrowStage()
	local config = PLUGIN:GetCropConfig(self.cropType)
	if (not config) then
		return
	end

	if (self:GetCropStage() < config.stages) then
		self:SetCropStage(self:GetCropStage() + 1)
		self:UpdateCropAppearance()
		self:StartGrowthTimer()
	end
end

function ENT:UpdateCropAppearance()
	local config = PLUGIN:GetCropConfig(self.cropType)
	if (not config or not config.stageConfig[self:GetCropStage()]) then
		return
	end

	local stageData = config.stageConfig[self:GetCropStage()]

	-- Update model if specified
	if (stageData.model) then
		self:SetModel(stageData.model)
	else
		self:SetModel(config.cropModel)
	end

	-- Update scale
	if (stageData.modelScale) then
		self:SetModelScale(stageData.modelScale)
	end

	-- Update bodygroup
	if (stageData.bodygroup) then
		self:SetBodygroup(0, stageData.bodygroup)
	end

	-- Update skin
	if (stageData.skin) then
		self:SetSkin(stageData.skin)
	end
end

function ENT:Harvest(player)
	local config = PLUGIN:GetCropConfig(self.cropType)
	if (not config) then
		return
	end

	local character = player:GetCharacter()
	if (not character) then
		return
	end

	local inventory = character:GetInventory()
	if (not inventory) then
		return
	end

	-- Call hook for crop output modification
	local harvestAmount = hook.Run("GetCropOutput", player, self.cropType, config.harvestItems) or config.harvestItems

	-- Give items to player
	for i = 1, harvestAmount do
		inventory:Add(self.cropType)
	end

	player:Notify(
		string.format("You harvested %d %s(s)!", harvestAmount, config.name)
	)

	self:EmitSound("physics/body/body_medium_break2.wav", 40, 255)

	self:Remove()
end

function ENT:OnTakeDamage(dmg)
	-- Crops can't be damaged
	return
end

function ENT:SetWatered(watered)
	self:SetIsWatered(watered)
	if (watered) then
		self.wateredTime = CurTime()
	end
end

function ENT:SetFertilized(fertilized)
	self:SetIsFertilized(fertilized)
end

function ENT:OnOptionSelected(client, option, data)
	if (option == "Harvest") then
		self:Harvest(client)
	elseif (option == "Water") then
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		-- Find a water bottle in inventory
		local waterItem = inventory:HasItem("water")

		if (waterItem) then
			if (PLUGIN:WaterCrop(client, self)) then
				waterItem:Remove() -- Consume the water bottle
			end
		else
			client:Notify("You need a water bottle to water crops.")
		end
	elseif (option == "Fertilize") then
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		-- Find fertilizer in inventory
		local fertItem = inventory:HasItem("fertilizer")

		if (fertItem) then
			if (PLUGIN:FertilizeCrop(client, self)) then
				fertItem:Remove() -- Consume the fertilizer
			end
		else
			client:Notify("You need fertilizer to fertilize crops.")
		end
	end
end
