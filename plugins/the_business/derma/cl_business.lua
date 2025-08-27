local PLUGIN = PLUGIN
local PANEL = {}

local BUTTON_HEIGHT = 36

--- Returns a list of items, optionally filtered by category and search query.
function PANEL:GetItems(category, search)
	category = category ~= "searchResults" and category or nil
	search = search and search:lower() or nil

	local items = {}

	for uniqueID, itemTable in SortedPairsByMemberValue(ix.item.list, "name") do
		if (hook.Run("CanPlayerUseBusiness", LocalPlayer(), uniqueID) == false) then
			continue
		end

		local searchMismatch = search and search ~= "" and not L(itemTable.name):lower():find(search, 1, true)

		if (searchMismatch and not itemTable.GetSearchMatches) then
			continue
		end

		if (searchMismatch and itemTable.GetSearchMatches and not itemTable:GetSearchMatches(search)) then
			continue
		end

		if (not category or itemTable.category == category) then
			items[#items + 1] = itemTable
		end
	end

	return items
end

function PANEL:Init()
	ix.gui.business = self
	Schema.businessPanel = self

	self:DockPadding(16, 48, 16, 48)

	self:SetupWalletInfo()

	self.categories = self:Add("DIconLayout")
	self.categories:SetSpaceY(5)
	self.categories:SetSpaceX(5)
	self.categories:SetBorder(5)
	self.categories:DockPadding(0, 0, 0, 5)
	self.categories:DockMargin(0, 0, 0, 16)
	self.categories:Dock(TOP)
	self.categories.Paint = function(this, w, h)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, 0, w, h)
	end
	self.categoryPanels = {}

	self.scroll = self:Add("DScrollPanel")
	self.scroll:Dock(FILL)

	self.itemList = self.scroll:Add("DIconLayout")
	self.itemList:Dock(TOP)
	self.itemList:SetSpaceX(16)
	self.itemList:SetSpaceY(16)
	self.itemList:SetMinimumSize(128, 400)

	local dark = Color(0, 0, 0, 50)

	for k, v in pairs(ix.item.list) do
		if (hook.Run("CanPlayerUseBusiness", LocalPlayer(), k) == false) then
			continue
		end

		if (! self.categoryPanels[L(v.category)]) then
			self.categoryPanels[L(v.category)] = v.category
		end
	end

	local label = self.categories:Add("DLabel")
	label:SetText(L "categories" .. ":")
	label:SetFont("expSmallerFont")
	label:DockMargin(5, 5, 5, 5)
	label:SetTextColor(Color(255, 255, 255, 100))
	label:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	label:SizeToContents()
	label:SetContentAlignment(5)
	label:SetTall(25)

	local function addCategoryButton(category, realName)
		local button = self.categories:Add("expButton")
		button:SetText(category)
		button:SetScale(BUTTON_SCALE_SMALL)
		button:DockMargin(5, 5, 5, 5)
		button.Paint = function(this, width, height)
			if (self.selected ~= this) then
				return
			end

			this:PaintBackground(width, height)
		end
		button.DoClick = function(this)
			if (self.selected ~= this) then
				self.selected = this
				PLUGIN.lastBusinessCategory = realName

				self:LoadItems(realName, self.search:GetText())
				timer.Simple(0.01, function()
					self.scroll:InvalidateLayout()
				end)
			end
		end
		button.category = realName

		if (not PLUGIN.lastBusinessCategory or PLUGIN.lastBusinessCategory == realName) then
			self.selected = button
			PLUGIN.lastBusinessCategory = realName
		end

		self.categoryPanels[realName] = button

		return button
	end

	for category, realName in SortedPairs(self.categoryPanels) do
		addCategoryButton(category, realName)
	end

	local searchResultButton = addCategoryButton(L "searchResults", "searchResults")

	if (not PLUGIN.lastBusinessSearch) then
		searchResultButton:SetVisible(false)
	end

	self.categories:Layout()

	self:SetupSearch()

	if (self.selected) then
		self:LoadItems(self.selected.category, self.search:GetText())
	end
end

function PANEL:SetupWalletInfo()
	local wallet = self:Add("DPanel")
	wallet:SetTall(48)
	wallet:DockMargin(0, 16, 0, 0)
	wallet:Dock(BOTTOM)
	wallet:SetPaintBackground(false)

	local walletLabel = wallet:Add("DLabel")
	walletLabel:SetText(L "wallet" .. ":")
	walletLabel:SetFont("expSmallerFont")
	walletLabel:DockMargin(5, 5, 5, 5)
	walletLabel:SetTextColor(Color(255, 255, 255, 100))
	walletLabel:SizeToContents()
	walletLabel:Dock(LEFT)

	local walletAmount = wallet:Add("DLabel")
	walletAmount:SetFont("ixBigFont")
	walletAmount:DockMargin(5, 5, 5, 5)
	walletAmount:SetTextColor(ix.config.Get("color"))
	walletAmount:Dock(FILL)

	self.walletAmount = walletAmount

	self:UpdateWallet()
end

function PANEL:UpdateWallet(money)
	money = money or LocalPlayer():GetCharacter():GetMoney()

	self.walletAmount:SetText(ix.currency.Get(money))
	self.walletAmount:SizeToContents()
end

function PANEL:SetupSearch()
	-- Create a panel to hold the search bar and category list
	self.searchPanel = self:Add("DPanel")
	self.searchPanel:Dock(TOP)
	self.searchPanel:SetTall(BUTTON_HEIGHT)
	self.searchPanel:DockMargin(0, 0, 0, 16)
	self.searchPanel:SetPaintBackground(false)

	-- A button to open the filter menu
	self.filterButton = self.searchPanel:Add("expButton")
	self.filterButton:Dock(LEFT)
	self.filterButton:SetText(L "filter")
	self.filterButton.DoClick = function(button)
		local allItems = self:GetItems(self.selected.category, self.search:GetText())
		local filters = {}

		for _, itemTable in ipairs(allItems) do
			if (not itemTable.GetFilters) then
				continue
			end

			for filter, filterType in pairs(itemTable:GetFilters()) do
				filters[filter] = filters[filter] or {
					type = filterType,
					items = {},
				}
				filters[filter].items[#filters[filter].items + 1] = itemTable
			end
		end

		if (IsValid(self.filterMenu)) then
			self.filterMenu:SetVisible(true)
			self.filterMenu:SetPos(button:LocalToScreen(0, button:GetTall()))
			self.filterMenu:MakePopup()
			return
		end

		self.filterMenu = vgui.Create("expBusinessFilters", self)
		self.filterMenu:SetFilters(filters, allItems)
		self.filterMenu:SetPos(button:LocalToScreen(0, button:GetTall()))
	end

	-- Reparent the search bar to the search panel
	self.search = self.searchPanel:Add("DTextEntry")
	self.search:SetText(PLUGIN.lastBusinessSearch or "")
	self.search:Dock(FILL)
	self.search:DockMargin(5, 0, 0, 0)
	self.search:SetFont("ixMediumFont")
	self.search.OnTextChanged = function(this)
		local query = self.search:GetText()

		self.selected = self.categoryPanels["searchResults"]
		self.selected:SetVisible(query ~= "")
		self.categories:Layout()

		if (query == "") then
			self.selected = self.categories:GetChildren()[2] -- skip the label
			timer.Simple(0.01, function()
				self.scroll:InvalidateLayout()
			end)
		end

		PLUGIN.lastBusinessCategory = self.selected.category
		PLUGIN.lastBusinessSearch = query
		self:LoadItems(self.selected.category, query:find("%S") and query or nil)

		self.scroll:InvalidateLayout()
	end
	self.search.PaintOver = function(this, cw, ch)
		if (self.search:GetValue() == "" and ! self.search:HasFocus()) then
			ix.util.DrawText("V", 10, ch / 2 - 1, color_black, 3, 1, "ixIconsSmall")
		end
	end
end

function PANEL:DisplayItems(items)
	self.itemList:Clear()
	self.itemList:InvalidateLayout(true)

	table.SortByMember(items, "name", true)

	for _, itemTable in ipairs(items) do
		self.itemList:Add("expBusinessItem"):SetItem(itemTable)
	end

	if (#items > 0) then
		return
	end

	local label = self.itemList:Add("DLabel")
	label:Dock(TOP)
	label:SetText(L("noSearchResults"))
	label:SetFont("ixMediumFont")
	label:SetTextColor(color_white)
	label:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	label:SizeToContents()
	label:SetContentAlignment(5)
	label:DockMargin(0, 0, 0, 16)

	local clearButton = self.itemList:Add("expButton")
	clearButton:Dock(TOP)
	clearButton:SetText(L("searchClear"))
	clearButton.DoClick = function()
		self.search:SetText("")
		self.categoryPanels["searchResults"]:SetVisible(false)
		self.categories:Layout()
		self.selected = self.categories:GetChildren()[2] -- skip the label
		PLUGIN.lastBusinessCategory = self.selected.category
		PLUGIN.lastBusinessSearch = nil
		self:LoadItems(self.selected.category)

		timer.Simple(0.01, function()
			self.scroll:InvalidateLayout()
		end)
	end
end

function PANEL:LoadItems(category, search)
	self.itemList:Clear()
	self.itemList:InvalidateLayout(true)

	if (IsValid(self.filterMenu)) then
		self.filterMenu:Close()
		self.filterMenu:Remove()
	end

	local items = self:GetItems(category, search)

	self:DisplayItems(items)
end

function PANEL:BuyItem(uniqueID)
	Schema.businessPurchasePanel:BuyItem(uniqueID)

	return true
end

function PANEL:Refresh()
	self:LoadItems(self.selected.category, self.search:GetText():lower())
end

hook.Add("VGUIMousePressed", "expCloseFiltersOnOutsideClick", function(panel, mouseCode)
	if (not IsValid(ix.gui.business) or not IsValid(ix.gui.business.filterMenu) or mouseCode ~= MOUSE_LEFT) then
		return
	end

	local isFilterMenuOrChild = panel:HasParent(ix.gui.business.filterMenu)

	if (not isFilterMenuOrChild) then
		ix.gui.business.filterMenu:Close()
	end
end)

vgui.Register("expBusiness", PANEL, "EditablePanel")

PANEL = {}

DEFINE_BASECLASS("ixBusinessItem")

function PANEL:Init()
	local size = math.max(ScrW() * 0.1, 128)
	self:SetSize(size, size * 1.4)
end

function PANEL:SetItem(itemTable)
	self.shipmentSize = self:Add("DLabel")
	self.shipmentSize:Dock(BOTTOM)
	self.shipmentSize:SetContentAlignment(5)
	self.shipmentSize:SetTextColor(Color(255, 255, 255, 60))
	self.shipmentSize:SetFont("ixSmallFont")
	self.shipmentSize:SetExpensiveShadow(1, Color(0, 0, 0, 200))

	BaseClass.SetItem(self, itemTable)

	if (itemTable.shipmentSize) then
		self.shipmentSize:SetText("(Batch of " .. itemTable.shipmentSize .. ")")
		self.price:SetText(
			itemTable.price
			and ix.currency.Get(itemTable.price * itemTable.shipmentSize)
			or L("free"):utf8upper()
		)
	else
		self.shipmentSize:SetText("(Each)")
	end

	-- For some reason the icon tends to render empty the first time around, so we delay it and render again
	timer.Simple(0.1, function()
		if ((itemTable.iconCam and ! ICON_RENDER_QUEUE[itemTable.uniqueID]) or itemTable.forceRender) then
			if IsValid(self.icon) then
				local iconCam = itemTable.iconCam
				iconCam = {
					cam_pos = iconCam.pos,
					cam_fov = iconCam.fov,
					cam_ang = iconCam.ang,
				}
				self.icon:RebuildSpawnIconEx(iconCam)
			end
		end
	end)
end

vgui.Register("expBusinessItem", PANEL, "ixBusinessItem")
