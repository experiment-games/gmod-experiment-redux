local PLUGIN = PLUGIN

if (SERVER) then
	AddCSLuaFile()
end

ENT.Type = "anim"
ENT.PrintName = "Structure Base"
ENT.Category = "Experiment Redux"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.IsStructure = true
ENT.IsStructureOrPart = true
ENT.PopulateEntityInfo = true

AccessorFunc(ENT, "expIsDoorLike", "IsDoorLike")
AccessorFunc(ENT, "expIsPassable", "IsPassable")
AccessorFunc(ENT, "expIsLocked", "IsLocked")

function ENT:SetupDataTables()
	self:NetworkVar("String", "ItemID")
	self:NetworkVar("Bool", "UnderConstruction")
	self:NetworkVar("Int", "GroundLevel")
end

function ENT:GetItemTable()
	return ix.item.list[self:GetItemID()]
end

function ENT:Draw()
	-- Don't draw the entity
	-- self:DrawModel()
end

function ENT:OnPopulateEntityInfo(tooltip)
	if (not self:GetUnderConstruction()) then
		return
	end

	local itemTable = self:GetItemTable()

	if (not itemTable) then
		return
	end

	local name = tooltip:AddRow("name")
	name:SetImportant()
	-- name:SetText(L("propHealth", self:Health(), self:GetMaxHealth()))
	name:SetText(L("propMaterialsRequired"))
	name:SizeToContents()

	local structureMaterials = self:GetNetVar("structureMaterials", {})
	local anyMaterialsRemaining = false

	for materialItem, amount in pairs(itemTable:GetConstructionMaterials()) do
		local amountRemaining = amount - (structureMaterials[materialItem] or 0)

		if (amountRemaining <= 0) then
			continue
		end

		anyMaterialsRemaining = true

		local item = ix.item.list[materialItem]
		local row = tooltip:AddRowAfter("name", "material_" .. materialItem)
		row:SetText(L("propMaterial", item.name, amountRemaining))
		row:SizeToContents()
	end

	if (not anyMaterialsRemaining) then
		local row = tooltip:AddRowAfter("name", "readyToFinishConstruction")
		row:SetText(L("readyToFinishConstruction"))
		row:SizeToContents()
	end
end

function ENT:GetEntityMenu(client)
	if (not self:GetUnderConstruction()) then
		return
	end

	local itemTable = self:GetItemTable()

	if (not itemTable) then
		return false
	end

	local options = {}

	options[L("abortConstruction")] = function() end

	local structureMaterials = self:GetNetVar("structureMaterials", {})
	local anyMaterialsRemaining = false
	local canFillAllMaterials = true
	local allMaterialsData = {}

	for materialItem, amount in pairs(itemTable:GetConstructionMaterials()) do
		local item = ix.item.list[materialItem]
		local itemCount = client:GetCharacter():GetInventory():GetItemCount(materialItem)
		local amountRemaining = amount - (structureMaterials[materialItem] or 0)
		local fillCount = math.min(itemCount, amountRemaining)

		if (amountRemaining <= 0) then
			continue
		end

		anyMaterialsRemaining = true

		-- Store data for "fill all materials" option
		if (fillCount > 0) then
			allMaterialsData[materialItem] = fillCount
		else
			canFillAllMaterials = false
		end

		if (fillCount <= 0) then
			continue
		end

		options[L("fillMaterials", item.name, fillCount)] = function()
			ix.menu.NetworkChoice(self, "fillMaterials", {
				amount = fillCount,
				item = materialItem
			})
			-- We manually send the amount of materials to fill
			return false
		end
	end

	-- Add "fill all materials" option if player has all required materials
	if (anyMaterialsRemaining and canFillAllMaterials and table.Count(allMaterialsData) > 0) then
		options[L("fillAllMaterials")] = function()
			ix.menu.NetworkChoice(self, "fillAllMaterials", {
				materials = allMaterialsData
			})
			return false
		end
	end

	if (not anyMaterialsRemaining) then
		options[L("finishConstruction")] = function() end
	end

	return options
end

if (not SERVER) then
	return
end

AccessorFunc(ENT, "expBuilder", "Builder")
AccessorFunc(ENT, "expBuilderName", "BuilderName")
AccessorFunc(ENT, "expBuilderAlliance", "BuilderAlliance")
AccessorFunc(ENT, "expBuilderSteamID64", "BuilderSteamID64")

function ENT:Initialize()
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetModel("models/props_lab/huladoll.mdl")
end

function ENT:SetStructure(client, item, position, angles)
	self.expItem = item

	self:SetBuilder(client)
	self:SetBuilderName(client:Name())
	self:SetBuilderAlliance(client:GetAlliance())
	self:SetBuilderSteamID64(client:SteamID64())

	client:RegisterEntityToRemoveOnLeave(self)

	self:SetPos(position)
	self:SetAngles(angles)

	self:SetItemID(item.uniqueID)
	self:SetHealth(item.health)
	self:SetMaxHealth(item.health)

	self:SetUnderConstruction(true)
	self:BuildStructure(client, item)

	if (item.structureMaximum) then
		client:AddLimitedObject(item.uniqueID, self)
	end
end

function ENT:BuildStructure(client, item)
	local structure = item:GetStructure(client)

	for _, structurePart in ipairs(structure) do
		local structureEntity = ents.Create("exp_structure_part")
		structureEntity:SetModel(structurePart.model)
		structureEntity:SetPos(self:LocalToWorld(structurePart.position))
		structureEntity:SetAngles(self:LocalToWorldAngles(structurePart.angles))
		structureEntity:SetParent(self)
		structureEntity:Spawn()
		structureEntity:Activate()
		structureEntity:SetNetVar("disabled", true) -- disables selling, buying and other commands
	end
end

function ENT:OnOptionSelected(client, option, data)
	if (option == L("abortConstruction", client)) then
		local structureMaterials = self:GetNetVar("structureMaterials", {})
		-- Refund materials and return the blueprint (if they have space)
		local inventory = client:GetCharacter():GetInventory()

		for materialItem, amount in pairs(structureMaterials) do
			local success, error = inventory:Add(materialItem, amount)

			if (not success) then
				client:Notify(error)
				return
			end
		end

		local success, error = inventory:Add(self:GetItemID())

		if (not success) then
			client:Notify(error)
			return
		end

		self:RemoveWithEffect()
	elseif (option == "fillMaterials") then
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		local structureMaterials = self:GetNetVar("structureMaterials", {})
		local itemTable = self:GetItemTable()

		local amount = math.min(data.amount,
			itemTable:GetConstructionMaterials()[data.item] - (structureMaterials[data.item] or 0))

		if (amount <= 0) then
			client:Notify("You have already filled the required materials.")
			return
		end

		local ownedAmount = inventory:GetItemCount(data.item)

		if (ownedAmount < amount) then
			client:Notify("You do not have enough materials.")
			return
		end

		inventory:RemoveStackedItem(data.item, amount)

		structureMaterials[data.item] = (structureMaterials[data.item] or 0) + amount

		self:SetNetVar("structureMaterials", structureMaterials)

		self:CheckConstruction(client)
	elseif (option == "fillAllMaterials") then
		local character = client:GetCharacter()
		local inventory = character:GetInventory()
		local structureMaterials = self:GetNetVar("structureMaterials", {})
		local itemTable = self:GetItemTable()
		local materialsToAdd = {}
		local totalMaterialsAdded = 0

		-- First pass: validate all materials and calculate what we can add
		for materialItem, requestedAmount in pairs(data.materials) do
			local maxNeeded = itemTable:GetConstructionMaterials()[materialItem] -
				(structureMaterials[materialItem] or 0)
			local actualAmount = math.min(requestedAmount, maxNeeded)

			if (actualAmount <= 0) then
				continue -- Skip materials that are already filled
			end

			local ownedAmount = inventory:GetItemCount(materialItem)

			if (ownedAmount < actualAmount) then
				client:Notify("You do not have enough materials to fill everything.")
				return
			end

			materialsToAdd[materialItem] = actualAmount
			totalMaterialsAdded = totalMaterialsAdded + actualAmount
		end

		-- Check if we actually have materials to add
		if (totalMaterialsAdded == 0) then
			client:Notify("All required materials have already been filled.")
			return
		end

		-- Second pass: actually remove items and update structure
		for materialItem, amount in pairs(materialsToAdd) do
			inventory:RemoveStackedItem(materialItem, amount)
			structureMaterials[materialItem] = (structureMaterials[materialItem] or 0) + amount
		end

		self:SetNetVar("structureMaterials", structureMaterials)
		client:Notify(string.format("Added %d materials to construction.", totalMaterialsAdded))
		self:CheckConstruction(client)
	elseif (option == L("finishConstruction", client)) then
		self:CheckConstruction(client)
	end
end

function ENT:CheckConstruction(client)
	local itemTable = self:GetItemTable()
	local structureMaterials = self:GetNetVar("structureMaterials", {})

	for materialItem, amount in pairs(itemTable:GetConstructionMaterials()) do
		if (amount > (structureMaterials[materialItem] or 0)) then
			return
		end
	end

	self:FinishConstruction(client)
end

function ENT:ForEachPart(callback)
	local children = self:GetChildren()

	for _, child in ipairs(children) do
		if (IsValid(child) and child.IsStructurePart) then
			callback(child)
		end
	end
end

function ENT:CheckSpaceToMakeSolid(callback)
	self:ForEachPart(function(child)
		child.expIsTouched = false
		child:SetTrigger(true)
	end)

	timer.Simple(0.1, function()
		if (not IsValid(self)) then
			return
		end

		local isTouched = false

		self:ForEachPart(function(child)
			child:SetTrigger(false)

			if (child.expIsTouched) then
				isTouched = true
			end

			child.expIsTouched = nil
		end)

		callback(not isTouched)
	end)
end

function ENT:FinishConstruction(client)
	self:CheckSpaceToMakeSolid(function(hasSpaceToMakeSolid)
		if (not hasSpaceToMakeSolid) then
			if (IsValid(client)) then
				client:Notify("You cannot finish the construction while it's intersecting with another object.")
			end

			return
		end

		self:SetUnderConstruction(false)

		self:ForEachPart(function(child)
			child:SetCollisionGroup(COLLISION_GROUP_NONE)
		end)

		self:SetupDoorAccess(client, DOOR_OWNER)

		if (self.expItem.OnFinishConstruction) then
			local replacement = self.expItem:OnFinishConstruction(self, client)
			local builder = self:GetBuilder()

			if (IsValid(replacement) and IsValid(builder)) then
				local itemTable = self:GetItemTable()

				client:RegisterEntityToRemoveOnLeave(replacement)

				-- Since a replacement is added, we should add that as the limited object since self will be removed
				if (itemTable and itemTable.structureMaximum) then
					builder:AddLimitedObject(itemTable.uniqueID, replacement)

					replacement:CallOnRemove(
						string.format("%s#structureMaximum#%s", builder:SteamID(), replacement:EntIndex()),
						function()
							builder:RemoveLimitedObject(itemTable.uniqueID, replacement)
						end
					)
				end
			end
		end
	end)
end

function ENT:SetupDoorAccess(client, role)
	self:SetIsDoorLike(true)
	self:ForEachPart(function(child)
		child.ixAccess = child.ixAccess or {}

		if (not IsValid(client)) then
			return
		end

		child:SetDTEntity(0, client)
		child.ixAccess[client] = role or DOOR_GUEST
	end)
end

function ENT:DisableDoorAccess()
	self:SetIsDoorLike(false)
	self:ForEachPart(function(child)
		child.ixAccess = nil
		child:SetDTEntity(0, nil)
	end)
end

function ENT:Think()
	local client = self:GetBuilder()

	if (not IsValid(client) or not client:Alive()) then
		self:Remove()
		return
	end
end

function ENT:AcceptInput(inputName, activator, caller, data)
	inputName = inputName:lower()

	if (inputName == "lock") then
		self:SetIsLocked(true)
		self:MakeUnpassable()
	elseif (inputName == "unlock") then
		self:SetIsLocked(false)
	end
end

function ENT:TryUse(client)
	if (Schema.util.Throttle("StructureUse", 1, self)) then
		return
	end

	if (self:GetUnderConstruction()) then
		return
	end

	if (self.expIsDecaying) then
		return
	end

	if (not self:GetIsDoorLike()) then
		return
	end

	if (self:GetIsLocked()) then
		return
	end

	self:MakePassable(4)
end

--- Makes the children of the structure passable for a duration, not reapplying the collision group
--- until no more players are inside the structure
function ENT:MakePassable(duration)
	if (self:GetIsPassable()) then
		return
	end

	self:SetIsPassable(true)
	self:EmitSound("ambient/energy/zap1.wav", 60, 50)

	local alpha = 160

	self:ForEachPart(function(child)
		child:SetCollisionGroup(COLLISION_GROUP_WORLD)

		if (child.expColorBefore == nil) then
			child.expColorBefore = child:GetColor()
		end

		if (child.expRenderModeBefore == nil) then
			child.expRenderModeBefore = child:GetRenderMode()
		end

		child:SetRenderMode(RENDERMODE_TRANSALPHA)
		child:SetColor(Color(child.expColorBefore.r, child.expColorBefore.g, child.expColorBefore.b, alpha))
	end)

	local name = "expStructureMakeUnpassable" .. self:EntIndex()

	timer.Create(name, duration, 0, function()
		if (not IsValid(self)) then
			timer.Remove(name)
			return
		end

		self:MakeUnpassable()
	end)
end

function ENT:MakeUnpassable()
	if (not self:GetIsPassable()) then
		return
	end

	local name = "expStructureMakeUnpassable" .. self:EntIndex()

	self:CheckSpaceToMakeSolid(function(hasSpaceToMakeSolid)
		if (not hasSpaceToMakeSolid) then
			return
		end

		timer.Remove(name)

		if (self.expIsDecaying) then
			return
		end

		self:ForEachPart(function(child)
			child:SetCollisionGroup(COLLISION_GROUP_NONE)
			child:SetColor(child.expColorBefore)
			child:SetRenderMode(child.expRenderModeBefore)

			child.expColorBefore = nil
			child.expRenderModeBefore = nil
		end)

		self:SetIsPassable(false)
		self:EmitSound("ambient/energy/zap8.wav", 60, 50)
	end)
end

--- Checks if the client has an active siege surge buff against the builder or their alliance
--- @param client any
--- @return boolean|ActiveBuff, Buff
function ENT:HasSiegeSurgeActive(client)
	local victimData = {
		victimID = self:GetBuilderSteamID64(),
	}

	local buff, buffTable = Schema.buff.GetActive(client, "siege_surge", victimData)
	local allianceID = self:GetBuilderAlliance()

	if (not buff and allianceID) then
		victimData.alliance = allianceID
		buff, buffTable = Schema.buff.GetActive(client, "siege_surge", victimData)
	end

	return buff, buffTable
end

function ENT:HandleSiegeSurgeDamage(damageInfo)
	local attacker = damageInfo:GetAttacker()

	if (not IsValid(attacker) or not attacker:IsPlayer()) then
		return
	end

	local buff, buffTable = self:HasSiegeSurgeActive(attacker)

	if (not buff) then
		return
	end

	local stacks = buffTable:GetStacks(attacker, buff)
	damageInfo:ScaleDamage(1 + stacks)
end

function ENT:HandleSiegeSurgeStack(client)
	local buff, buffTable = self:HasSiegeSurgeActive(client)

	if (not buff) then
		local victimData = {
			victimID = self:GetBuilderSteamID64(),
			victimName = self:GetBuilderName(),
		}

		if (self:GetBuilderAlliance()) then
			victimData.alliance = self:GetBuilderAlliance()
		end

		Schema.buff.SetActive(client, "siege_surge", nil, victimData)
		return
	end

	buffTable:Stack(client, buff)
end

function ENT:OnTakeDamage(damageInfo)
	if (self:GetUnderConstruction()) then
		return
	end

	if (self.expIsDecaying) then
		return
	end

	self:HandleSiegeSurgeDamage(damageInfo)

	self:SetHealth(self:Health() - damageInfo:GetDamage())

	local damageColor = math.max((self:Health() / self:GetMaxHealth()) * 255, 30)
	self:ForEachPart(function(child)
		local ownAlpha = child:GetColor().a -- Match passable alpha
		child:SetColor(Color(damageColor, damageColor, damageColor, ownAlpha))
	end)

	if (self:Health() <= 0) then
		local attacker = damageInfo:GetAttacker()

		if (IsValid(attacker) and attacker:IsPlayer()) then
			self:HandleSiegeSurgeStack(attacker)

			if (self:GetBuilderSteamID64() ~= attacker:SteamID64()) then
				Schema.achievement.Progress("hooligan", attacker)
			end
		end

		hook.Run("StructureDestroyed", self, attacker)

		self.expIsDecaying = true

		self:ForEachPart(function(child)
			child:SetCollisionGroup(COLLISION_GROUP_WEAPON)
			child:Ignite(4, 0)
			Schema.DecayEntity(child, 4)
		end)
	end
end

function ENT:OnRemove()
	if (self.expItem.structureMaximum) then
		local client = self:GetBuilder()

		if (IsValid(client)) then
			client:RemoveLimitedObject(self.expItem.uniqueID, self)
		end
	end

	self:ForEachPart(function(child)
		child:Remove()
	end)
end
