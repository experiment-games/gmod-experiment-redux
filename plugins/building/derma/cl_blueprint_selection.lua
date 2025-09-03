local PLUGIN = PLUGIN

do
	local PANEL = {}

	function PANEL:Init()
		local size = 120
		self:SetSize(size, size * 1.4)
		self.isSelected = false
	end

	function PANEL:SetBlueprint(itemTable, mainPanel)
		self.itemTable = itemTable
		self.blueprintName = L(itemTable.name):lower()
		self.mainPanel = mainPanel

		-- Blueprint name (top)
		self.name = self:Add("DLabel")
		self.name:Dock(TOP)
		self.name:SetText(itemTable.GetName and itemTable:GetName() or L(itemTable.name))
		self.name:SetContentAlignment(5)
		self.name:SetFont("ixSmallFont")
		self.name:SetTextColor(color_white)
		self.name:SetTall(32)
		self.name:SetExpensiveShadow(1, Color(0, 0, 0, 200))
		self.name.Paint = function(this, w, h)
			surface.SetDrawColor(0, 0, 0, 75)
			surface.DrawRect(0, 0, w, h)
		end

		-- Blueprint icon (center)
		self.icon = self:Add("SpawnIcon")
		self.icon:SetZPos(1)
		self.icon:SetSize(self:GetWide(), self:GetWide())
		self.icon:Dock(FILL)
		self.icon:DockMargin(5, 5, 5, 10)
		self.icon:InvalidateLayout(true)
		self.icon:SetModel(itemTable:GetModel(), itemTable:GetSkin())
		self.icon:SetHelixTooltip(function(tooltip)
			ix.hud.PopulateItemTooltip(tooltip, itemTable)

			-- Also list the materials
			local materialsDescription = tooltip:AddRow("materials")
			materialsDescription:SetText("Materials:")
			materialsDescription:SizeToContents()
			materialsDescription:SetBackgroundColor(Color(50, 50, 50, 200))

			for materialId, material in pairs(itemTable:GetConstructionMaterials()) do
				local materialItemTable = ix.item.list[materialId]
				local materialRow = tooltip:AddRow(materialId)
				materialRow:SetText(
					string.format(
						"• %s x%d",
						materialItemTable and L(materialItemTable.name) or materialId,
						material
					)
				)
				materialRow:SizeToContents()
				materialRow:SetBackgroundColor(Color(50, 50, 50, 200))
			end
		end)
		self.icon.itemTable = itemTable

		-- Click handling
		self.icon.DoClick = function(this)
			local mainPanel = self.mainPanel
			mainPanel:SelectBlueprint(self)
		end

		-- Custom paint over for selection highlight
		self.icon.PaintOver = function(this, w, h)
			if (self.isSelected) then
				-- Draw selection border
				surface.SetDrawColor(60, 120, 180, 255)
				surface.DrawOutlinedRect(0, 0, w, h, 3)

				-- Draw selection overlay
				surface.SetDrawColor(60, 120, 180, 50)
				surface.DrawRect(0, 0, w, h)
			end

			-- Call original PaintOver if it exists
			if (itemTable and itemTable.PaintOver) then
				itemTable.PaintOver(this, itemTable, w, h)
			end
		end

		if ((itemTable.iconCam and ! ICON_RENDER_QUEUE[itemTable.uniqueID]) or itemTable.forceRender) then
			local iconCam = itemTable.iconCam
			iconCam = {
				cam_pos = iconCam.pos,
				cam_fov = iconCam.fov,
				cam_ang = iconCam.ang,
			}
			ICON_RENDER_QUEUE[itemTable.uniqueID] = true

			self.icon:RebuildSpawnIconEx(iconCam)
		end
	end

	vgui.Register("expBlueprintItem", PANEL, "DPanel")
end

do
	-- Main Blueprint Selector Panel
	local PANEL = {}

	function PANEL:Init()
		self:SetTitle("Select Blueprint")
		self:SetSize(800, 600)
		self:Center()
		self:MakePopup()
		self:SetDeleteOnClose(true)

		self.selectedBlueprint = nil
		self.weapon = nil

		self:CreateMainContainer()
	end

	function PANEL:SetWeapon(weapon)
		self.weapon = weapon
		self:RefreshBlueprintsList()
	end

	function PANEL:CreateMainContainer()
		-- Main container
		self.mainContainer = vgui.Create("EditablePanel", self)
		self.mainContainer:Dock(FILL)
		self.mainContainer:DockMargin(8, 8, 8, 8)

		self:CreateHeaderPanel()
		self:CreateSearchPanel()
		self:CreateContentPanel()
		self:CreateBottomPanel()
	end

	function PANEL:CreateHeaderPanel()
		-- Header panel
		self.headerPanel = vgui.Create("EditablePanel", self.mainContainer)
		self.headerPanel:SetTall(40)
		self.headerPanel:Dock(TOP)
		self.headerPanel:DockMargin(0, 0, 0, 8)

		-- Header label
		self.headerLabel = vgui.Create("DLabel", self.headerPanel)
		self.headerLabel:SetText("Select a Blueprint to Build:")
		self.headerLabel:SetTextColor(Color(255, 255, 255, 255))
		self.headerLabel:SetFont("ixMediumFont")
		self.headerLabel:SizeToContents()
	end

	function PANEL:CreateSearchPanel()
		self.search = vgui.Create("DTextEntry", self.mainContainer)
		self.search:Dock(TOP)
		self.search:SetTall(36)
		self.search:SetFont("ixMediumFont")
		self.search:DockMargin(10, 0, 10, 5)
		self.search:SetPlaceholderText("Search blueprints...")

		self.search.OnTextChanged = function(this)
			local text = self.search:GetText():lower()
			self:RefreshBlueprintsList(text:find("%S") and text or nil)
		end
	end

	function PANEL:CreateContentPanel()
		self.scrollPanel = vgui.Create("DScrollPanel", self.mainContainer)
		self.scrollPanel:Dock(FILL)
		self.scrollPanel:DockMargin(0, 0, 0, 8)

		-- Icon layout for blueprints
		self.itemList = self.scrollPanel:Add("DIconLayout")
		self.itemList:Dock(TOP)
		self.itemList:DockMargin(10, 1, 5, 5)
		self.itemList:SetSpaceX(10)
		self.itemList:SetSpaceY(10)
		self.itemList:SetMinimumSize(128, 400)
	end

	function PANEL:CreateBottomPanel()
		-- Bottom button panel
		self.bottomPanel = vgui.Create("EditablePanel", self.mainContainer)
		self.bottomPanel:SetTall(50)
		self.bottomPanel:Dock(BOTTOM)

		self:CreateSelectButton()
		self:CreateCancelButton()
	end

	function PANEL:CreateSelectButton()
		-- Select button
		self.selectButton = vgui.Create("expButton", self.bottomPanel)
		self.selectButton:SetText("Select Blueprint")
		self.selectButton:SizeToContents()
		self.selectButton:Dock(RIGHT)
		self.selectButton:DockMargin(0, 10, 15, 10)
		self.selectButton:SetEnabled(false)

		self.selectButton.DoClick = function()
			self:OnSelectButtonClicked()
		end
	end

	function PANEL:CreateCancelButton()
		-- Cancel button
		self.cancelButton = vgui.Create("expButton", self.bottomPanel)
		self.cancelButton:SetText("Cancel")
		self.cancelButton:SizeToContents()
		self.cancelButton:Dock(RIGHT)
		self.cancelButton:DockMargin(0, 10, 8, 10)

		self.cancelButton.DoClick = function()
			self:Close()
		end
	end

	function PANEL:RefreshBlueprintsList(searchFilter)
		-- Clear existing items
		self.itemList:Clear()

		-- Get learned blueprints from character data
		local character = LocalPlayer():GetCharacter()
		if (not character) then
			self:ShowNoBlueprints()
			return
		end

		local blueprintsLearned = character:GetData("blueprintsLearned", {})
		local learnedItems = {}

		-- Find all learned blueprint items
		for uniqueID, isLearned in pairs(blueprintsLearned) do
			if (isLearned and ix.item.list[uniqueID]) then
				local itemTable = ix.item.list[uniqueID]

				-- Apply search filter if provided
				if (searchFilter) then
					local itemName = L(itemTable.name):lower()
					if (! itemName:find(searchFilter, 1, true)) then
						continue
					end
				end

				table.insert(learnedItems, itemTable)
			end
		end

		-- Sort items by name
		table.sort(learnedItems, function(a, b)
			return a.name < b.name
		end)

		if (#learnedItems == 0) then
			self:ShowNoBlueprints(searchFilter and "No blueprints found matching search." or nil)
			return
		end

		-- Create blueprint items using the icon layout
		for i, itemTable in ipairs(learnedItems) do
			local blueprintItem = self.itemList:Add("expBlueprintItem")
			blueprintItem:SetBlueprint(itemTable, self)
		end

		-- Invalidate layout to properly arrange items
		self.itemList:InvalidateLayout(true)
		timer.Simple(0.01, function()
			if (IsValid(self.scrollPanel)) then
				self.scrollPanel:InvalidateLayout()
			end
		end)
	end

	function PANEL:ShowNoBlueprints(customMessage)
		local noItemsLabel = vgui.Create("DLabel", self.itemList)
		noItemsLabel:SetText(customMessage or
			"No blueprints learned. Learn blueprints from blueprint items for sale at The Business.")
		noItemsLabel:SetTextColor(Color(150, 150, 150, 255))
		noItemsLabel:SetFont("ixMediumFont")
		noItemsLabel:SetContentAlignment(5)
		noItemsLabel:SetWrap(true)
		noItemsLabel:SetAutoStretchVertical(true)
		noItemsLabel:Dock(FILL)
		noItemsLabel:SizeToContents()

		self.selectButton:SetEnabled(false)
	end

	function PANEL:SelectBlueprint(blueprintItem)
		-- Deselect all items
		for _, child in pairs(self.itemList:GetChildren()) do
			if (child.isSelected) then
				child.isSelected = false
			end
		end

		-- Select new item
		blueprintItem.isSelected = true
		self.selectedBlueprint = blueprintItem.itemTable
		self.selectButton:SetEnabled(true)

		-- Play selection sound
		surface.PlaySound("buttons/button14.wav")
	end

	function PANEL:OnSelectButtonClicked()
		if (not self.selectedBlueprint or not self.weapon) then
			return
		end

		-- Set the weapon's item table to the selected blueprint
		net.Start("expSetStructureBuilderBlueprint")
		net.WriteString(self.selectedBlueprint.uniqueID)
		net.SendToServer()

		-- On client, we need to update the weapon's ixItem for the preview system
		self.weapon.ixItem = self.selectedBlueprint
		self.weapon.expStructureBuilt = false -- Force rebuild of client-side models

		-- Close the menu
		self:Close()

		-- Notify player
		LocalPlayer():Notify("Selected blueprint: " .. self.selectedBlueprint.name)

		-- Play confirmation sound
		surface.PlaySound("buttons/button3.wav")
	end

	vgui.Register("expBlueprintSelector", PANEL, "expFrame")
end
