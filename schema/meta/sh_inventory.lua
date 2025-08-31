local META = ix.meta.inventory

--- Returns a table of `Item`s by their base, also checking the base of their base.
-- @realm shared
-- @string baseID The base to search for.
-- @bool bOnlyMain Whether or not to exclude bags that are present from the search.
function META:GetItemsByNestedBase(baseID, bOnlyMain)
	local items = {}

	-- Goes through all items and for each item will recursively check their base to see if it matches the baseID
	-- If it does, the very child item will be added to the items table
	for _, item in pairs(self:GetItems(bOnlyMain)) do
		if (item:IsBasedOn(baseID)) then
			items[#items + 1] = item
		end
	end

	return items
end

-- Overrides GetItemCount in gamemode/core/meta/sh_inventory.lua
-- Source: https://github.com/Bilwin/helix-plugins/blob/main/stacks/sh_meta.lua
function META:GetItemCount(uniqueID, onlyMain)
	local count = 0
	local stacks

	for _, item in pairs(self:GetItems(onlyMain)) do
		if (item.uniqueID == uniqueID) then
			stacks = item.data.stacks

			if (stacks and stacks >= 2) then
				count = count + stacks
			else
				count = count + 1
			end
		end
	end

	return count
end

--- Go through the items, removing them (or taking from their stack) until we have enough
--- @param uniqueID string The unique ID of the item to remove.
--- @param amountToRemove number The amount of items to remove.
--- @param bOnlyMain boolean Whether or not to only remove items from the main inventory.
function META:RemoveStackedItem(uniqueID, amountToRemove, bOnlyMain)
	local items = self:GetItems(bOnlyMain)

	for _, item in pairs(items) do
		if (item.uniqueID ~= uniqueID) then
			continue
		end

		local stacks = item:GetData("stacks", 1)
		local toRemove = math.min(stacks, amountToRemove)

		if (toRemove == stacks) then
			item:Remove()
		else
			item:SetData("stacks", stacks - toRemove)
		end

		amountToRemove = amountToRemove - toRemove

		if (amountToRemove <= 0) then
			break
		end
	end
end

-- TODO: Write some tests for this and if it works, submit a PR to Helix to add this function to the core
--- Checks whether multiple items of the specified dimensions can fit in the inventory
-- This function simulates placing items to determine if the specified quantity will fit
-- @realm shared
-- @number w The width of each item
-- @number h The height of each item
-- @number quantity The number of items to check for
-- @bool[opt=false] onlyMain Whether to exclude bags from the search
-- @treturn[1] bool true if all items can fit
-- @treturn[1] table positions Table of {x, y, invID} positions where items can be placed
-- @treturn[2] bool false if not all items can fit
-- @treturn[2] number maxFit The maximum number of items that can actually fit
function META:CanItemsFit(w, h, quantity, onlyMain)
	w = w or 1
	h = h or 1
	quantity = quantity or 1

	if (quantity <= 0) then
		return true, {}
	end

	-- If single item is too big for this inventory, check bags only
	if (w > self.w or h > self.h) then
		if (onlyMain == true) then
			return false, 0
		end

		local bags = self:GetBags()
		local totalPositions = {}
		local remainingQuantity = quantity

		for _, invID in ipairs(bags) do
			local bagInv = ix.item.inventories[invID]
			if (bagInv) then
				local canFit, positions = bagInv:CanItemsFit(w, h, remainingQuantity, true)
				if (canFit) then
					-- Add bag inventory ID to each position
					for _, pos in ipairs(positions) do
						pos[3] = invID
						table.insert(totalPositions, pos)
					end
					return true, totalPositions
				else
					-- Partial fit in this bag
					for _, pos in ipairs(positions) do
						pos[3] = invID
						table.insert(totalPositions, pos)
					end
					remainingQuantity = remainingQuantity - #positions
					if (remainingQuantity <= 0) then
						return true, totalPositions
					end
				end
			end
		end

		return false, #totalPositions
	end

	-- Create a copy of the current slots to simulate placement
	local simulatedSlots = {}
	for x = 1, self.w do
		simulatedSlots[x] = {}
		if (self.slots[x]) then
			for y = 1, self.h do
				simulatedSlots[x][y] = self.slots[x][y]
			end
		end
	end

	local positions = {}
	local placed = 0

	-- Try to place items in the main inventory
	for i = 1, quantity do
		local foundSpot = false

		-- Search for empty spot
		for y = 1, self.h - (h - 1) do
			for x = 1, self.w - (w - 1) do
				-- Check if this spot can fit the item
				local canPlace = true
				for x2 = 0, w - 1 do
					for y2 = 0, h - 1 do
						if (simulatedSlots[x + x2][y + y2] ~= nil) then
							canPlace = false
							break
						end
					end
					if (! canPlace) then break end
				end

				if (canPlace) then
					-- Mark the spot as occupied in simulation
					for x2 = 0, w - 1 do
						for y2 = 0, h - 1 do
							simulatedSlots[x + x2][y + y2] = true -- placeholder item
						end
					end

					table.insert(positions, { x, y, self:GetID() })
					placed = placed + 1
					foundSpot = true
					break
				end
			end
			if (foundSpot) then break end
		end

		if (! foundSpot) then
			break -- Can't place any more in main inventory
		end
	end

	-- If we haven't placed all items and bags are allowed, check bags
	if (placed < quantity and onlyMain ~= true) then
		local bags = self:GetBags()
		local remainingQuantity = quantity - placed

		for _, invID in ipairs(bags) do
			local bagInv = ix.item.inventories[invID]
			if (bagInv and remainingQuantity > 0) then
				local canFitBag, bagPositions = bagInv:CanItemsFit(w, h, remainingQuantity, true)

				-- Add what we can from this bag
				local actuallyFit = math.min(#bagPositions, remainingQuantity)
				for i = 1, actuallyFit do
					bagPositions[i][3] = invID -- Set the inventory ID
					table.insert(positions, bagPositions[i])
					placed = placed + 1
					remainingQuantity = remainingQuantity - 1
				end

				if (remainingQuantity <= 0) then
					break
				end
			end
		end
	end

	if (placed >= quantity) then
		return true, positions
	else
		return false, placed
	end
end

if (CLIENT) then
	--- Networks inventory actions to the server.
	--- @param action string The action to perform (e.g., "transfer", "use", etc.).
	--- @param itemID number The ID of the item to act upon.
	--- @param data? table Additional data relevant to the action.
	function META:NetworkAction(action, itemID, data)
		net.Start("ixInventoryAction")
		net.WriteString(action)
		net.WriteUInt(itemID, 32)
		net.WriteUInt(self:GetID(), 32)
		net.WriteTable(data or {})
		net.SendToServer()
	end
end
