--- Client library to work with companion NPC's.
Schema.companion = ix.util.GetOrCreateLibrary("companion")

net.Receive("expCompanionCommand", function(length)
	local entity = net.ReadEntity()
	local currentCommand = net.ReadString()
	local isOwner = net.ReadBool()

	if (not IsValid(entity)) then
		ix.util.SchemaErrorNoHaltFormatted("Attempted to interact with an invalid entity!")
		return
	end

	local menu = Schema.companion.CreateQuickCommandMenu(entity, nil, isOwner, currentCommand)
	menu:Open(ScrW() * 0.5, ScrH() * 0.5)
end)

--- Builds and opens the quick command menu for a companion entity to show available options.
--- @param entityOrInstanceID Entity|string The companion entity to open the quick command menu for.
--- @param callback? fun(action: string, data?: any) The callback to execute when a command is selected. Typically one that sends an action net message to the server.
--- @param isOwner boolean Whether the player is the owner of the companion entity.
--- @param currentCommand? string The current command that the companion is executing.
--- @return DMenu # The quick command menu.
function Schema.companion.CreateQuickCommandMenu(entityOrInstanceID, callback, isOwner, currentCommand)
	local playerRange = 512
	local menu = DermaMenu()
	local entity
	local instanceID
	local itemInstance

	if (isstring(entityOrInstanceID)) then
		instanceID = entityOrInstanceID
		itemInstance = ix.item.instances[tonumber(instanceID)]
	else
		entity = entityOrInstanceID
		instanceID = entity:GetItemInstanceID()
		itemInstance = ix.item.instances[tonumber(instanceID)]
	end

	callback = callback or function(action, command)
		local inventory = ix.item.inventories[itemInstance.invID]

		inventory:NetworkAction(action, instanceID, {
			command = command,
		})
	end

	menu:AddOption("Despawn", function()
		callback("Toggle")
	end)

	if (IsValid(entity)) then
		local canCommand, fault = Schema.companion.PlayerIsCloseEnoughToCommand(LocalPlayer(), entity)

		if (not canCommand) then
			menu:AddOption(fault, function() end):SetEnabled(false)
			return menu
		end

		-- For some reason, the entity's command is not being updated. So we wont
		-- show these options in the unequip menu.
		if (currentCommand) then
			if (currentCommand ~= "patrol") then
				local option = menu:AddOption("Patrol", function()
					callback("Command", "patrol")
				end)
				option:SetIcon("icon16/arrow_refresh.png")
			end

			if (currentCommand ~= "stay") then
				local option = menu:AddOption("Stay", function()
					callback("Command", "stay")
				end)
				option:SetIcon("icon16/arrow_down.png")
			end

			if (currentCommand ~= "follow") then
				local option = menu:AddOption("Follow", function()
					callback("Command", "follow")
				end)
				option:SetIcon("icon16/arrow_join.png")
			end
		end

		local function getEnemyName(enemy)
			if (enemy:IsPlayer()) then
				return enemy:Name()
			end

			return "this entity"
		end

		local function setupOptionTargetHalo(option, targetEntity)
			option.Think = function(option)
				if (option.Hovered) then
					halo.Add({ targetEntity }, color_white, 1, 1, 2, true, false)
				end
			end
		end

		local function addOptionsForNearbyPlayers(subMenu, optionCallback, filterCallback)
			for _, player in ipairs(ents.FindInSphere(entity:GetPos(), playerRange)) do
				if (player:IsPlayer() and (not filterCallback or filterCallback(player))) then
					local name = getEnemyName(player)

					local option = subMenu:AddOption(name, function()
						optionCallback(player)
					end)
					setupOptionTargetHalo(option, player)
				end
			end
		end

		if (currentCommand == "attack") then
			local option = menu:AddOption("Stop Attacking", function()
				callback("Command", "stop")
			end)
			option:SetIcon("icon16/cross.png")
		else
			local subMenu, option = menu:AddSubMenu("Attack")
			option:SetIcon("icon16/gun.png")

			addOptionsForNearbyPlayers(subMenu, function(enemy)
				callback("Command", { "attack", enemy:EntIndex() })
			end)

			hook.Run("AdjustCompanionAttackMenu", entity, itemInstance, subMenu, callback)
		end

		local trainingSubMenu, option = menu:AddSubMenu("Train")

		if (not isOwner) then
			option:SetEnabled(false)
		else
			local sortedRelationshipTypes = table.ClearKeys(Schema.companion.TRAINING_MAP)

			table.sort(sortedRelationshipTypes, function(a, b)
				return a.order < b.order
			end)

			for _, relationshipType in ipairs(sortedRelationshipTypes) do
				local subMenu, option = trainingSubMenu:AddSubMenu(
					relationshipType.message:sub(1, 1):upper() .. relationshipType.message:sub(2))
				option:SetIcon(relationshipType.icon)

				addOptionsForNearbyPlayers(subMenu, function(target)
					callback("Command", { "train", target:EntIndex(), relationshipType.key })
				end, function(target)
					local currentRelation = Schema.companion.GetDisposition(itemInstance, target)
					return currentRelation ~= relationshipType.disposition
				end)

				hook.Run("AdjustCompanionTrainingMenu", entity, itemInstance, relationshipType.key, subMenu,
					callback, relationshipType)

				if (subMenu:ChildCount() == 0) then
					subMenu:AddOption("<none>", function() end):SetEnabled(false)
				end
			end
		end
	end

	return menu
end

--- Gets the relationship between a companion entity and a target entity.
--- @param itemInstanceOrEntity ItemInstance|Entity The item instance of, or the companion entity.
--- @param target Entity The target entity to get the relationship with.
--- @return number # The dispisiton value.
function Schema.companion.GetDisposition(itemInstanceOrEntity, target)
	local itemInstance

	if (isentity(itemInstanceOrEntity)) then
		itemInstance = ix.item.instances[tonumber(itemInstanceOrEntity:GetItemInstanceID())]
	else
		itemInstance = itemInstanceOrEntity
	end

	local characterKey

	if (target:IsPlayer()) then
		local character = target:GetCharacter()
		characterKey = character and character:GetID() or nil

		if (not characterKey) then
			return Schema.companion.DEFAULT_DISPOSITION.disposition
		end
	else
		characterKey = target:GetClass()
	end

	local dispositions = itemInstance:GetData("dispositions", {})
	local relationship = dispositions[characterKey]

	if (not relationship) then
		return Schema.companion.DEFAULT_DISPOSITION.disposition
	end

	return relationship[1]
end
