local PLUGIN = PLUGIN

function PLUGIN:NetworkEntityCreated(entity)
	if (entity:GetClass() ~= "exp_monitor") then
		return
	end

	-- Delay this call, because SetupDataTables is called after NetworkEntityCreated and the hook inside this function may need those
	timer.Simple(0, function()
		if (IsValid(entity) and entity:GetClass() == "exp_monitor") then
			self:HandleMonitorEntityEnteringPVS(entity)
		end
	end)
end

-- Draw location to locker with anti-virus (if this player has a locker rot event)
function PLUGIN:HUDPaint()
	self:DrawLockerRotAntiVirusIfNeeded()
end

function PLUGIN:PaintOverItemIcon(itemIcon, itemTable, width, height)
	if (not itemTable:GetData("lockerRot")) then
		return
	end

	self:PaintLockerRotOverItemIcon(itemIcon, itemTable, width, height)
end

function PLUGIN:PostDrawTranslucentRenderables(isDrawingDepth, isDrawingSkybox)
	if (isDrawingSkybox or isDrawingDepth) then return end

	local monitorEntities = ents.FindByClass("exp_monitor")

	for _, monitor in pairs(monitorEntities) do
		-- Use the new ShouldDrawMonitor function that handles both client-specific and global content
		if (not self:ShouldDrawMonitor(monitor) or monitor:IsDormant()) then
			continue
		end

		self:SetupMonitorDrawing(monitor)
	end
end

function PLUGIN:OnStoragePanelSetup(panel, storageInventoryPanel, localInventoryPanel)
	local storageInventory = ix.item.inventories[storageInventoryPanel.invID]
	local anyHasLockerRot = false

	for _, item in pairs(storageInventory:GetItems()) do
		if (item:GetData("lockerRot")) then
			anyHasLockerRot = true
			break
		end
	end

	if (not anyHasLockerRot) then
		return
	end

	local lockerRotInfo = panel:Add("DPanel")
	lockerRotInfo:SetWide(storageInventoryPanel:GetWide() + localInventoryPanel:GetWide())
	lockerRotInfo:SetPaintBackground(false)
	lockerRotInfo.Paint = function(this, w, h)
		local color = ix.config.Get("color")

		surface.SetDrawColor(ColorAlpha(color, 50))
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(color)
		surface.DrawOutlinedRect(0, 0, w, h, 2)
	end

	local symbol = lockerRotInfo:Add("DPanel")
	symbol:Dock(LEFT)
	symbol:SetPaintBackground(false)
	symbol:SetSize(64 + 16, 80 + 16)
	symbol.Paint = function(this, w, h)
		local smallestSize = math.min(w, h)
		local padding = 8
		smallestSize = smallestSize - (padding * 2)

		surface.SetDrawColor(color_white)
		surface.SetMaterial(PLUGIN.lockerRotSymbol)
		surface.DrawTexturedRect(
			padding,
			(h * 0.5) - (smallestSize * 0.5),
			smallestSize, smallestSize
		)
	end

	local explanation = lockerRotInfo:Add("DPanel")
	explanation:DockPadding(8, 8, 8, 8)
	explanation:Dock(FILL)
	explanation:SetPaintBackground(false)

	local explanationHeading = explanation:Add("DLabel")
	explanationHeading:Dock(TOP)
	explanationHeading:SetText("Some items in this locker are at risk of being lost!")
	explanationHeading:SetFont("ixSmallTitleFont")
	explanationHeading:SetWrap(true)
	explanationHeading:SetAutoStretchVertical(true)
	explanationHeading:SetTextColor(ColorAlpha(color_white, 150))

	local explanationText = explanation:Add("DLabel")
	explanationText:Dock(FILL)
	explanationText:SetText(
		"The 'Locker Rot Virus' will destroy items in this locker infected by it. "
		.. "You can prevent this by taking the items out of the locker and bringing them to the locker with the anti-virus."
	)
	explanationText:SetFont("ixSmallFont")
	explanationText:SetTextColor(color_white)
	explanationText:SetWrap(true)
	explanationText:SetAutoStretchVertical(true)

	lockerRotInfo:SizeToChildren(false, true)
	lockerRotInfo:SetX(storageInventoryPanel:GetX())
	lockerRotInfo:SetY(storageInventoryPanel:GetY() - lockerRotInfo:GetTall() - 16)
end

function PLUGIN:PostDrawHUD()
	if (IsValid(self.lockerRotInfoPanel)) then
		local phaseInfo = GetNetVar("locker_rot_event")

		if (phaseInfo or TEST_LOCKER_ROT_PANEL) then
			self.lockerRotInfoPanel:SetPos(ScrW() - self.lockerRotInfoPanel:GetWide(), 20)
			self.lockerRotInfoPanel:PaintManual()
		end

		return
	end

	local panel = vgui.Create("expLockerRotEventPanel")
	self.lockerRotInfoPanel = panel
	panel:SetPaintedManually(true)
end

function PLUGIN:AdjustProgressionHUD(desiredWidth, x, y)
	local phaseInfo = GetNetVar("locker_rot_event")
	if ((phaseInfo or TEST_LOCKER_ROT_PANEL) and IsValid(self.lockerRotInfoPanel)) then
		return desiredWidth, x, y + self.lockerRotInfoPanel:GetTall() + 16
	end
end
