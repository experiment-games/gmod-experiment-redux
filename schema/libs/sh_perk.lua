Schema.perk = ix.util.GetOrCreateCommonLibrary("perk")

local function checkHasPerk(perks, perkTable, client)
	local hasPerk = perks[perkTable.uniqueID]

	if (not hasPerk) then
		return false
	end

	if (perkTable.GetIsActive) then
		hasPerk = perkTable:GetIsActive(client or nil)

		if (hasPerk == nil) then
			hasPerk = true
		end
	end

	return hasPerk, perkTable
end

if (SERVER) then
	util.AddNetworkString("PerkGive")
	util.AddNetworkString("PerkTake")
	util.AddNetworkString("PerkLoadOwned")
	util.AddNetworkString("PerkRequestBuy")

	function Schema.perk.Give(client, perk)
		local perkTable = Schema.perk.Get(perk)
		local perks = client:GetCharacter():GetData("perks", {})

		if (not perkTable) then
			return false, "That is not a valid perk!"
		end

		perks[perkTable.uniqueID] = true
		client:GetCharacter():SetData("perks", perks)

		net.Start("PerkGive")
		net.WriteUInt(perkTable.index, 32)
		net.Send(client)

		if (perkTable.OnGiven) then
			perkTable:OnGiven(client)
		end
	end

	function Schema.perk.Take(client, perk)
		local perkTable = Schema.perk.Get(perk)
		local perks = client:GetCharacter():GetData("perks", {})

		if (not perkTable) then
			return false, "That is not a valid perk!"
		end

		perks[perkTable.uniqueID] = nil
		client:GetCharacter():SetData("perks", perks)

		net.Start("PerkTake")
		net.WriteUInt(perkTable.index, 32)
		net.Send(client)

		if (perkTable.OnTaken) then
			perkTable:OnTaken(client)
		end

		ix.log.Add(client, "perkTaken", perkTable.name)
	end

	function Schema.perk.LoadOwned(client, character)
		local perks = character:GetData("perks", {})

		net.Start("PerkLoadOwned")
		net.WriteTable(perks)
		net.Send(client)
	end

	--- Returns whether a player has a perk or not.
	--- @param perk string|number
	--- @param client Player
	--- @param character? table
	--- @return boolean
	function Schema.perk.GetOwned(perk, client, character)
		local perkTable = Schema.perk.Get(perk)

		character = character or client:GetCharacter()

		if (not perkTable) then
			ix.log.Add(client, "schemaDebug", "Schema.perk.GetOwned", "Attempt to check for invalid perk: " ..
				tostring(perk))
			return false
		end

		if (client:IsBot()) then
			return false
		end

		local perks = character:GetData("perks", {})

		return checkHasPerk(perks, perkTable, client)
	end

	net.Receive("PerkRequestBuy", function(len, client)
		local perkIndex = net.ReadUInt(32)
		local character = client:GetCharacter()
		local perkTable = Schema.perk.Get(perkIndex)

		if (not perkTable) then
			ix.log.Add(client, "schemaDebug", "PerkRequestBuy", "Attempt to check for invalid perk: " ..
				tostring(perkIndex))
		end

		if (not character:HasMoney(perkTable.price)) then
			client:Notify(
				"You need another "
				.. ix.currency.Get(perkTable.price - character:GetMoney(), nil, true)
				.. "!"
			)

			return
		end

		if (Schema.perk.GetOwned(perkTable.uniqueID, client)) then
			client:Notify("You already have the '" .. perkTable.name .. "' perk.")
			return
		end

		Schema.perk.Give(client, perkTable.uniqueID)

		character:TakeMoney(perkTable.price, perkTable.name)
		client:Notify("You have gotten the '" .. perkTable.name .. "' perk.")

		hook.Run("PlayerPerkBought", client, perkTable)

		ix.log.Add(client, "perkBought", perkTable.name)
	end)
else
	Schema.perk.localOwned = Schema.perk.localOwned or {}

	function Schema.perk.GetPanel()
		return ix.gui.perksPanel
	end

	function Schema.perk.UpdatePanel()
		local panel = Schema.perk.GetPanel()

		if (IsValid(panel)) then
			panel:Update()
		end
	end

	function Schema.perk.GetOwned(perk)
		local perkTable = Schema.perk.Get(perk)

		if (not perkTable) then
			return false
		end

		return checkHasPerk(Schema.perk.localOwned, perkTable)
	end

	function Schema.perk.RequestBuy(perk)
		net.Start("PerkRequestBuy")
		net.WriteUInt(perk.index, 32)
		net.SendToServer()
	end

	net.Receive("PerkGive", function()
		local perkIndex = net.ReadUInt(32)
		local perkTable = Schema.perk.Get(perkIndex)

		if (not perkTable) then
			error("Perk with index " .. perkIndex .. " does not exist.")
			return
		end

		Schema.perk.localOwned[perkTable.uniqueID] = true

		Schema.perk.UpdatePanel()

		hook.Run("PlayerPerkBought", LocalPlayer(), perkTable)
	end)

	net.Receive("PerkTake", function()
		local perkIndex = net.ReadUInt(32)
		local perkTable = Schema.perk.Get(perkIndex)

		if (not perkTable) then
			error("Perk with index " .. perkIndex .. " does not exist.")
			return
		end

		Schema.perk.localOwned[perkTable.uniqueID] = nil

		Schema.perk.UpdatePanel()
	end)

	net.Receive("PerkLoadOwned", function()
		local perks = net.ReadTable()
		Schema.perk.localOwned = {}

		for uniqueID, _ in pairs(perks) do
			Schema.perk.localOwned[uniqueID] = true
		end

		Schema.perk.UpdatePanel()
	end)
end
