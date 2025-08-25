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

net.Receive("expChemistryStationMenu", function()
	local station = net.ReadEntity()
	if (not IsValid(station)) then return end

	local frame = vgui.Create("expFrame")
	frame:SetSize(300, 200)
	frame:SetTitle("Chemistry Station")
	frame:MakePopup()

	-- Distillation button
	local distillBtn = frame:Add("expButton")
	distillBtn:Dock(LEFT)
	distillBtn:SetText("Distill Items")
	distillBtn:SizeToContents()
	distillBtn.DoClick = function()
		frame:Close()

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
	end

	-- Combination button
	local combineBtn = frame:Add("expButton")
	combineBtn:Dock(LEFT)
	combineBtn:DockMargin(5, 0, 0, 0)
	combineBtn:SetText("Combine Items")
	combineBtn:SizeToContents()
	combineBtn.DoClick = function()
		frame:Close()

		local character = LocalPlayer():GetCharacter()
		local inventory = character:GetInventory()

		local selector = PLUGIN:CreateItemSelector(inventory, nil, function(selectedItems)
			local selectedItemIDs = {}

			for _, item in ipairs(selectedItems) do
				table.insert(selectedItemIDs, item.id)
			end

			net.Start("expChemistryCombine")
			net.WriteEntity(station)
			net.WriteTable(selectedItemIDs)
			net.SendToServer()
		end, 10)

		selector:SetTitle("Select Items to Combine")
	end

	frame:InvalidateChildren(true)

	frame:SizeToChildren(true, false)
	frame:Center()
end)

net.Receive("expWorkbenchMenu", function()
	local station = net.ReadEntity()
	if (not IsValid(station)) then return end

	local frame = vgui.Create("expFrame")
	frame:SetSize(300, 150)
	frame:SetTitle("Workbench")
	frame:Center()
	frame:MakePopup()

	-- Combination button
	local combineBtn = frame:Add("expButton")
	combineBtn:SetPos(20, 40)
	combineBtn:SetSize(260, 30)
	combineBtn:SetText("Combine Items")
	combineBtn.DoClick = function()
		frame:Close()

		local character = LocalPlayer():GetCharacter()
		local inventory = character:GetInventory()

		local selector = PLUGIN:CreateItemSelector(inventory, nil, function(selectedItems)
			net.Start("expWorkbenchCombine")
			net.WriteEntity(station)
			net.WriteTable(selectedItems)
			net.SendToServer()
		end, 10)

		selector:SetTitle("Select Items to Combine")
	end

	local closeBtn = frame:Add("expButton")
	closeBtn:SetPos(110, 90)
	closeBtn:SetSize(80, 25)
	closeBtn:SetText("Close")
	closeBtn.DoClick = function()
		frame:Close()
	end
end)
