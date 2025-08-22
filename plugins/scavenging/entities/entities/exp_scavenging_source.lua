local PLUGIN = PLUGIN

if (SERVER) then
	AddCSLuaFile()
end

ENT.Type = "anim"

ENT.PrintName = "Scavenging Source"
ENT.Author = "Experiment Redux"

ENT.Spawnable = false
ENT.AdminOnly = true

ENT.Model = Model("models/props_junk/trashcluster01a.mdl")

ENT.IsScavengingSource = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", "ID")
	self:NetworkVar("String", "InventoryType")
	self:NetworkVar("String", "SourceName")
end

function ENT:GetInventory()
	local inventoryID = self:GetID()

	if (inventoryID == 0) then
		return nil
	end

	return ix.item.inventories[inventoryID]
end

if (SERVER) then
	function ENT:Initialize()
		self:SetModel(self.Model)

		-- self:SetSolid(SOLID_BBOX)
		-- self:SetCollisionGroup(COLLISION_GROUP_WORLD)
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local physicsObject = self:GetPhysicsObject()

		if (IsValid(physicsObject)) then
			physicsObject:EnableMotion(false)
		end
	end

	function ENT:Think()
		local physicsObject = self:GetPhysicsObject()

		if (IsValid(physicsObject) and physicsObject:IsMotionEnabled() and not IsValid(self.expPhysgunnedBy)) then
			-- Prevent admins from accidentally moving the entity too much
			physicsObject:EnableMotion(false)
		end

		self:NextThink(CurTime() + 1)
		return true
	end

	function ENT:SetInvisible(invisible)
		self:SetNoDraw(invisible)
		self:DrawShadow(not invisible)

		if (invisible) then
			self:SetModel("models/props_wasteland/laundry_dryer001.mdl")
			self:SetSolid(SOLID_BBOX)
			self:SetCollisionGroup(COLLISION_GROUP_WORLD)
			self:SetRenderMode(RENDERMODE_TRANSALPHA)
			self:SetColor(Color(0, 0, 0, 0))
		else
			self:SetModel(self.Model)
			self:SetSolid(SOLID_VPHYSICS)
			self:PhysicsInit(SOLID_VPHYSICS)
			self:SetRenderMode(RENDERMODE_NORMAL)
			self:SetColor(Color(255, 255, 255, 255))
		end
	end

	function ENT:SetInventory(inventory)
		if (inventory) then
			self:SetID(inventory:GetID())
		end
	end

	function ENT:MakeInventory(inventoryType)
		local entity = self

		inventoryType = inventoryType or "scavenging:base"

		self:SetInventoryType(inventoryType)

		ix.inventory.New(0, inventoryType, function(inventory)
			inventory.vars.isScavengingSource = entity

			if (IsValid(entity)) then
				entity:SetInventory(inventory)

				PLUGIN:AddItemsToScavengingSource(entity, inventory)
			end
		end)
	end

	function ENT:OpenInventory(activator)
		local inventory = self:GetInventory()

		if (not inventory) then
			ix.util.SchemaErrorNoHalt("Attempt to open a scavenging source with no inventory!\n")
			return
		end

		local name = self:GetSourceName()

		if (name == "") then
			name = "A bunch of junk"
		end

		local baseTaskTime = ix.config.Get("scavengeSourceOpenTime", 4)
		local searchTime = Schema.GetDexterityTime(activator, baseTaskTime)

		ix.storage.Open(activator, inventory, {
			name = name,
			entity = self,
			searchTime = searchTime,
			searchText = "Scavenging...",
			bMultipleUsers = true,
			OnPlayerOpen = function(client)
				if (not IsValid(activator) or not IsValid(client) or not inventory or not inventory.GetID) then
					-- See comment below
					return
				end

				ix.log.Add(client, "openContainer", name, inventory:GetID())
			end,
			OnPlayerClose = function(client)
				if (not IsValid(activator) or not IsValid(client) or not inventory or not inventory.GetID) then
					--[[
					Issue: https://github.com/experiment-games/gmod-experiment-redux/issues/115
					This seems to happen when not staring at the scavenging source for long enough (1) AND when closing it normally (2):

					1.
						[LOG] Dmitri Nicholov opened the 'A bunch of junk' #19 container.

						[ERROR] gamemodes/helix/gamemode/core/libs/sh_character.lua:1227: Tried to use a NULL entity!
						1. SteamName - [C]:-1
						2. Name - gamemodes/helix/gamemode/core/libs/sh_character.lua:1227
							3. text - gamemodes/helix/plugins/containers/sh_plugin.lua:218
							4. Parse - gamemodes/helix/gamemode/core/libs/sh_log.lua:74
							5. Add - gamemodes/helix/gamemode/core/libs/sh_log.lua:101
							6. OnPlayerClose - gamemodes/experiment-redux/plugins/scavenging/entities/entities/exp_scavenging_source.lua:131
								7. RemoveReceiver - gamemodes/helix/gamemode/core/libs/sh_storage.lua:202
								8. onCancel - gamemodes/helix/gamemode/core/libs/sh_storage.lua:251
								9. unknown - gamemodes/helix/gamemode/core/meta/sh_player.lua:146

						Timer Failed! [ixStare562264568][@gamemodes/helix/gamemode/core/meta/sh_player.lua (line 137)]

					2.
						[LOG] Boris Petrov opened the 'A bunch of junk' #25 container.
						[LOG] Boris Petrov ran 'Scrap' on item 'Metal Can' (#2480)
						[LOG] Boris Petrov has gained a 'Scrap' #2901.
						[LOG] Boris Petrov ran 'Scrap' on item 'Metal Can' (#2512)
						[LOG] Boris Petrov has gained a 'Scrap' #2902.

						[ERROR] gamemodes/helix/gamemode/core/libs/sh_character.lua:1227: Tried to use a NULL entity!
						1. SteamName - [C]:-1
						2. Name - gamemodes/helix/gamemode/core/libs/sh_character.lua:1227
							3. text - gamemodes/helix/plugins/containers/sh_plugin.lua:218
							4. Parse - gamemodes/helix/gamemode/core/libs/sh_log.lua:74
							5. Add - gamemodes/helix/gamemode/core/libs/sh_log.lua:101
							6. OnPlayerClose - gamemodes/experiment-redux/plugins/scavenging/entities/entities/exp_scavenging_source.lua:131
								7. RemoveReceiver - gamemodes/helix/gamemode/core/libs/sh_storage.lua:202
								8. func - gamemodes/helix/gamemode/core/libs/sh_storage.lua:279
								9. unknown - lua/includes/extensions/net.lua:38

					I see no reason why it should happen, except that perhaps somehow Lua doesn't keep a reference to the 'activator' from
					the ENT:Use function. This debugging code should help me figure out what's going on.
					--]]
					ix.util.SchemaError(
						"(Debugging) Clogsin scavenging point that has no activator, inventory or inventory.GetID.\n"
						.. "Activator: " .. tostring(activator) .. "\n"
						.. "Client: " .. tostring(client) .. "\n"
						.. "Inventory: " .. tostring(inventory) .. "\n"
						.. "Inventory.GetID: " .. tostring(inventory and inventory.GetID or nil) .. "\n"
					)

					return
				end

				ix.log.Add(client, "closeContainer", name, inventory:GetID())
			end
		})
	end

	function ENT:Use(activator)
		self:OpenInventory(activator)
	end

	function ENT:OnRemove()
		local index = self:GetID()

		if (! ix.shuttingDown and ! self.ixIsSafe and ix.entityDataLoaded and index) then
			local inventory = ix.item.inventories[index]

			if (inventory) then
				ix.item.inventories[index] = nil

				local query = mysql:Delete("ix_items")
				query:Where("inventory_id", index)
				query:Execute()

				query = mysql:Delete("ix_inventories")
				query:Where("inventory_id", index)
				query:Execute()

				hook.Run("ContainerRemoved", self, inventory)
			end
		end
	end

	-- Let the map spawn scavenging sources
	function ENT:KeyValue(key, value)
		key = key:lower()

		if (key == "inventorytype") then
			self:SetInventoryType(value)
		elseif (key == "sourcename") then
			self:SetSourceName(value)
		elseif (key == "model") then
			self.Model = value
		elseif (key == "invisible") then
			self:SetInvisible(tobool(value))
		end
	end
end

if (not CLIENT) then
	return
end

ENT.PopulateEntityInfo = true

function ENT:OnPopulateEntityInfo(tooltip)
	local sourceName = self:GetSourceName()

	if (sourceName == "") then
		sourceName = "A pile of junk"
	end

	local name = tooltip:AddRow("name")
	name:SetImportant()
	name:SetText(sourceName)
	name:SizeToContents()

	local description = tooltip:AddRow("description")
	description:SetText("It might contain something useful...")
	description:SizeToContents()
end
