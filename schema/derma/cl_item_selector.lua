local PANEL = {}

AccessorFunc(PANEL, "title", "Title", FORCE_STRING)

function PANEL:Init()
	self:SetTall(500)
	self:SetTitle("Select Items")
	self:MakePopup()

	self.selectedItems = {}
	self.maxItems = 10
	self.slotSize = 64

	-- Create confirm button
	self.confirmBtn = self:Add("expButton")
	self.confirmBtn:SetText("Confirm")
	self.confirmBtn:SizeToContents()
	self.confirmBtn:Dock(BOTTOM)
	self.confirmBtn.DoClick = function()
		if (self.onConfirm) then
			self.onConfirm(self.selectedItems)
		end
		self:Close()
	end

	self.itemsPanel = self:Add("DSizeToContents")
	self.itemsPanel:SetSize(500, 500 - self.confirmBtn:GetTall() - 5)
	self.itemsPanel:SetSizeY(false)

	-- Create inventory panel
	self.inventory = self.itemsPanel:Add("ixInventory")
	self.inventory:Dock(LEFT)
	self.inventory:SetDraggable(false)

	-- Create selected items panel (now with slots)
	self.selectedPanel = self.itemsPanel:Add("EditablePanel")
	self.selectedPanel:Dock(LEFT)
	self.selectedPanel:SetWide(250)
	self.selectedPanel:Receiver("ixInventoryItem", function(pnl, panels, bDropped, menuIndex, x, y)
		self:ReceiveSlotDrop(panels, bDropped, menuIndex, x, y)
	end)

	self.selectedPanel.Paint = function(pnl, w, h)
		surface.SetDrawColor(40, 40, 40, 200)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(60, 60, 60)
		surface.DrawOutlinedRect(0, 0, w, h)

		draw.SimpleText("Selected Items", "DermaDefault", w / 2, 5, Color(255, 255, 255), TEXT_ALIGN_CENTER)
	end

	-- Create item slots
	self.itemSlots = {}
	self:CreateItemSlots()

	self.btnClose = self:Add("expCloseButton")
	self.btnClose:SetPaintedManually(true)
	self.btnClose.DoClick = function(button)
		self:Close()
	end

	-- Delay centering until next frame when inventory has sized
	timer.Simple(0, function()
		if (not IsValid(self)) then
			return
		end

		self:Center()

		-- Position the confirm and cancel buttons below it all
		self.confirmBtn:CenterHorizontal()
		self.confirmBtn:AlignBottom(-self.confirmBtn:GetTall())
	end)
end

function PANEL:CreateItemSlots()
	local slotsPerRow = math.floor((self.selectedPanel:GetWide() - 10) / (self.slotSize + 2))
	local rows = math.ceil(self.maxItems / slotsPerRow)

	for i = 1, self.maxItems do
		local row = math.floor((i - 1) / slotsPerRow)
		local col = (i - 1) % slotsPerRow

		local slot = self.selectedPanel:Add("EditablePanel")
		slot:SetSize(self.slotSize, self.slotSize)
		slot:SetMouseInputEnabled(true)
		slot:SetPos(5 + col * (self.slotSize + 2), 25 + row * (self.slotSize + 2))
		slot.slotIndex = i
		slot.item = nil

		slot.Paint = function(pnl, w, h)
			surface.SetDrawColor(20, 20, 20, 150)
			surface.DrawRect(0, 0, w, h)

			local borderColor = Color(80, 80, 80)

			if (slot.item) then
				borderColor = Color(255, 255, 255)
			end

			surface.SetDrawColor(borderColor)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		slot.OnMouseReleased = function(_, mouseButton)
			if (mouseButton == MOUSE_FIRST) then
				if (slot.item) then
					self:RemoveItemFromSlot(i)
				end
			end
		end

		self.itemSlots[i] = slot
	end
end

function PANEL:ReceiveSlotDrop(panels, bDropped, menuIndex, x, y)
	if (! bDropped or ! panels[1]) then
		return
	end

	local draggedPanel = panels[1]
	local item = draggedPanel:GetItemTable()

	if (! item) then
		return
	end

	-- Find which slot we dropped on
	local slotIndex = self:GetSlotAtPosition(x, y)
	if (! slotIndex) then
		return
	end

	-- Check if item is already selected
	for i, selectedItem in pairs(self.selectedItems) do
		if (selectedItem.id == item.id) then
			return -- Item already selected
		end
	end

	-- Add item to slot
	self:AddItemToSlot(item, slotIndex)
end

function PANEL:GetSlotAtPosition(x, y)
	for i, slot in pairs(self.itemSlots) do
		local slotX, slotY = slot:GetPos()
		local slotW, slotH = slot:GetSize()

		if (x >= slotX and x <= slotX + slotW and y >= slotY and y <= slotY + slotH) then
			return i
		end
	end

	return nil
end

function PANEL:AddItemToSlot(item, slotIndex)
	local slot = self.itemSlots[slotIndex]
	if (! slot) then
		return
	end

	-- Remove item from previous slot if it exists
	if (slot.item) then
		self:RemoveItemFromSlot(slotIndex)
	end

	-- Add the item
	slot.item = item
	table.insert(self.selectedItems, item)

	-- Create visual representation
	if (IsValid(slot.itemIcon)) then
		slot.itemIcon:Remove()
	end

	slot.itemIcon = slot:Add("SpawnIcon")
	slot.itemIcon:SetSize(self.slotSize - 4, self.slotSize - 4)
	slot.itemIcon:SetPos(2, 2)
	slot.itemIcon:SetModel(item:GetModel())
	slot.itemIcon:SetMouseInputEnabled(false)

	-- Set tooltip
	slot.itemIcon:SetTooltip(item:GetName())

	-- In the inventory, make the item now disabled from dragging
	self:SetItemIconEnabled(self.inventory.panels[item.id], false)
end

function PANEL:RemoveItemFromSlot(slotIndex)
	local slot = self.itemSlots[slotIndex]
	if (! slot or ! slot.item) then
		return
	end

	-- Remove from selected items
	for i, selectedItem in pairs(self.selectedItems) do
		if (selectedItem.id == slot.item.id) then
			table.remove(self.selectedItems, i)
			break
		end
	end

	self:SetItemIconEnabled(self.inventory.panels[slot.item.id], true)

	-- Clear slot
	slot.item = nil

	if (IsValid(slot.itemIcon)) then
		slot.itemIcon:Remove()
	end
end

function PANEL:SetInventory(inventory, filterFunc)
	if (not inventory) then return end

	self.inventory:SetInventory(inventory, true)
	self.filterFunc = filterFunc

	-- Override the inventory panels to allow dragging
	for _, panel in pairs(self.inventory.panels) do
		if (IsValid(panel)) then
			local item = panel:GetItemTable()

			self:SetItemIconEnabled(panel, not filterFunc or filterFunc(item))
		end
	end
end

function PANEL:SetItemIconEnabled(icon, enabled)
	if (enabled) then
		icon:SetAlpha(255)
		icon:SetCursor("hand")
		icon:Droppable("ixInventoryItem")
		icon:SetMouseInputEnabled(true)
	else
		icon:SetAlpha(100)
		icon:SetMouseInputEnabled(false)
	end
end

function PANEL:SetOnConfirm(func)
	self.onConfirm = func
end

function PANEL:SetMaxItems(max)
	self.maxItems = max

	-- Recreate slots with new max
	for _, slot in pairs(self.itemSlots or {}) do
		if (IsValid(slot)) then
			slot:Remove()
		end
	end

	self.itemSlots = {}
	self:CreateItemSlots()
end

function PANEL:GetSelectedItems()
	return self.selectedItems
end

function PANEL:PerformLayout()
	local totalWidth = self.inventory:GetWide() + self.selectedPanel:GetWide()

	if (self:GetWide() ~= totalWidth) then
		self:SetWide(totalWidth)
		self:Center()
	end

	self.btnClose:SetSize(32, 32)
	self.btnClose:SetPos(self:GetWide() - 28, -4)
end

function PANEL:Paint(width, height)
	draw.SimpleText(
		self.title or "",
		"ixSmallBoldFont",
		width * .5,
		-5,
		Color(255, 255, 255),
		TEXT_ALIGN_CENTER,
		TEXT_ALIGN_BOTTOM
	)
end

function PANEL:PaintOver(width, height)
	DisableClipping(true)
	self.btnClose:PaintManual()
	DisableClipping(false)
end

function PANEL:Close()
	self:Remove()
end

vgui.Register("expItemSelector", PANEL, "EditablePanel")
