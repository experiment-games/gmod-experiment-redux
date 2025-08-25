local PANEL = {}

AccessorFunc(PANEL, "title", "Title", FORCE_STRING)

function PANEL:Init()
	self:SetSize(600, 600)
	self:SetTitle("Select Items")
	self:MakePopup()

	self.selectedItems = {}
	self.maxItems = 10
	self.slotSize = 96

	-- Create selected items panel
	self.selectedPanel = self:Add("EditablePanel")
	self.selectedPanel:Dock(TOP)
	self.selectedPanel:SetTall(self.slotSize + 10)

	self.selectedPanel:Receiver("ixInventoryItem", function(pnl, panels, bDropped, menuIndex, x, y)
		self:ReceiveSlotDrop(panels, bDropped, menuIndex, x, y)
	end)

	-- Create confirm button
	self.confirmBtn = self:Add("expButton")
	self.confirmBtn:SetText("Confirm")
	self.confirmBtn:SizeToContents()
	self.confirmBtn:Dock(TOP)
	self.confirmBtn:DockMargin(0, 10, 0, 10)
	self.confirmBtn.DoClick = function()
		if (self.onConfirm) then
			self.onConfirm(self.selectedItems)
		end
		self:Close()
	end

	self.itemsScrollPanel = self:Add("DScrollPanel")
	self.itemsScrollPanel:Dock(TOP)
	self.itemsScrollPanel:SetSize(self:GetWide(),
		self:GetTall() - self.selectedPanel:GetTall() - self.confirmBtn:GetTall() - 50)

	self.itemsPanel = self.itemsScrollPanel:Add("DSizeToContents")
	self.itemsPanel:Dock(TOP)
	self.itemsPanel:SetSizeX(false)

	-- Create inventory panel
	self.inventory = self.itemsPanel:Add("ixInventory")
	self.inventory:SetDraggable(false)

	-- Create item slots
	self.itemSlots = {}
	self:CreateItemSlots()

	self.btnClose = self:Add("expCloseButton")
	self.btnClose:SetPaintedManually(true)
	self.btnClose.DoClick = function(button)
		self:Close()
	end

	self:Center()
end

function PANEL:PositionItemSlots()
	if not self.itemSlots then return end

	-- Calculate space-between positioning
	local containerWidth = self.selectedPanel:GetWide()
	local margins = 10 -- 5px on each side
	local availableWidth = containerWidth - margins
	local totalSlotWidth = self.maxItems * self.slotSize

	-- Ensure we don't exceed available space
	if (totalSlotWidth > availableWidth) then
		-- If slots don't fit, fall back to minimal spacing
		local spacing = 2
		for i, slot in pairs(self.itemSlots) do
			if (IsValid(slot)) then
				local col = i - 1
				local xPos = 5 + col * (self.slotSize + spacing)
				slot:SetPos(xPos, 5)
			end
		end

		return
	end

	if (self.maxItems == 1) then
		-- Center single slot
		local xPos = (containerWidth - self.slotSize) * .5
		self.itemSlots[1]:SetPos(xPos, 5)
	else
		-- Space-between: first slot at start, last at end, others evenly spaced
		local totalSpacing = availableWidth - totalSlotWidth
		local spacing = totalSpacing / (self.maxItems - 1)

		for i, slot in pairs(self.itemSlots) do
			if (IsValid(slot)) then
				local col = i - 1
				local xPos = 5 + col * (self.slotSize + spacing)
				slot:SetPos(xPos, 5)
			end
		end
	end
end

function PANEL:CreateItemSlots()
	for i = 1, self.maxItems do
		local slot = self.selectedPanel:Add("EditablePanel")
		slot:SetSize(self.slotSize, self.slotSize)
		slot:SetMouseInputEnabled(true)
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

	-- Position the slots after creation
	self:PositionItemSlots()
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

	slot:SetHelixTooltip(function(tooltip)
		ix.hud.PopulateItemTooltip(tooltip, item)
	end)

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

	slot:SetHelixTooltip(nil)

	-- Clear slot
	slot.item = nil

	if (IsValid(slot.itemIcon)) then
		slot.itemIcon:Remove()
	end
end

function PANEL:SetInventory(inventory, filterFunc)
	if (not inventory) then return end

	self.inventory:SetInventory(inventory)
	self.filterFunc = filterFunc

	-- Override the inventory panels to allow dragging
	for _, panel in pairs(self.inventory.panels) do
		if (IsValid(panel)) then
			local item = panel:GetItemTable()

			-- Only allow single stacks to be dragged on it
			if (item:IsBasedOn("base_stackable") and item:GetData("stacks", 1) > 1) then
				self:SetItemIconEnabled(panel, false)
				continue
			end

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
		icon:SetAlpha(50)
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
	local scrollBarWidth = 16
	local desiredWidth = self.inventory:GetWide() + scrollBarWidth

	if (self:GetWide() ~= desiredWidth) then
		self:SetWide(desiredWidth)
		self:Center()
	end

	self.btnClose:SetSize(32, 32)
	self.btnClose:SetPos(self:GetWide() - 28, -4)

	-- Reposition item slots when layout changes
	self:PositionItemSlots()
end

function PANEL:PaintOver(width, height)
	DisableClipping(true)

	draw.SimpleText(
		self.title or "",
		"ixSmallBoldFont",
		width * .5,
		-5,
		Color(255, 255, 255),
		TEXT_ALIGN_CENTER,
		TEXT_ALIGN_BOTTOM
	)

	self.btnClose:PaintManual()

	DisableClipping(false)
end

function PANEL:Close()
	self:Remove()
end

vgui.Register("expItemSelector", PANEL, "EditablePanel")
