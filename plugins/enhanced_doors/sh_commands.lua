local PLUGIN = PLUGIN

ix.command.Add("DoorSetUnownable", {
	description = "@cmdDoorSetUnownable",
	privilege = "Manage Doors",
	adminOnly = true,
	arguments = ix.type.text,
	OnRun = function(self, client, name)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and ! entity:GetNetVar("disabled")) then
			-- Set it so it is unownable.
			entity:SetNetVar("ownable", nil)

			-- Change the name of the door if needed.
			if (name:find("%S")) then
				entity:SetNetVar("name", name)
			end

			PLUGIN:CallOnDoorChildren(entity, function(child)
				child:SetNetVar("ownable", nil)

				if (name:find("%S")) then
					child:SetNetVar("name", name)
				end
			end)

			-- Save the door information.
			PLUGIN:SaveDoorData()
			return "@dMadeUnownable"
		else
			-- Tell the player the door isn't valid.
			return "@dNotValid"
		end
	end
})

ix.command.Add("DoorSetOwnable", {
	description = "@cmdDoorSetOwnable",
	privilege = "Manage Doors",
	adminOnly = true,
	arguments = ix.type.text,
	OnRun = function(self, client, name)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and ! entity:GetNetVar("disabled")) then
			PLUGIN:DoorSetOwnable(entity, true, name)

			-- Save the door information.
			PLUGIN:SaveDoorData()
			return "@dMadeOwnable"
		else
			-- Tell the player the door isn't valid.
			return "@dNotValid"
		end
	end
})

ix.command.Add("DoorSetFaction", {
	description = "@cmdDoorSetFaction",
	privilege = "Manage Doors",
	adminOnly = true,
	arguments = bit.bor(ix.type.text, ix.type.optional),
	OnRun = function(self, client, name)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and ! entity:GetNetVar("disabled")) then
			if (! name or name == "") then
				entity.ixFactionID = nil
				entity:SetNetVar("faction", nil)

				PLUGIN:CallOnDoorChildren(entity, function()
					entity.ixFactionID = nil
					entity:SetNetVar("faction", nil)
				end)

				PLUGIN:SaveDoorData()
				return "@dRemoveFaction"
			end

			local faction

			-- Loop through each faction, checking the uniqueID and name.
			for k, v in pairs(ix.faction.teams) do
				if (ix.util.StringMatches(k, name) or ix.util.StringMatches(L(v.name, client), name)) then
					-- This faction matches the provided string.
					faction = v

					-- Escape the loop.
					break
				end
			end

			-- Check if a faction was found.
			if (faction) then
				entity.ixFactionID = faction.uniqueID
				entity:SetNetVar("faction", faction.index)

				PLUGIN:CallOnDoorChildren(entity, function()
					entity.ixFactionID = faction.uniqueID
					entity:SetNetVar("faction", faction.index)
				end)

				PLUGIN:SaveDoorData()
				return "@dSetFaction", L(faction.name, client)
				-- The faction was not found.
			else
				return "@invalidFaction"
			end
		end
	end
})

ix.command.Add("DoorSetDisabled", {
	description = "@cmdDoorSetDisabled",
	privilege = "Manage Doors",
	adminOnly = true,
	arguments = ix.type.bool,
	OnRun = function(self, client, bDisabled)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor()) then
			-- Set it so it is ownable.
			entity:SetNetVar("disabled", bDisabled)

			PLUGIN:CallOnDoorChildren(entity, function(child)
				child:SetNetVar("disabled", bDisabled)
			end)

			PLUGIN:SaveDoorData()

			-- Tell the player they have made the door (un)disabled.
			return "@dSet" .. (bDisabled and "" or "Not") .. "Disabled"
		else
			-- Tell the player the door isn't valid.
			return "@dNotValid"
		end
	end
})

ix.command.Add("DoorSetTitle", {
	description = "@cmdDoorSetTitle",
	arguments = ix.type.text,
	OnRun = function(self, client, name)
		-- Get the door infront of the player.
		local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 96
		data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity
		entity = entity:GetDoor()

		if (not entity) then
			return false
		end

		-- Validate the door.
		if (IsValid(entity) and entity:IsDoor() and ! entity:GetNetVar("disabled")) then
			-- Make sure the name contains actual characters.
			if (! name:find("%S")) then
				return "@invalidArg", 1
			end

			--[[
				NOTE: Here, we are setting two different networked names.
				The title is a temporary name, while the other name is the
				default name for the door. The reason for this is so when the
				server closes while someone owns the door, it doesn't save THEIR
				title, which could lead to unwanted things.
			--]]

			name = name:utf8sub(1, 24)

			-- Check if they are allowed to change the door's name.
			if (entity:CheckDoorAccess(client, DOOR_TENANT)) then
				entity:SetNetVar("title", name)
			elseif (CAMI.PlayerHasAccess(client, "Helix - Manage Doors", nil)) then
				entity:SetNetVar("name", name)

				PLUGIN:CallOnDoorChildren(entity, function(child)
					child:SetNetVar("name", name)
				end)
			else
				-- Otherwise notify the player he/she can't.
				return "@notOwner"
			end
		else
			-- Notification of the door not being valid.
			return "@dNotValid"
		end
	end
})

ix.command.Add("DoorSetParent", {
	description = "@cmdDoorSetParent",
	privilege = "Manage Doors",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and ! entity:GetNetVar("disabled")) then
			client.ixDoorParent = entity
			return "@dSetParentDoor"
		else
			-- Tell the player the door isn't valid.
			return "@dNotValid"
		end
	end
})

ix.command.Add("DoorSetChild", {
	description = "@cmdDoorSetChild",
	privilege = "Manage Doors",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and ! entity:GetNetVar("disabled")) then
			local parent = client.ixDoorParent

			if (parent == entity) then
				return "@dCanNotSetAsChild"
			end

			-- Check if the player has set a door as a parent.
			if (IsValid(parent)) then
				PLUGIN:DoorSetParent(entity, parent)

				-- Save the door information.
				PLUGIN:SaveDoorData()

				return "@dAddChildDoor"
			else
				-- Tell the player they do not have a door parent.
				return "@dNoParentDoor"
			end
		else
			-- Tell the player the door isn't valid.
			return "@dNotValid"
		end
	end
})

ix.command.Add("DoorRemoveChild", {
	description = "@cmdDoorRemoveChild",
	privilege = "Manage Doors",
	adminOnly = true,
	OnRun = function(self, client, arguments)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and ! entity:GetNetVar("disabled")) then
			if (client.ixDoorParent == entity) then
				PLUGIN:CallOnDoorChildren(entity, function(child)
					child.ixParent = nil
				end)

				entity.ixChildren = nil
				return "@dRemoveChildren"
			end

			-- Check if the player has set a door as a parent.
			if (IsValid(entity.ixParent) and entity.ixParent.ixChildren) then
				-- Remove the door from the list of children.
				entity.ixParent.ixChildren[entity:MapCreationID()] = nil
				-- Remove the variable for the parent.
				entity.ixParent = nil

				PLUGIN:SaveDoorData()
				return "@dRemoveChildDoor"
			end
		else
			-- Tell the player the door isn't valid.
			return "@dNotValid"
		end
	end
})

ix.command.Add("DoorSetHidden", {
	description = "@cmdDoorSetHidden",
	privilege = "Manage Doors",
	adminOnly = true,
	arguments = ix.type.bool,
	OnRun = function(self, client, bHidden)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor()) then
			entity:SetNetVar("visible", ! bHidden)

			PLUGIN:CallOnDoorChildren(entity, function(child)
				child:SetNetVar("visible", ! bHidden)
			end)

			PLUGIN:SaveDoorData()

			-- Tell the player they have made the door (un)hidden.
			return "@dSet" .. (bHidden and "" or "Not") .. "Hidden"
		else
			-- Tell the player the door isn't valid.
			return "@dNotValid"
		end
	end
})

ix.command.Add("DoorSetClass", {
	description = "@cmdDoorSetClass",
	privilege = "Manage Doors",
	adminOnly = true,
	arguments = bit.bor(ix.type.text, ix.type.optional),
	OnRun = function(self, client, name)
		-- Get the door the player is looking at.
		local entity = client:GetEyeTrace().Entity

		-- Validate it is a door.
		if (IsValid(entity) and entity:IsDoor() and ! entity:GetNetVar("disabled")) then
			if (! name or name == "") then
				entity:SetNetVar("class", nil)

				PLUGIN:CallOnDoorChildren(entity, function()
					entity:SetNetVar("class", nil)
				end)

				PLUGIN:SaveDoorData()
				return "@dRemoveClass"
			end

			local class, classData

			for k, v in pairs(ix.class.list) do
				if (ix.util.StringMatches(v.name, name) or ix.util.StringMatches(L(v.name, client), name)) then
					class, classData = k, v

					break
				end
			end

			-- Check if a faction was found.
			if (class) then
				entity.ixClassID = class
				entity:SetNetVar("class", class)

				PLUGIN:CallOnDoorChildren(entity, function()
					entity.ixClassID = class
					entity:SetNetVar("class", class)
				end)

				PLUGIN:SaveDoorData()
				return "@dSetClass", L(classData.name, client)
			else
				return "@invalidClass"
			end
		end
	end
})
