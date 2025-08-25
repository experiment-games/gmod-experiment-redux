local PLUGIN = PLUGIN

function PLUGIN:CreateItemSelector(inventory, filterFunc, onConfirm, maxItems)
	local selector = vgui.Create("expItemSelector")
	selector:SetInventory(inventory, filterFunc)
	selector:SetOnConfirm(onConfirm)

	if (maxItems) then
		selector:SetMaxItems(maxItems)
	end

	return selector
end

--[[
	Net Messages
--]]

net.Receive("expOpenDistillationSelector", function()
	local station = net.ReadEntity()
	if (not IsValid(station)) then return end

	local character = LocalPlayer():GetCharacter()
	local inventory = character:GetInventory()

	local selector = PLUGIN:CreateItemSelector(inventory, function(item)
		return item.craftingDistillation ~= nil
	end, function(selectedItems)
		if (#selectedItems > 0) then
			net.Start("expChemistryDistill")
			net.WriteEntity(station)
			net.WriteUInt(selectedItems[1].id, 32)
			net.SendToServer()
		end
	end, 1)

	selector:SetTitle("Select Item to Distill")
end)

net.Receive("expOpenCombinationSelector", function()
	local station = net.ReadEntity()
	if (not IsValid(station)) then return end

	local character = LocalPlayer():GetCharacter()
	local inventory = character:GetInventory()

	local selector = PLUGIN:CreateItemSelector(inventory, nil, function(selectedItems)
		local selectedItemIDs = {}

		for _, item in ipairs(selectedItems) do
			table.insert(selectedItemIDs, item.id)
		end

		net.Start("expCraftingCombine")
		net.WriteEntity(station)
		net.WriteTable(selectedItemIDs)
		net.SendToServer()
	end, 3)

	selector:SetTitle("Select Items to Combine")
end)
