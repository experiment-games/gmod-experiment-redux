-- Source: https://github.com/Bilwin/helix-plugins/blob/main/stacks/items/base/sh_stackable.lua
local ITEM = ITEM

-- This file is named sh__stackable.lua so it's loaded before sh_materials.lua (which depends on this base item)
ITEM.uniqueID = "base_stackable"
ITEM.name = "Stackable Items Base"
ITEM.description = "Stackable Item"
ITEM.category = "Stackable"
ITEM.model = "models/props_c17/TrapPropeller_Lever.mdl"

if (CLIENT) then
	function ITEM.PaintOver(icon, item, w, h)
		local isMax = item:GetData("stacks", 1) == item:GetMaxStacks()

		draw.SimpleTextOutlined(
			item:GetData("stacks", 1),
			"DermaDefault",
			w - 5,
			h - 5,
			isMax and Color(120, 120, 120, 200) or Color(255, 255, 255, 200),
			TEXT_ALIGN_RIGHT,
			TEXT_ALIGN_BOTTOM,
			1,
			color_black
		)
	end
end

function ITEM:GetMaxStacks()
	return self.maxStacks or 16
end

function ITEM:CanStackWith(otherItem)
	local currentItemStacks = self:GetData("stacks", 1)
	local otherItemStacks = otherItem:GetData("stacks", 1)
	local totalStacks = otherItemStacks + currentItemStacks

	if (self.uniqueID ~= otherItem.uniqueID) then
		return false, "You can't stack these items."
	end

	if (self == otherItem) then
		return false, "You can't stack an item with itself."
	end

	if (totalStacks > self:GetMaxStacks()) then
		return false, "These items can't be stacked any further."
	end

	-- Ensure the items have exactly the same data (except for stacks)
	local bothKeys = table.Add(
		table.GetKeys(self.data or {}),
		table.GetKeys(otherItem.data or {})
	)

	for _, key in pairs(bothKeys) do
		if (key ~= "stacks" and self:GetData(key) ~= otherItem:GetData(key)) then
			return false, "These items have different properties and can't be stacked."
		end
	end

	return true
end

function ITEM:Stack(otherItem)
	local currentItemStacks = self:GetData("stacks", 1)
	local otherItemStacks = otherItem:GetData("stacks", 1)
	local totalStacks = otherItemStacks + currentItemStacks

	self:SetData(
		"stacks",
		totalStacks,
		ix.inventory.Get(self.invID):GetReceivers()
	)
	otherItem:Remove()
end

ITEM.functions.combine = {
	name = "Combine",
	icon = "icon16/arrow_in.png",
	OnRun = function(item, data)
		local otherItem = ix.item.instances[data[1]]
		local canStack, message = item:CanStackWith(otherItem)
		local client = item.player

		if (not canStack) then
			client:Notify(message)

			return false
		end

		item:Stack(otherItem)

		return false
	end,

	OnCanRun = function(firstItem, data)
		return true
	end
}

ITEM.functions.split = {
	name = "Split",
	icon = "icon16/arrow_divide.png",
	OnRun = function(item)
		local client = item.player
		local character = client:GetCharacter()
		local itemUniqueID = item.uniqueID
		local stacks = item:GetData("stacks", 1)

		client:RequestString(
			"Split",
			"Please enter how many items you want to split",
			function(splitStack)
				if (not isnumber(tonumber(splitStack))) then
					client:Notify("Please enter a `number`")
					return false
				end

				local cleanSplitStack = math.Round(math.abs(tonumber(splitStack)))

				if (cleanSplitStack >= stacks) then
					return false
				end

				local stackedCount = (stacks - cleanSplitStack)
				local stackData = { stacks = cleanSplitStack }

				client.expLastSplit = CurTime()

				if (not character:GetInventory():Add(itemUniqueID, 1, stackData)) then
					ix.item.Spawn(itemUniqueID, client, nil, angle_zero, stackData)
				end

				local inventory = ix.inventory.Get(item.invID)
				local receivers = nil

				-- World inventories don't have receivers (they don't even have the GetReceivers method)
				if (inventory and inventory:GetID() > 0) then
					if (inventory.GetReceivers) then
						receivers = inventory:GetReceivers()
					else
						-- https://github.com/experiment-games/gmod-experiment-redux/issues/114
						-- Shouldn't happen anymore, but leaving it here for a while just in case.
						-- TODO: Remove after 10-7-2024
						ix.util.SchemaError(
							"(Debugging) Inventory doesn't have a GetReceivers method, id of inventory: "
							.. tostring(item.invID)
						)
					end
				end

				item:SetData("stacks", stackedCount, receivers)
			end,
			"1"
		)

		return false
	end,

	OnCanRun = function(item)
		return (item:GetData("stacks", 1) ~= 1)
	end
}
