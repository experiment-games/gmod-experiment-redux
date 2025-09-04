--[[
	An instancing system that allows entities to be visible only to specific players.
	By default, all players are in the global instance (nil).
	When a player is moved to a specific instance, they can only see entities that belong to that instance.

	Instances are identified by unique strings (typically SteamID64).
	Entities can belong to one instance at a time.
	Players can be in one instance at a time.

	Each instance can have an owner. When the owner disconnects, the instance is automatically destroyed.

	TODO: Prevent in-character chat
	TODO: Prevent server-side only EmitSounds from playing (only shared calls to EmitSound can be stopped by EntityEmitSound)
]]

--- @class InstanceData
--- @field entities table<Entity, boolean> Entities belonging to this instance
--- @field players table<Player, boolean> Players in this instance
--- @field owner Player|nil The client that owns this instance

Schema.instance = ix.util.GetOrCreateLibrary("instance", {
	instances = {},    -- instanceID -> InstanceData
	playerInstances = {}, -- Player -> instanceID
	entityInstances = {}, -- Entity -> instanceID
	instanceOwners = {}, -- instanceID -> Player (for quick lookup)
})

if (SERVER) then
	--- Gets all children of an entity recursively
	--- @param entity Entity
	--- @return table<Entity>
	local function GetEntityChildren(entity)
		local children = {}

		if (not IsValid(entity)) then
			return children
		end

		-- Get direct children
		local directChildren = entity:GetChildren()

		for _, child in ipairs(directChildren) do
			if (IsValid(child)) then
				table.insert(children, child)
				-- Recursively get children of children
				local grandchildren = GetEntityChildren(child)
				for _, grandchild in ipairs(grandchildren) do
					table.insert(children, grandchild)
				end
			end
		end

		return children
	end

	--- Common logic for adding entities to instances with networking
	--- @param entity Entity
	--- @param instanceID string
	--- @param isPlayer boolean
	local function AddEntityToInstance(entity, instanceID, isPlayer)
		if (not IsValid(entity)) then
			ix.util.SchemaErrorNoHalt("Attempted to add invalid entity to instance '" .. tostring(instanceID) .. "'\n")
			return false
		end

		-- Remove from previous instance if it exists
		local oldInstanceID = Schema.instance.entityInstances[entity] or Schema.instance.playerInstances[entity]
		if (oldInstanceID) then
			if (isPlayer) then
				Schema.instance.RemovePlayer(entity)
			else
				Schema.instance.RemoveEntity(entity)
			end
		end

		-- Create instance if it doesn't exist
		local instance = Schema.instance.CreateInstance(instanceID)

		-- Add entity to appropriate collection
		if (isPlayer) then
			instance.players[entity] = true
			Schema.instance.playerInstances[entity] = instanceID
		else
			instance.entities[entity] = true
			Schema.instance.entityInstances[entity] = instanceID
		end

		-- Network the entity's instance ID
		entity:SetNWString("InstanceID", instanceID)

		-- Needed for ShouldCollide to work
		entity.expInstanceOldCustomCollisionCheck = entity:GetCustomCollisionCheck()
		entity:SetCustomCollisionCheck(true)

		return true
	end

	--- Common logic for removing entities from instances
	--- @param entity Entity
	--- @param isPlayer boolean
	local function RemoveEntityFromInstance(entity, isPlayer)
		if (not IsValid(entity)) then
			return false
		end

		local instanceID
		if (isPlayer) then
			instanceID = Schema.instance.playerInstances[entity]
		else
			instanceID = Schema.instance.entityInstances[entity]
		end

		if (not instanceID) then
			return false
		end

		local instance = Schema.instance.instances[instanceID]
		if (instance) then
			if (isPlayer) then
				instance.players[entity] = nil
				Schema.instance.playerInstances[entity] = nil
			else
				instance.entities[entity] = nil
				Schema.instance.entityInstances[entity] = nil
			end
		end

		-- Clear networked instance ID
		entity:SetNWString("InstanceID", "")

		-- Restore collision check
		entity:SetCustomCollisionCheck(entity.expInstanceOldCustomCollisionCheck or false)

		return instanceID
	end

	--- Creates a new instance or returns existing one
	--- @param instanceID string
	--- @param owner Player|nil Optional owner of the instance
	--- @return InstanceData
	function Schema.instance.CreateInstance(instanceID, owner)
		if (not Schema.instance.instances[instanceID]) then
			Schema.instance.instances[instanceID] = {
				entities = {},
				players = {},
				owner = owner
			}

			-- Track ownership for quick lookup
			if (IsValid(owner)) then
				Schema.instance.instanceOwners[instanceID] = owner
			end
		end

		return Schema.instance.instances[instanceID]
	end

	--- Sets the owner of an instance
	--- @param instanceID string
	--- @param owner Player The new owner
	function Schema.instance.SetInstanceOwner(instanceID, owner)
		if (not IsValid(owner)) then
			ix.util.SchemaErrorNoHalt("Attempted to set invalid owner for instance '" .. tostring(instanceID) .. "'\n")
			return
		end

		local instance = Schema.instance.instances[instanceID]
		if (not instance) then
			ix.util.SchemaErrorNoHalt("Attempted to set owner for non-existent instance '" ..
				tostring(instanceID) .. "'\n")
			return
		end

		local oldOwner = instance.owner
		instance.owner = owner
		Schema.instance.instanceOwners[instanceID] = owner

		hook.Run("InstanceOwnerChanged", instanceID, owner, oldOwner)
	end

	--- Gets the owner of an instance
	--- @param instanceID string
	--- @return Player|nil
	function Schema.instance.GetInstanceOwner(instanceID)
		local instance = Schema.instance.instances[instanceID]
		return instance and instance.owner or nil
	end

	--- Checks if a player owns an instance
	--- @param client Player
	--- @param instanceID string
	--- @return boolean
	function Schema.instance.IsInstanceOwner(client, instanceID)
		local instance = Schema.instance.instances[instanceID]
		return instance and instance.owner == client or false
	end

	--- Gets all instances owned by a player
	--- @param client Player
	--- @return table<string, InstanceData>
	function Schema.instance.GetPlayerOwnedInstances(client)
		local ownedInstances = {}

		for instanceID, owner in pairs(Schema.instance.instanceOwners) do
			if (owner == client) then
				ownedInstances[instanceID] = Schema.instance.instances[instanceID]
			end
		end

		return ownedInstances
	end

	--- Adds an entity and its children to an instance
	--- @param entity Entity
	--- @param instanceID string
	--- @param includeChildren boolean Optional, defaults to true
	function Schema.instance.AddEntity(entity, instanceID, includeChildren)
		if (includeChildren == nil) then includeChildren = true end

		if (not AddEntityToInstance(entity, instanceID, false)) then
			return
		end

		-- Add children to the same instance
		if (includeChildren) then
			local children = GetEntityChildren(entity)
			for _, child in ipairs(children) do
				if (IsValid(child)) then
					AddEntityToInstance(child, instanceID, false)
					hook.Run("EntityAddedToInstance", child, instanceID)
				end
			end
		end

		hook.Run("EntityAddedToInstance", entity, instanceID)
	end

	--- Removes an entity and its children from its instance
	--- @param entity Entity
	--- @param includeChildren boolean Optional, defaults to true
	function Schema.instance.RemoveEntity(entity, includeChildren)
		if (includeChildren == nil) then includeChildren = true end

		-- Remove children first
		if (includeChildren) then
			local children = GetEntityChildren(entity)
			for _, child in ipairs(children) do
				if (IsValid(child)) then
					local childInstanceID = RemoveEntityFromInstance(child, false)
					if (childInstanceID) then
						hook.Run("EntityRemovedFromInstance", child, childInstanceID)
					end
				end
			end
		end

		-- Remove the main entity
		local instanceID = RemoveEntityFromInstance(entity, false)
		if (instanceID) then
			hook.Run("EntityRemovedFromInstance", entity, instanceID)
		end
	end

	--- Adds a player to an instance
	--- ! Do not call this function in PlayerSpawn, Loadout or anything similar. Use timer.Simple(0, ...) to
	--- ! delay the call a frame. Otherwise the player's hands will not have been parented to the predicted
	--- ! viewmodel yet, causing the hands to be invisible.
	--- @param client Player
	--- @param instanceID? string Optional ID to identify the instance by, defaults to SteamID64
	function Schema.instance.AddPlayer(client, instanceID)
		instanceID = instanceID or client:SteamID64()

		if (not AddEntityToInstance(client, instanceID, true)) then
			return
		end

		hook.Run("PlayerAddedToInstance", client, instanceID)
	end

	--- Removes a player from their instance (returns them to global)
	--- @param client Player
	function Schema.instance.RemovePlayer(client)
		local instanceID = RemoveEntityFromInstance(client, true)
		if (instanceID) then
			hook.Run("PlayerRemovedFromInstance", client, instanceID)
		end
	end

	--- Gets the instance ID a player is in
	--- @param client Player
	--- @return string|nil
	function Schema.instance.GetPlayerInstance(client)
		return Schema.instance.playerInstances[client]
	end

	--- Gets the instance ID an entity belongs to
	--- @param entity Entity
	--- @return string|nil
	function Schema.instance.GetEntityInstance(entity)
		return Schema.instance.entityInstances[entity]
	end

	--- Checks if a player can see an entity based on instancing
	--- @param client Player
	--- @param entity Entity
	--- @return boolean
	function Schema.instance.CanPlayerSeeEntity(client, entity)
		local playerInstance = Schema.instance.playerInstances[client]
		local entityInstance = Schema.instance.entityInstances[entity]

		-- If neither are in an instance, they can see each other
		if (not playerInstance and not entityInstance) then
			return true
		end

		-- If they're in the same instance, they can see each other
		return playerInstance == entityInstance
	end

	--- Checks if a player can see another player based on instancing
	--- @param viewer Player
	--- @param target Player
	--- @return boolean
	function Schema.instance.CanPlayerSeePlayer(viewer, target)
		local viewerInstance = Schema.instance.playerInstances[viewer]
		local targetInstance = Schema.instance.playerInstances[target]

		-- If neither are in an instance, they can see each other
		if (not viewerInstance and not targetInstance) then
			return true
		end

		-- If they're in the same instance, they can see each other
		return viewerInstance == targetInstance
	end

	--- Destroys an instance and removes all its entities and players
	--- @param instanceID string
	--- @param reason string|nil Optional reason for destruction
	function Schema.instance.DestroyInstance(instanceID, reason)
		local instance = Schema.instance.instances[instanceID]
		if (not instance) then
			return
		end

		hook.Run("InstancePreDestroy", instanceID, reason or "manual")

		-- Remove all players from instance
		for client, _ in pairs(instance.players) do
			if (IsValid(client)) then
				Schema.instance.RemovePlayer(client)
			end
		end

		-- Remove all entities (this will also remove them from the world)
		for entity, _ in pairs(instance.entities) do
			if (IsValid(entity)) then
				Schema.instance.RemoveEntity(entity)
				entity:Remove()
			end
		end

		-- Clear ownership tracking
		Schema.instance.instanceOwners[instanceID] = nil

		-- Clear the instance
		Schema.instance.instances[instanceID] = nil

		hook.Run("InstanceDestroyed", instanceID, reason or "manual")
	end

	--- Gets all players in an instance
	--- @param instanceID string
	--- @return table<Player, boolean>
	function Schema.instance.GetPlayersInInstance(instanceID)
		local instance = Schema.instance.instances[instanceID]
		return instance and instance.players or {}
	end

	--- Gets all entities in an instance
	--- @param instanceID string
	--- @return table<Entity, boolean>
	function Schema.instance.GetEntitiesInInstance(instanceID)
		local instance = Schema.instance.instances[instanceID]
		return instance and instance.entities or {}
	end

	--- Gets all active instances
	--- @return table<string, InstanceData>
	function Schema.instance.GetAllInstances()
		return Schema.instance.instances
	end

	--- Transfers ownership of an instance to another player
	--- @param instanceID string
	--- @param newOwner Player
	--- @param oldOwner Player|nil Optional verification of current owner
	function Schema.instance.TransferInstanceOwnership(instanceID, newOwner, oldOwner)
		if (not IsValid(newOwner)) then
			ix.util.SchemaErrorNoHalt("Attempted to transfer instance ownership to invalid player\n")
			return false
		end

		local instance = Schema.instance.instances[instanceID]
		if (not instance) then
			ix.util.SchemaErrorNoHalt("Attempted to transfer ownership of non-existent instance '" ..
				tostring(instanceID) .. "'\n")
			return false
		end

		-- Verify current ownership if specified
		if (oldOwner and instance.owner ~= oldOwner) then
			ix.util.SchemaErrorNoHalt("Instance ownership verification failed for '" .. tostring(instanceID) .. "'\n")
			return false
		end

		local previousOwner = instance.owner
		instance.owner = newOwner
		Schema.instance.instanceOwners[instanceID] = newOwner

		hook.Run("InstanceOwnershipTransferred", instanceID, newOwner, previousOwner)
		return true
	end

	-- Hook to handle when entities get parented
	hook.Add("EntitySetParent", "expInstanceParentChild", function(child, parent)
		-- Validate entities
		if (not IsValid(child) or not IsValid(parent)) then
			return
		end

		-- Get the parent's instance
		local parentInstance = Schema.instance.GetEntityInstance(parent)

		-- If parent is a player, check their instance instead
		if (parent:IsPlayer()) then
			parentInstance = Schema.instance.GetPlayerInstance(parent)
		end

		-- Get the child's current instance
		local childInstance = Schema.instance.GetEntityInstance(child)

		-- If parent has an instance and child doesn't match, move child to parent's instance
		if (parentInstance and parentInstance ~= childInstance) then
			-- Remove child from current instance first (if any)
			if (childInstance) then
				Schema.instance.RemoveEntity(child, false) -- Don't include children to avoid recursion
			end

			-- Add child to parent's instance (don't include children to avoid double-processing)
			Schema.instance.AddEntity(child, parentInstance, false)

			-- Call hook for external systems
			hook.Run("EntityMovedToParentInstance", child, parent, parentInstance, childInstance)
		elseif (not parentInstance and childInstance) then
			-- If parent is not instanced but child is, remove child from instance
			Schema.instance.RemoveEntity(child, false)

			hook.Run("EntityRemovedFromParentInstance", child, parent, childInstance)
		end
	end)

	-- Hook to handle when entities lose their parent (via SetParent(nil) or parent removal)
	local function HandleOrphanedEntity(entity)
		if (not IsValid(entity)) then
			return
		end

		-- Check if this entity was in an instance and now has no parent
		local entityInstance = Schema.instance.GetEntityInstance(entity)
		if (entityInstance and not IsValid(entity:GetParent())) then
			-- Entity is orphaned and in an instance - keep it in the instance
			-- This maintains consistency unless explicitly moved by other code
			return
		end
	end

	--[[
		Server hooks
	--]]

	-- Clean up when entities are removed
	hook.Add("EntityRemoved", "expInstanceCleanup", function(entity)
		if (not IsValid(entity)) then
			return
		end

		-- Get all children of the removed entity
		local children = entity:GetChildren()
		for _, child in ipairs(children) do
			if (IsValid(child)) then
				-- Child will be automatically orphaned, but keep it in the same instance
				-- The existing EntityRemoved hook in your system will clean up if needed
				HandleOrphanedEntity(child)
			end
		end

		Schema.instance.RemoveEntity(entity)
	end)

	-- Clean up when players disconnect - destroy owned instances
	hook.Add("PlayerDisconnected", "expInstanceCleanup", function(client)
		-- Remove player from their current instance
		Schema.instance.RemovePlayer(client)

		-- Destroy all instances owned by this player
		local ownedInstances = Schema.instance.GetPlayerOwnedInstances(client)

		for instanceID, _ in pairs(ownedInstances) do
			Schema.instance.DestroyInstance(instanceID, "owner_disconnect")
		end
	end)


	-- Prevent players from hearing voice chat across instances
	hook.Add("PlayerCanHearPlayersVoice", "expPreventHearingOtherInstancePlayers", function(listener, speaker)
		return Schema.instance.CanPlayerSeePlayer(listener, speaker)
	end)

	-- Prevent physgun interactions across instances
	hook.Add("PhysgunPickup", "expInstancePhysgunPickup", function(client, entity)
		if (not Schema.instance.CanPlayerSeeEntity(client, entity)) then
			return false
		end
	end)

	-- Prevent gravgun interactions across instances
	hook.Add("GravGunOnPickedUp", "expInstanceGravgunPickup", function(client, entity)
		if (not Schema.instance.CanPlayerSeeEntity(client, entity)) then
			return false
		end
	end)

	hook.Add("GravGunPunt", "expInstanceGravgunPunt", function(client, entity)
		if (not Schema.instance.CanPlayerSeeEntity(client, entity)) then
			return false
		end
	end)

	-- Prevent damage across instances
	hook.Add("EntityTakeDamage", "expInstanceDamage", function(target, dmgInfo)
		local attacker = dmgInfo:GetAttacker()

		if (IsValid(attacker) and attacker:IsPlayer()) then
			-- Prevent player damage across instances
			if (target:IsPlayer()) then
				if (not Schema.instance.CanPlayerSeePlayer(attacker, target)) then
					return true -- Block damage
				end
			else
				-- Prevent entity damage across instances
				if (not Schema.instance.CanPlayerSeeEntity(attacker, target)) then
					return true -- Block damage
				end
			end
		end
	end)

	-- Prevent use interactions across instances
	hook.Add("PlayerUse", "expInstancePlayerUse", function(client, entity)
		if (not Schema.instance.CanPlayerSeeEntity(client, entity)) then
			return false
		end
	end)

	-- Prevent tool gun usage across instances
	hook.Add("CanTool", "expInstanceCanTool", function(client, trace, tool)
		local entity = trace.Entity
		if (IsValid(entity) and not Schema.instance.CanPlayerSeeEntity(client, entity)) then
			return false
		end
	end)

	-- Prevent duplicator interactions across instances
	hook.Add("CanDrive", "expInstanceCanDrive", function(client, entity)
		if (not Schema.instance.CanPlayerSeeEntity(client, entity)) then
			return false
		end
	end)

	-- Prevent property interactions across instances
	hook.Add("CanProperty", "expInstanceCanProperty", function(client, property, entity)
		if (not Schema.instance.CanPlayerSeeEntity(client, entity)) then
			return false
		end
	end)

	-- Commented, otherwise player:Give wont work
	-- -- Prevent right-click context menu interactions across instances
	-- hook.Add("PlayerCanPickupWeapon", "expInstancePickupWeapon", function(client, weapon)
	-- 	if (not Schema.instance.CanPlayerSeeEntity(client, weapon)) then
	-- 		return false
	-- 	end
	-- end)

	-- Prevent item pickup across instances (for dropped items)
	hook.Add("PlayerCanPickupItem", "expInstancePickupItem", function(client, item)
		if (not Schema.instance.CanPlayerSeeEntity(client, item)) then
			return false
		end
	end)

	-- Prevent vehicles from being entered across instances
	hook.Add("CanPlayerEnterVehicle", "expInstanceEnterVehicle", function(client, vehicle, role)
		if (not Schema.instance.CanPlayerSeeEntity(client, vehicle)) then
			return false
		end
	end)

	-- Prevent spawning entities in other instances
	hook.Add("PlayerSpawnedSENT", "expInstanceSpawnedSENT", function(client, entity)
		-- Automatically add spawned entities to the player's instance
		local playerInstance = Schema.instance.GetPlayerInstance(client)
		if (playerInstance) then
			Schema.instance.AddEntity(entity, playerInstance)
		end
	end)

	hook.Add("PlayerSpawnedProp", "expInstanceSpawnedProp", function(client, model, entity)
		-- Automatically add spawned props to the player's instance
		local playerInstance = Schema.instance.GetPlayerInstance(client)
		if (playerInstance) then
			Schema.instance.AddEntity(entity, playerInstance)
		end
	end)

	hook.Add("PlayerSpawnedNPC", "expInstanceSpawnedNPC", function(client, entity)
		-- Automatically add spawned NPCs to the player's instance
		local playerInstance = Schema.instance.GetPlayerInstance(client)
		if (playerInstance) then
			Schema.instance.AddEntity(entity, playerInstance)
		end
	end)

	hook.Add("PlayerSpawnedVehicle", "expInstanceSpawnedVehicle", function(client, entity)
		-- Automatically add spawned vehicles to the player's instance
		local playerInstance = Schema.instance.GetPlayerInstance(client)
		if (playerInstance) then
			Schema.instance.AddEntity(entity, playerInstance)
		end
	end)

	-- Prevent doors from being used across instances
	hook.Add("PlayerUseDoor", "expInstanceUseDoor", function(client, door)
		if (not Schema.instance.CanPlayerSeeEntity(client, door)) then
			return false
		end
	end)

	-- Prevent doors from being knocked across instances
	hook.Add("CanPlayerKnock", "expInstanceKnockDoor", function(client, door)
		if (not Schema.instance.CanPlayerSeeEntity(client, door)) then
			return false
		end
	end)

	-- Prevent picking up objects with hands across instances.
	hook.Add("CanPlayerHoldObject", "expInstanceHoldObject", function(client, object)
		if (not Schema.instance.CanPlayerSeeEntity(client, object)) then
			return false
		end
	end)

	-- Ensure dropped items from a player get moved to the same instance.
	hook.Add("OnItemSpawned", "expInstanceItemSpawned", function(item)
		if (not item.ixSteamID) then
			return
		end

		local client = player.GetBySteamID(item.ixSteamID)

		if (client) then
			local playerInstance = Schema.instance.GetPlayerInstance(client)

			if (playerInstance) then
				Schema.instance.AddEntity(item, playerInstance)
			end
		end
	end)

	-- Prevent in-character chat from working across instances
	hook.Add("PlayerMessageSend", "expInstanceChatFilter",
		function(speaker, chatType, text, anonymous, receivers, rawText)
			if (chatType == "ic") then
				local playerInstance = Schema.instance.GetPlayerInstance(speaker)

				-- If the player is in an instance, remove receivers not in the same instance
				if (playerInstance) then
					for i = #receivers, 1, -1 do
						local receiver = receivers[i]

						if (not Schema.instance.CanPlayerSeePlayer(speaker, receiver)) then
							table.remove(receivers, i)
						end
					end
				end
			end

			return text -- Allow the message to be sent normally
		end
	)
else
	--- Client-side function to get a player's instance using networked data
	--- @param client Player
	--- @return string|nil
	function Schema.instance.GetPlayerInstance(client)
		if (not IsValid(client)) then
			return nil
		end

		local instanceID = client:GetNWString("InstanceID", "")
		return instanceID ~= "" and instanceID or nil
	end

	--- Client-side function to get an entity's instance using networked data
	--- @param entity Entity
	--- @return string|nil
	function Schema.instance.GetEntityInstance(entity)
		if (not IsValid(entity)) then
			return nil
		end

		local instanceID = entity:GetNWString("InstanceID", "")
		return instanceID ~= "" and instanceID or nil
	end

	--- Shared function to check if a player can see an entity based on instancing
	--- @param client Player
	--- @param entity Entity
	--- @return boolean
	function Schema.instance.CanPlayerSeeEntity(client, entity)
		local playerInstance = Schema.instance.GetPlayerInstance(client)
		local entityInstance = Schema.instance.GetEntityInstance(entity)

		-- If neither are in an instance, they can see each other
		if (not playerInstance and not entityInstance) then
			return true
		end

		-- If they're in the same instance, they can see each other
		return playerInstance == entityInstance
	end

	--- Shared function to check if a player can see another player based on instancing
	--- @param viewer Player
	--- @param target Player
	--- @return boolean
	function Schema.instance.CanPlayerSeePlayer(viewer, target)
		local viewerInstance = Schema.instance.GetPlayerInstance(viewer)
		local targetInstance = Schema.instance.GetPlayerInstance(target)

		-- If neither are in an instance, they can see each other
		if (not viewerInstance and not targetInstance) then
			return true
		end

		-- If they're in the same instance, they can see each other
		return viewerInstance == targetInstance
	end

	--- Client-side function to check if the local player can see another player
	--- @param target Player
	--- @return boolean
	function Schema.instance.CanSeePlayer(target)
		local localPlayer = LocalPlayer()
		if (not IsValid(localPlayer) or not IsValid(target)) then
			return true
		end

		return Schema.instance.CanPlayerSeePlayer(localPlayer, target)
	end

	--- Client-side function to check if the local player can see an entity
	--- @param entity Entity
	--- @return boolean
	function Schema.instance.CanSeeEntity(entity)
		local localPlayer = LocalPlayer()
		if (not IsValid(localPlayer) or not IsValid(entity)) then
			return true
		end

		return Schema.instance.CanPlayerSeeEntity(localPlayer, entity)
	end

	--[[
		Client hooks
	--]]

	-- Store entities that should be hidden due to instance mismatch
	Schema.instance.hiddenEntities = Schema.instance.hiddenEntities or {}
	local hiddenEntities = Schema.instance.hiddenEntities

	-- Store entities in PVS so not all entities have to be looped in PreRender
	Schema.instance.entitiesInPVS = Schema.instance.entitiesInPVS or {}
	local entitiesInPVS = Schema.instance.entitiesInPVS

	-- Track entities entering PVS
	hook.Add("NotifyShouldTransmit", "expInstancePVSTracking", function(entity, shouldTransmit)
		if (shouldTransmit) then
			entitiesInPVS[entity] = true
		else
			entitiesInPVS[entity] = nil
			-- Clean up hidden entities when they leave PVS
			if (hiddenEntities[entity]) then
				hiddenEntities[entity] = nil
			end
		end
	end)

	-- Lookups since thse are used in hooks that are called often and this micro optimization helps
	local isValid = IsValid
	local localPlayerFunction = LocalPlayer
	local canSeeEntity = Schema.instance.CanSeeEntity
	local canSeePlayer = Schema.instance.CanSeePlayer

	-- Pre-render hook to hide entities from other instances
	hook.Add("PreRender", "expInstanceVisibilityControl", function()
		local localPlayer = localPlayerFunction()

		if (not isValid(localPlayer)) then
			return
		end

		-- Process only entities in PVS
		for entity, _ in pairs(entitiesInPVS) do
			if (isValid(entity) and entity ~= localPlayer) then
				local shouldHide = false

				-- Check if entity should be visible to local player
				if (entity:IsPlayer()) then
					shouldHide = not canSeePlayer(entity)
				else
					shouldHide = not canSeeEntity(entity)
				end

				-- Allow overriding if the player can be seen. This could for example be used when using instances
				-- for chunks and you want to draw players in the bordering chunk with SetRenderOrigin.
				local shouldHideOverride = hook.Run("ShouldHideEntityDueToInstance", localPlayer, entity, shouldHide)

				if (shouldHideOverride ~= nil) then
					shouldHide = shouldHideOverride
				end

				local isCurrentlyHidden = hiddenEntities[entity]

				if (shouldHide and not isCurrentlyHidden) then
					-- Need to hide this entity
					entity.expOldNoDraw = entity:GetNoDraw()
					entity:SetNoDraw(true)
					hiddenEntities[entity] = true
				elseif (not shouldHide and isCurrentlyHidden) then
					-- Need to show this entity
					entity:SetNoDraw(entity.expOldNoDraw or false)
					entity.expOldNoDraw = nil
					hiddenEntities[entity] = nil
				end
			end
		end
	end)

	-- Clean up when entities are removed
	hook.Add("EntityRemoved", "expInstanceVisibilityCleanup", function(entity)
		entitiesInPVS[entity] = nil

		if (hiddenEntities[entity]) then
			hiddenEntities[entity] = nil
		end
	end)

	-- Hide player names/overlays for players in different instances
	hook.Add("HUDDrawTargetID", "expInstanceTargetID", function()
		local trace = localPlayerFunction():GetEyeTrace()
		local target = trace.Entity

		if (isValid(target) and target:IsPlayer()) then
			if (not canSeePlayer(target)) then
				return true -- Prevent drawing target ID
			end
		end
	end)

	-- Prevent sound from playing across instances
	hook.Add("EntityEmitSound", "expInstanceEntitySound", function(data)
		local entity = data.Entity

		if (isValid(entity)) then
			local localPlayer = localPlayerFunction()

			if (isValid(localPlayer)) then
				-- If it's a player sound
				if (entity:IsPlayer()) then
					if (not canSeePlayer(entity)) then
						return false
					end
				else
					-- For entity sounds, check if we can see the entity
					if (not canSeeEntity(entity)) then
						return false
					end
				end
			end
		end
	end)

	-- Prevent client-side prediction errors for interactions
	hook.Add("CreateMove", "expInstanceCreateMove", function(cmd)
		local localPlayer = localPlayerFunction()
		if (cmd:KeyDown(IN_USE)) then
			local trace = localPlayer:GetEyeTrace()
			local entity = trace.Entity

			if (isValid(entity) and not canSeeEntity(entity)) then
				cmd:RemoveKey(IN_USE)
			end
		end
	end)

	-- Prevent tooltip info for entities in other instances
	hook.Add("ShouldPopulateEntityInfo", "expInstanceEntityInfo", function(entity)
		local localPlayer = localPlayerFunction()
		if (isValid(localPlayer)) then
			if (not canSeeEntity(entity)) then
				return false
			end
		end
	end)
end

--[[
	Shared hooks
--]]

-- Micro-optimize lookup (ShouldCollide hook is called very often)
local getEntityInstance = Schema.instance.GetEntityInstance
local getPlayerInstance = Schema.instance.GetPlayerInstance

-- Collision prevention across instances
hook.Add("ShouldCollide", "expInstanceShouldCollide", function(ent1, ent2)
	-- If one is the world, return to have default behaviour
	if (not IsValid(ent1) or not IsValid(ent2)) then
		return
	end

	local inst1 = ent1:IsPlayer() and getPlayerInstance(ent1) or getEntityInstance(ent1)
	local inst2 = ent2:IsPlayer() and getPlayerInstance(ent2) or getEntityInstance(ent2)

	-- If one is instanced and the other isn't, or they're in different instances
	if ((inst1 and not inst2) or (not inst1 and inst2) or (inst1 ~= inst2)) then
		return false
	end
end)

-- Shared trace filtering
hook.Add("PlayerTraceAttack", "expInstanceTraceAttack", function(client, damageinfo, dir, trace)
	local attacker = damageinfo:GetAttacker()

	if (IsValid(attacker) and attacker:IsPlayer()) then
		if (attacker:IsPlayer()) then
			if (not Schema.instance.CanPlayerSeePlayer(client, attacker)) then
				return true -- Block trace
			end
		else
			if (not Schema.instance.CanPlayerSeeEntity(client, attacker)) then
				return true -- Block trace
			end
		end
	end
end)

--[[
	Commands
--]]

do
	local COMMAND = {}

	COMMAND.description = "Get the instance ID of a player."
	COMMAND.arguments = {
		ix.type.player
	}
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, target)
		if (not IsValid(target)) then
			client:Notify("Invalid player.")
			return
		end

		local instanceID = Schema.instance.GetEntityInstance(target)

		if (not instanceID) then
			client:Notify("Player is not in an instance.")
			return
		end

		client:Notify("Player's instance ID: " .. instanceID)
	end

	ix.command.Add("InstanceGetID", COMMAND)
end
