local PLUGIN = PLUGIN

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel(self.cropModel or "models/a31/fallout4/props/plants/carrot.mdl")

	self:SetMoveType(MOVETYPE_NONE)
	self:PhysicsInit(SOLID_OBB)
	self:SetUseType(SIMPLE_USE)
	self:SetSolid(SOLID_OBB)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	self:SetCropStage(1)
	self.lastGrowth = CurTime()
	self:SetIsWatered(false)
	self:SetIsFertilized(false)
	self:SetIsRotten(false)
	self.wateredTime = 0

	self:UpdateCropAppearance()
	self:StartGrowthTimer()
end

function ENT:StartGrowthTimer()
	if (not IsValid(self)) then
		return
	end

	local seedItem = self:GetItemTable()
	local baseGrowthTime = seedItem:GetGrowthTime()
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

function ENT:CheckRotting()
	if (self:GetIsRotten() or self.rotPrevented) then
		return
	end

	local seedItem = self:GetItemTable()
	local stageConfig = seedItem:GetStageConfig(self:GetCropStage())

	if (stageConfig and stageConfig.rotChance) then
		if (math.random(1, 100) <= stageConfig.rotChance) then
			self:SetRotten()
		end
	end
end

function ENT:SetRotten()
	self:SetIsRotten(true)
	self:UpdateCropAppearance()
	self.nextGrowth = nil -- Stop growing
end

function ENT:CureRot()
	if (not self:GetIsRotten()) then
		return false
	end

	self:SetIsRotten(false)
	self:UpdateCropAppearance()
	self:StartGrowthTimer()
	return true
end

function ENT:Think()
	if (not self:GetIsRotten() and self.nextGrowth and CurTime() >= self.nextGrowth) then
		self:GrowStage()
	end

	if (self:GetIsWatered() and CurTime() >= (self.wateredTime or 0) + 60) then
		self:SetIsWatered(false)
	end

	-- Check for rotting every 30 seconds
	if (not self.lastRotCheck or CurTime() >= self.lastRotCheck + 30) then
		self:CheckRotting()
		self.lastRotCheck = CurTime()
	end

	self:NextThink(CurTime() + 1)

	return true
end

function ENT:GrowStage()
	local seedItem = self:GetItemTable()

	if (self:GetCropStage() < seedItem:GetStages()) then
		self:SetCropStage(self:GetCropStage() + 1)
		self:UpdateCropAppearance()
		self:StartGrowthTimer()
	end
end

function ENT:UpdateCropAppearance()
	local seedItem = self:GetItemTable()
	local stageConfig = seedItem:GetStageConfig(self:GetCropStage())

	if (not stageConfig) then
		return
	end

	-- Update model if specified
	if (stageConfig.model) then
		self:SetModel(stageConfig.model)
	else
		self:SetModel(seedItem:GetCropModel())
	end

	-- Update scale
	if (stageConfig.modelScale) then
		self:SetModelScale(stageConfig.modelScale)
	end

	-- Update bodygroup
	if (stageConfig.bodygroup) then
		self:SetBodygroup(0, stageConfig.bodygroup)
	end

	-- Update skin based on rotten state
	if (self:GetIsRotten()) then
		self:SetSkin(0)          -- Rotten skin
	elseif (stageConfig.skin) then
		self:SetSkin(stageConfig.skin) -- Normal skin
	end
end

function ENT:Harvest(player)
	if (self:GetIsRotten()) then
		player:Notify("This crop is rotten and cannot be harvested.")
		return
	end

	if (not self:CanHarvest()) then
		player:Notify("This crop is not ready for harvest.")
		return
	end

	local seedItem = self:GetItemTable()
	local character = player:GetCharacter()
	local inventory = character:GetInventory()

	if (not inventory) then
		return
	end

	-- Call hook for crop output modification
	local productItem = seedItem:GetProductItemTable()
	local harvestItems = seedItem:GetHarvestItems()
	local harvestAmount = hook.Run("GetCropOutput", player, seedItem, productItem, harvestItems)
		or harvestItems

	-- Give items to player
	for i = 1, harvestAmount do
		inventory:Add(productItem.uniqueID)
	end

	player:Notify(
		string.format("You harvested %d %s%s!", harvestAmount, productItem:GetName(), harvestAmount ~= 1 and "s" or "")
	)

	player:EmitSound("npc/stalker/stalker_footstep_left2.wav", 45, 255)
	player:EmitSound("npc/stalker/stalker_footstep_right2.wav", 45, 255)

	self:Remove()
end

function ENT:HarvestRotten(player)
	if (not self:GetIsRotten()) then
		player:Notify("This crop is not rotten.")
		return
	end

	local seedItem = self:GetItemTable()
	local character = player:GetCharacter()
	local inventory = character:GetInventory()

	if (not inventory) then
		return
	end

	-- Give rotten items to player
	local rottenItem = seedItem:GetRottenItemTable()
	if (rottenItem) then
		inventory:Add(rottenItem.uniqueID)
		player:Notify(string.format("You removed the rotten %s.", rottenItem:GetName()))
	else
		player:Notify("You removed the rotten crop.")
	end

	player:EmitSound("npc/stalker/stalker_footstep_left2.wav", 45, 255)

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

function ENT:CanHarvest()
	local seedItem = self:GetItemTable()
	return self:GetCropStage() >= seedItem:GetStages() and not self:GetIsRotten()
end

function ENT:OnOptionSelected(client, option, data)
	if (option == "Harvest") then
		self:Harvest(client)
	elseif (option == "Remove") then
		self:HarvestRotten(client)
	elseif (option == "Cure Rot") then
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		local cureItem = inventory:HasItem("rot_cure")

		if (cureItem) then
			if (self:CureRot()) then
				cureItem:Remove()
				client:Notify("You cured the crop's rot! It will continue growing.")
			else
				client:Notify("This crop is not rotten.")
			end
		else
			client:Notify("You need rot cure to cure rotten crops.")
		end
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
