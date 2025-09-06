local PLUGIN = PLUGIN

function PLUGIN:LoadBelongings()
	local belongings = self:GetData()

	for _, belongingsData in pairs(belongings) do
		if (not belongingsData.ownerID) then
			-- Legacy check that we can remove after 1 map change
			continue
		end

		local entity = ents.Create("exp_belongings")
		local inventoryID = tonumber(belongingsData.inventoryID)

		entity:SetAngles(belongingsData.angles)
		entity:SetOwnerID(belongingsData.ownerID)
		entity:SetMoney(belongingsData.money)
		entity:SetPos(belongingsData.position)
		entity:Spawn()

		ix.inventory.Restore(inventoryID, belongingsData.invWidth, belongingsData.invHeight, function(inventory)
			if (IsValid(entity)) then
				entity:SetInventory(inventory)
			end

			inventory.vars.belongingsEntity = entity
		end)

		if (not belongingsData.moveable) then
			local physicsObject = entity:GetPhysicsObject()

			if (IsValid(physicsObject)) then
				physicsObject:EnableMotion(false)
			end
		end
	end
end

function PLUGIN:SaveBelongings()
	local entities = ents.FindByClass("exp_belongings")
	local belongings = {}

	for _, ragdoll in pairs(ents.FindByClass("prop_ragdoll")) do
		if (not ragdoll.expIsBelongings) then
			continue
		end

		entities[#entities + 1] = ragdoll
	end

	for _, entity in pairs(entities) do
		local inventory = entity:GetInventory()

		if (self:RemoveIfEmpty(inventory)) then
			continue
		end

		local physicsObject = entity:GetPhysicsObject()
		local moveable

		if (IsValid(physicsObject)) then
			moveable = physicsObject:IsMoveable()
		end

		if (not inventory.GetSize) then
			ix.util.SchemaErrorNoHaltWithStack(
				"TODO: Im doing something wrong, find out why inventories are not complete\n")
			continue
		end

		-- Do not store monster inventories (for sake of code simplicity)
		if (entity:GetOwnerID() == 0) then
			continue
		end

		local width, height = inventory:GetSize()

		belongings[#belongings + 1] = {
			inventoryID = inventory:GetID(),
			invWidth = width,
			invHeight = height,
			money = entity:GetMoney(),

			ownerID = entity:GetOwnerID(),

			position = entity:GetPos(),
			angles = entity:GetAngles(),
			moveable = moveable,
		}
	end

	self:SetData(belongings)
end

--- If there's no money or items left in the belongings, remove it.
--- @param inventory? table
function PLUGIN:RemoveIfEmpty(inventory)
	if (not inventory) then
		return true
	end

	if (not inventory.vars or not IsValid(inventory.vars.belongingsEntity)) then
		return false
	end

	local entity = inventory.vars.belongingsEntity

	if (entity:GetMoney() > 0 or table.Count(entity:GetInventory():GetItems()) > 0) then
		return false
	end

	entity:RemoveWithEffect()

	if (inventory.storageInfo) then
		--[[
			TODO: Figure out why this happens. For now it'll just prevent this error:

			[ERROR] gamemodes/helix/gamemode/core/libs/sh_storage.lua:268: attempt to index field 'storageInfo' (a nil value)
			Close - gamemodes/helix/gamemode/core/libs/sh_storage.lua:268
			RemoveIfEmpty - gamemodes/experiment-redux/plugins/belongings/sv_plugin.lua:114
			SaveBelongings - gamemodes/experiment-redux/plugins/belongings/sv_plugin.lua:54
			v - gamemodes/experiment-redux/plugins/belongings/sv_hooks.lua:4
			Run - gamemodes/helix/gamemode/core/libs/sh_plugin.lua:347
			unknown - gamemodes/helix/gamemode/core/sh_data.lua:116

			[ERROR] Warning! A net message (ixStorageExpired) is already started! Discarding in favor of the new message! (ixNetVarDelete)
			ClearNetVars - gamemodes/helix/gamemode/core/libs/sv_networking.lua:191
			unknown - gamemodes/helix/gamemode/core/hooks/sh_hooks.lua:232

			On SERVERSIDE, spotted at 2024-06-10 14:40
		--]]
		ix.storage.Close(inventory)
	end

	local index = inventory:GetID()

	local query = mysql:Delete("ix_items")
	query:Where("inventory_id", index)
	query:Execute()

	query = mysql:Delete("ix_inventories")
	query:Where("inventory_id", index)
	query:Execute()

	return true
end

function PLUGIN:CreateBelongings(corpse)
	local inventory = corpse.ixInventory

	if (not inventory) then
		ix.util.SchemaErrorNoHaltWithStack(
			"Attempted to create belongings for monster without existing corpse inventory\n")
		return -- This shouldn't happen, but lets log it just in case
	end

	local belongings = ents.Create("exp_belongings")

	belongings:SetMoney(corpse:GetMoney())

	belongings.ixInventory = inventory
	inventory.vars.belongingsEntity = belongings

	belongings:SetInventory(inventory)
	belongings:SetAngles(corpse:GetAngles())
	belongings:SetPos(corpse:GetPos() + Vector(0, 0, 48))
	belongings:Spawn()

	return belongings
end

function PLUGIN:HandleCorpseEmpty(corpse)
	if (corpse:GetMoney() == 0 and table.Count(corpse.ixInventory:GetItems()) == 0) then
		local index = corpse.ixInventory:GetID()

		local query = mysql:Delete("ix_items")
		query:Where("inventory_id", index)
		query:Execute()

		query = mysql:Delete("ix_inventories")
		query:Where("inventory_id", index)
		query:Execute()

		return true
	end

	return false
end
