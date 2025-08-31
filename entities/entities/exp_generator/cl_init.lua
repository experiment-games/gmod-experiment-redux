include("shared.lua")

ENT.PopulateEntityInfo = true

function ENT:OnPopulateEntityInfo(tooltip)
	local ownerName, isOwner = self:GetOwnerName()
	local name = tooltip:AddRow("name")
	name:SetImportant()

	if (isOwner) then
		name:SetText(L("generatorOwnerSelf"))
	else
		name:SetText(L("generatorOwnerName", ownerName))
	end

	name:SizeToContents()

	local itemTable = self:GetItemTable()

	if (not itemTable) then
		return
	end

	local powerBar = tooltip:Add("expProgressBar")
	powerBar:SetValue(function()
		if (not IsValid(self)) then
			return 0
		end

		return self:GetPower()
	end)
	powerBar:SetMaxValue(itemTable.generator.power)
	powerBar:SetPrefix(L("generatorPower"))
	powerBar:Dock(BOTTOM)

	local upgrades = self:GetUpgrades() or 0
	local description = tooltip:AddRow("description")
	description:SetText("Upgrades: " .. upgrades .. " / " .. #itemTable.generator.upgrades)
	description:SizeToContents()

	local teleportEarnings = ix.config.Get("teleportGeneratorEarnings")

	if (not teleportEarnings) then
		local earnings = tooltip:AddRow("earnings")
		earnings:SetText("Earnings: " .. ix.currency.Get(self:GetHeldBolts() or 0))
		earnings:SizeToContents()
	end
end

function ENT:GetEntityMenu(client)
	local itemTable = self:GetItemTable()
	local options = {}

	if (not itemTable) then
		return false
	end

	local characterID = self:GetOwnerID()

	itemTable.entity = self
	itemTable.player = client

	if (characterID and characterID == client:GetCharacter():GetID()) then
		options[L("pickup")] = {
			callback = function() end,
			forceListEnd = true,
		}
	end

	local nextUpgrade, upgradeLabel = self:GetNextUpgrade()

	if (nextUpgrade) then
		options[upgradeLabel] = function() end
	end

	local teleportEarnings = ix.config.Get("teleportGeneratorEarnings")

	if (not teleportEarnings) then
		local heldBolts = self:GetHeldBolts() or 0

		if (heldBolts > 0) then
			options[L("withdraw", heldBolts)] = function() end
		end
	end

	local power = self:GetPower()

	if (power < itemTable.generator.power) then
		options[L("generatorRecharge")] = function() end
	end

	itemTable.player = nil
	itemTable.entity = nil

	return options
end
