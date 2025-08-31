--- Server library to work with companions and command them in the world.
Schema.companion = ix.util.GetOrCreateLibrary("companion", {
	spawned = {}
})

util.AddNetworkString("expCompanionCommand")

--- Sends a net message to open the quick command menu for a companion entity.
--- @param player Player The player to send the net message to.
--- @param entity Entity The companion entity to open the quick command menu for.
function Schema.companion.PlayerQuickCommandMenu(player, entity)
	local owner = entity:GetDTEntity(0) -- Helix uses GetDTEntity(0) for owner

	net.Start("expCompanionCommand")
	net.WriteEntity(entity)
	net.WriteString(entity:GetCommand() or "")
	net.WriteBool(owner == player)
	net.Send(player)
end

--- Gets whether the player can command a companion entity.
--- @param player Player The player to check.
--- @param companion Entity The companion entity to check.
--- @return boolean, string? # Whether the player can command the companion, and an optional failure message.
function Schema.companion.CanPlayerCommand(player, companion)
	local owner = companion:GetDTEntity(0)

	if (owner == player) then
		return Schema.companion.PlayerIsCloseEnoughToCommand(player, companion)
	end

	-- Allow friendly players to command the companion to do something,
	-- unless the companion is set to follow the owner right now.
	local disposition, priority = companion:Disposition(player)

	if (disposition == D_LI) then
		if (companion:GetFriendlyToFollow() == owner) then
			return false, "You cannot command this companion while it is following its owner!"
		end

		return Schema.companion.PlayerIsCloseEnoughToCommand(player, companion)
	end

	return false, "This companion won't listen to you!"
end

--- Attempts to execute a command on a companion entity.
--- @param player Player The player executing the command.
--- @param companion Entity The companion entity to execute the command on.
--- @param command string|table The command
--- @param itemInstance ItemInstance The item instance that the companion is associated with.
--- @return boolean
function Schema.companion.PlayerTryCommand(player, companion, command, itemInstance)
	if (not IsValid(companion)) then
		player:Notify("This companion is not valid!")
		return false
	end

	local canCommand, failureMessage = Schema.companion.CanPlayerCommand(player, companion)

	if (not canCommand) then
		player:Notify(failureMessage)
		return false
	end

	if (istable(command)) then
		local commandInfo = command
		command = command[1]
		local targetEntIndex = tonumber(commandInfo[2])

		if (not targetEntIndex) then
			player:Notify("This target is not valid!")
			return false
		end

		local target = Entity(targetEntIndex)

		if (not IsValid(target)) then
			player:Notify("This target is no longer valid!")
			return false
		end

		if (command == "attack") then
			companion:ClearSchedule()
			companion:AddEntityRelationship(target, D_HT, 99)
			companion:SetTargetEntity(target)
			companion:SetCommand("attack")
			companion:SetFriendlyToFollow()

			if (target == player) then
				command = "attack you"
			elseif (target:IsPlayer()) then
				command = "attack " .. target:Name()
			else
				command = "attack this entity"
			end
		elseif (command == "train") then
			local owner = companion:GetDTEntity(0)

			if (owner ~= player) then
				player:Notify("You cannot train this companion, as you are not the owner!")
				return false
			end

			local dispositionName = commandInfo[3]
			local dispositionInfo = Schema.companion.TRAINING_MAP[dispositionName]

			if (dispositionInfo) then
				local disposition = dispositionInfo.disposition
				local value = dispositionInfo.value or 99
				local targetName = target:IsPlayer() and target:Name() or "this entity"

				if (itemInstance) then
					local dispositions = itemInstance:GetData("dispositions", {})
					local key

					if (target:IsPlayer()) then
						local character = target:GetCharacter()
						key = character and character:GetID() or nil
					else
						key = target:GetClass()
					end

					if (key) then
						if (dispositionInfo == Schema.companion.DEFAULT_DISPOSITION) then
							-- Save space by removing the default disposition.
							dispositions[key] = nil
						else
							-- Store the disposition towards the target player.
							dispositions[key] = { disposition, value }
						end

						itemInstance:SetData("dispositions", dispositions)

						if (target:IsPlayer()) then
							Schema.companion.ResetSavedDispositionForPlayer(target, companion, itemInstance)
						else
							Schema.companion.ResetSavedDispositionForEntity(target, companion, itemInstance)
						end
					end
				end

				player:Notify("You have trained your companion to " ..
					dispositionInfo.message .. " " .. targetName .. ".")
				return true
			else
				player:Notify("This disposition is not valid!")
				return false
			end
		else
			command = nil
		end
	elseif (command == "patrol") then
		companion:ClearSchedule()
		companion:SetCommand("patrol")
		companion:SetFriendlyToFollow()
	elseif (command == "stay") then
		companion:SetTargetEntity(nil)
		companion:ClearSchedule()
		companion:SetCommand("stay")
		companion:SetFriendlyToFollow()
	elseif (command == "follow") then
		companion:SetTargetEntity(nil)
		companion:ClearSchedule()
		companion:SetCommand("follow")
		companion:SetFriendlyToFollow(player)
	elseif (command == "stop") then
		local currentTarget = companion.targetingSystem.currentTarget

		companion:SetTargetEntity(nil)
		companion:ClearSchedule()
		companion:SetCommand("stay")
		companion:SetFriendlyToFollow()

		if (IsValid(currentTarget)) then
			if (currentTarget == player) then
				companion:AddEntityRelationship(player, D_LI, 99)
				player:Notify("You have stopped your companion from attacking you.")
			else
				companion:AddEntityRelationship(currentTarget, D_NU, 99)

				if (currentTarget:IsPlayer()) then
					player:Notify("You have stopped your companion from attacking " .. currentTarget:Name() .. ".")
				else
					player:Notify("You have stopped your companion from attacking this entity.")
				end
			end
		else
			player:Notify("You have stopped your companion.")
		end
	end

	if (not command) then
		player:Notify("This command is not valid!")
		return false
	end

	player:Notify("You have set your companion to " .. command .. ".")

	return true
end

--- Spawns a companion entity into the world.
--- @param entityID string The entity ID of the companion to spawn.
--- @param client Player The player that is spawning the companion.
--- @param position Vector The position to spawn the companion at.
--- @param itemInstance ItemInstance The item instance that the companion is associated with.
--- @return Entity
function Schema.companion.Spawn(entityID, client, position, itemInstance)
	local companion = ents.Create(entityID)
	companion:SetPos(position + Vector(0, 0, 16))
	companion:SetCommand("follow")
	companion:SetFriendlyToFollow(client)
	companion:SetItem(itemInstance, client)
	companion:SetDisplayName(itemInstance.name)
	companion:Spawn()

	Schema.companion.spawned[companion] = true

	Schema.MakeFlushToGround(companion, position)

	-- Set owner using Helix's property system
	companion:SetDTEntity(0, client)

	itemInstance:SetData("spawnedState", { player = client:SteamID(), entity = companion:EntIndex() })
	client.expCompanion = {
		entity = companion,
		item = itemInstance
	}

	Schema.companion.ResetSavedDispositions(companion, itemInstance)

	return companion
end

--- Removes a companion entity from the world.
--- @param client Player The player that is removing the companion.
--- @param itemInstance ItemInstance The item instance that the companion is associated with.
function Schema.companion.Remove(client, itemInstance)
	local companion = client.expCompanion
	local isEntityValid = companion and IsValid(companion.entity)

	if (isEntityValid) then
		itemInstance:SetData("companionHealth", math.max(0, companion.entity:Health()))
	end

	itemInstance:SetData("spawnedState", nil)

	if (not companion) then
		return
	end

	if (isEntityValid) then
		Schema.companion.spawned[companion.entity] = nil
		companion.entity:Remove()
	end

	client.expCompanion = nil
end

--- Resets dispositions for when spawning a companion.
--- @param companion Entity The companion entity to reset dispositions for.
--- @param itemInstance ItemInstance The item instance that the companion is associated with.
function Schema.companion.ResetSavedDispositions(companion, itemInstance)
	local dispositions = itemInstance:GetData("dispositions", {})

	if (not dispositions or table.Count(dispositions) == 0) then
		return
	end

	-- First have all players get setup based on their character ID
	for _, player in ipairs(player.GetAll()) do
		Schema.companion.ResetSavedDispositionForPlayer(player, companion, itemInstance)
	end

	-- Now check if any entity classes need to be setup
	for entityClass, disposition in pairs(dispositions) do
		if (isstring(entityClass)) then
			local entities = ents.FindByClass(entityClass)

			for _, entity in ipairs(entities) do
				Schema.companion.ResetSavedDispositionForEntity(entity, companion, itemInstance)
			end
		end
	end
end

--- Sets the default disposition for a companion entity towards a player.
--- @param player Player The player to set the default disposition for.
--- @param companion Entity The companion entity to set the default disposition for.
--- @param itemInstance ItemInstance The item instance that the companion is associated with.
function Schema.companion.SetDefaultDispositionForPlayer(player, companion, itemInstance)
	local defaultDisposition = itemInstance.defaultDisposition or { D_NU, 99 }

	companion:AddEntityRelationship(player, defaultDisposition[1], defaultDisposition[2])
end

--- Resets a disposition towards a player when spawning a companion.
--- @param player Player The player to reset the disposition for.
--- @param companion Entity The companion entity to reset the disposition for.
--- @param itemInstance ItemInstance The item instance that the companion is associated with.
--- @return boolean # Whether the disposition was reset, or the default disposition was used.
function Schema.companion.ResetSavedDispositionForPlayer(player, companion, itemInstance)
	local dispositions = itemInstance:GetData("dispositions", {})

	if (not dispositions or table.Count(dispositions) == 0) then
		Schema.companion.SetDefaultDispositionForPlayer(player, companion, itemInstance)
		return false
	end

	local character = player:GetCharacter()
	local key = character and character:GetID() or nil
	local disposition = dispositions[key]

	if (not disposition) then
		Schema.companion.SetDefaultDispositionForPlayer(player, companion, itemInstance)
		return false
	end

	companion:AddEntityRelationship(player, disposition[1], disposition[2])

	return true
end

--- Sets up a disposition for when a player spawns into the world.
--- @param player Player The player to set up the disposition for.
function Schema.companion.SetupDispositionsForPlayer(player)
	for companion, _ in pairs(Schema.companion.spawned) do
		if (IsValid(companion)) then
			local itemInstance = companion:GetItem()

			Schema.companion.ResetSavedDispositionForPlayer(player, companion, itemInstance)
		end
	end
end

--- Sets up a disposition for when an entity when spawning a companion.
--- @param entity Entity The entity to set up the disposition for.
--- @param companion Entity The companion entity to set up the disposition for.
--- @param itemInstance ItemInstance The item instance that the companion is associated with.
function Schema.companion.ResetSavedDispositionForEntity(entity, companion, itemInstance)
	local dispositions = itemInstance:GetData("dispositions", {})

	if (not dispositions or table.Count(dispositions) == 0) then
		return
	end

	local key = entity:GetClass()
	local disposition = dispositions[key]

	if (not disposition) then
		return
	end

	companion:AddEntityRelationship(entity, disposition[1], disposition[2])
end

--- Sets up disposition for when an entity spawns into the world.
--- @param entity Entity The entity to set up the disposition for.
function Schema.companion.SetupDispositionsForEntity(entity)
	for companion, _ in pairs(Schema.companion.spawned) do
		if (IsValid(companion)) then
			local itemInstance = companion:GetItem()

			Schema.companion.ResetSavedDispositionForEntity(entity, companion, itemInstance)
		end
	end
end

-- Hook to setup dispositions when players spawn
hook.Add("PlayerLoadedCharacter", "Schema.companion.SetupDispositions", function(player, character)
	timer.Simple(1, function() -- Small delay to ensure everything is loaded
		if IsValid(player) then
			Schema.companion.SetupDispositionsForPlayer(player)
		end
	end)
end)

-- Hook to setup dispositions when entities spawn
hook.Add("OnEntityCreated", "Schema.companion.SetupDispositions", function(entity)
	timer.Simple(0.1, function() -- Small delay to ensure entity is fully created
		if IsValid(entity) then
			Schema.companion.SetupDispositionsForEntity(entity)
		end
	end)
end)
