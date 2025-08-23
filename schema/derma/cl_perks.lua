local rowPaintFunctions = {
	function(width, height)
	end,

	function(width, height)
		surface.SetDrawColor(30, 30, 30, 100)
		surface.DrawRect(0, 0, width, height)
	end
}

-- exp_Perk
local PANEL = {}

AccessorFunc(PANEL, "paintFunction", "BackgroundPaintFunction")

function PANEL:Init()
	self:SetTall(64)

	self:SetCursor("hand")

	self.icon = self:Add("expDynamicIcon")
	self.icon:Dock(LEFT)

	self.name = self:Add("DLabel")
	self.name:DockMargin(4, 4, 0, 0)
	self.name:Dock(TOP)
	self.name:SetFont("ixGenericFont")

	self.costLabel = vgui.Create("DLabel", self)
	self.costLabel:DockMargin(0, 0, 4, 4)
	self.costLabel:Dock(RIGHT)
	self.costLabel:SetFont("ixSmallFont")

	self.description = self:Add("DLabel")
	self.description:DockMargin(4, 4, 0, 0)
	self.description:Dock(TOP)
	self.description:SetFont("ixSmallFont")

	self.paintFunction = rowPaintFunctions[1]
end

function PANEL:SetBackgroundPaintFunction(func)
	self.paintFunction = func
end

function PANEL:SetPerk(perk)
	self.perk = perk

	self:Update()
end

function PANEL:GetText()
	if (self.perk) then
		return self.perk.name .. " " .. (self.perk.description or "")
	end

	return ""
end

function PANEL:Update()
	if (not self.perk) then
		return
	end

	self.name:SetText(self.perk.name)
	self.name:SizeToContents()
	self.description:SetText(self.perk.description)
	self.description:SizeToContents()

	local opacity = 255

	if (Schema.perk.GetOwned(self.perk.uniqueID)) then
		self.icon:SetBadge({
			spritesheet = Material("experiment-redux/flatmsicons32.png"),
			x = 29,
			y = 5,
			size = 32,
		}, derma.GetColor("Success", self))
		self.costLabel:SetText("")
	else
		opacity = 20

		self.costLabel:SetText(ix.currency.Get(self.perk.price))

		if (not LocalPlayer():GetCharacter():HasMoney(self.perk.price)) then
			self.costLabel:SetTextColor(derma.GetColor("Error", self))
		else
			self.costLabel:SetTextColor(color_white)
		end
	end

	self.icon:SetBack(
		self.perk.backgroundImage or "experiment-redux/symbol_background",
		self.perk.backgroundColor or Color(240, 211, 66, 255),
		opacity
	)
	self.icon:SetSymbol(self.perk.foregroundImage, opacity)

	local whiteOpacity = Color(color_white.r, color_white.g, color_white.b, opacity)

	self.name:SetTextColor(whiteOpacity)
	self.description:SetTextColor(whiteOpacity)
	--self.costLabel:SetTextColor(whiteOpacity)

	self.costLabel:SizeToContents()
end

function PANEL:OnCursorEntered()
	self.isHovering = true
end

function PANEL:OnCursorExited()
	self.isHovering = false
end

function PANEL:OnMouseReleased(keyCode)
	if (keyCode ~= MOUSE_FIRST) then
		return
	end

	local perk = self.perk

	if (Schema.perk.GetOwned(perk.uniqueID)) then
		return
	end

	Derma_Query(
		string.format(
			"Are you sure you want to buy the perk '%s' for %s?",
			perk.name,
			ix.currency.Get(perk.price)
		),
		"Confirm Purchase Perk",
		L("yes"),
		function()
			Schema.perk.RequestBuy(perk)
		end,
		L("no")
	)
end

function PANEL:Paint(width, height)
	self.paintFunction(width, height)

	if (Schema.perk.GetOwned(self.perk.uniqueID)) then
		return
	end

	if (self.isHovering) then
		surface.SetDrawColor(255, 255, 255, 50)
		surface.DrawRect(0, 0, width, height)
	end
end

vgui.Register("exp_Perk", PANEL, "EditablePanel")

-- exp_Perks
PANEL = {}

function PANEL:Init()
	self:Dock(FILL)
	self:SetSearchEnabled(true)

	self.perks = {}
	self.nextThink = 0

	-- Create scroll panel
	self.canvas = self:Add("DScrollPanel")
	self.canvas:Dock(FILL)

	local sortedPerks = table.ClearKeys(Schema.perk.GetAll())
	table.SortByMember(sortedPerks, "name", true)

	for _, perk in ipairs(sortedPerks) do
		local panel = self.canvas:Add("exp_Perk")
		panel:SetPerk(perk)
		panel:Dock(TOP)
		panel:DockMargin(4, 4, 4, 4)

		self.perks[#self.perks + 1] = panel
	end
end

function PANEL:SetSearchEnabled(bValue)
	if (not bValue) then
		if (IsValid(self.searchEntry)) then
			self.searchEntry:Remove()
		end
		return
	end

	-- search entry
	self.searchEntry = self:Add("ixIconTextEntry")
	self.searchEntry:Dock(TOP)
	self.searchEntry:SetEnterAllowed(false)

	self.searchEntry.OnChange = function(entry)
		self:FilterPerks(entry:GetValue())
	end
end

function PANEL:FilterPerks(query)
	if (not query) then return end

	query = string.PatternSafe(query:lower())
	local bEmpty = query == ""

	for _, perkPanel in ipairs(self.perks) do
		if (not IsValid(perkPanel) or not perkPanel.GetText) then continue end

		local bFound = bEmpty or perkPanel:GetText():lower():find(query)
		perkPanel:SetVisible(bFound)
	end

	self:InvalidateChildren(true)
end

function PANEL:Update()
	for i = 1, #self.perks do
		local id = i % 2 == 0 and 1 or 2
		local perkPanel = self.perks[i]
		perkPanel:SetBackgroundPaintFunction(rowPaintFunctions[id])
		perkPanel:Update()
	end
end

function PANEL:Think()
	if (CurTime() >= self.nextThink) then
		self:Update()

		self.nextThink = CurTime() + 0.5
	end

	ix.gui.perksPanel = self
end

vgui.Register("exp_Perks", PANEL, "EditablePanel")

hook.Add("CreateMenuButtons", "expAddPerksMenuButton", function(tabs)
	tabs["perks"] = function(container)
		container:Add("exp_Perks")
	end
end)
