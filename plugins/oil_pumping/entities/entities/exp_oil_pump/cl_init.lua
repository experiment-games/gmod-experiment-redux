local PLUGIN = PLUGIN

include("shared.lua")

ENT.PopulateEntityInfo = true

function ENT:OnPopulateEntityInfo(tooltip)
	local ownerName, isOwner = self:GetOwnerName()
	local name = tooltip:AddRow("name")
	name:SetImportant()

	if (isOwner) then
		name:SetText(L("oilPumpOwnerSelf"))
	else
		if (ownerName == false) then
			name:SetText(L("oilPumpOwnerTheBusiness"))
			name:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		else
			name:SetText(L("oilPumpOwnerName", ownerName))
		end
	end

	name:SizeToContents()

	-- Show pump status
	local statusRow = tooltip:AddRow("status")
	local statusText = ""

	if (self:GetIsBroken()) then
		statusText = L("oilPumpStatusBroken")
		statusRow:SetTextColor(Color(255, 100, 100))
	elseif (self:GetScrapAmount() <= 0) then
		statusText = L("oilPumpStatusNoScrap")
		statusRow:SetTextColor(Color(255, 200, 100))
	elseif (self:GetIsRunning()) then
		statusText = L("oilPumpStatusRunning")
		statusRow:SetTextColor(Color(100, 255, 100))
	else
		statusText = L("oilPumpStatusStopped")
		statusRow:SetTextColor(Color(200, 200, 200))
	end

	statusRow:SetText(L("oilPumpStatus", statusText))
	statusRow:SizeToContents()

	-- Show oil levels
	local oilRow = tooltip:AddRow("oil")
	oilRow:SetText(L("oilPumpOil", self:GetOilAmount(), PLUGIN.pumpMaxCapacity))
	oilRow:SizeToContents()

	-- Show scrap levels
	local scrapRow = tooltip:AddRow("scrap")
	scrapRow:SetText(L("oilPumpScrap", self:GetScrapAmount()))
	scrapRow:SizeToContents()

	-- Health bar
	local healthBar = tooltip:Add("expProgressBar")
	healthBar:SetValue(self:Health())
	healthBar:SetMaxValue(self:GetMaxHealth())
	healthBar:SetPrefix("Health: ")

	-- Health colors
	healthBar:SetProgressColors({
		{ threshold = 0.7, color = derma.GetColor("Success", healthBar) },
		{ threshold = 0.4, color = derma.GetColor("Warning", healthBar) },
		{ threshold = 0,   color = derma.GetColor("Error", healthBar) },
	})

	healthBar:Dock(BOTTOM)
	healthBar:SizeToContents()
end

function ENT:GetEntityMenu()
	local options = {}

	-- If broken, allow repairs
	if (self:GetIsBroken()) then
		options[L("oilPumpRepair")] = function() end
		return options
	end

	-- Add scrap option
	local character = LocalPlayer():GetCharacter()
	local inventory = character:GetInventory()

	if (inventory:HasItem("scrap")) then
		options[L("oilPumpAddScrap")] = function() end
	end

	-- Oil extraction options
	local currentOil = self:GetOilAmount()

	-- Oil drum extraction (500L)
	if (currentOil >= 500 and inventory:HasItem("oil_drum_empty")) then
		options[L("oilPumpExtractOilDrum")] = function() end
	end

	-- Gas can extraction (50L)
	if (currentOil >= 50 and inventory:HasItem("gas_can_empty")) then
		options[L("oilPumpExtractGasCan")] = function() end
	end

	return options
end
