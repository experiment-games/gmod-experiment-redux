local ITEM = ITEM

ITEM.name = "Companion Healing Base"
ITEM.model = "models/Items/HealthKit.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Medical"
ITEM.description = "A first aid kit that will heal your companion."

--- The amount of health to heal the companion by.
ITEM.companionHealAmount = 100

--- Whether or not this item can be used to revive companions from <= 0 health.
ITEM.companionCanBeRevived = true

--- The healing range if the companion is out in the world.
ITEM.healingRange = 192

--- Called to get the heal amount for the companion.
--- @param character Character The character that is using the item.
--- @param companionItemInstance ItemInstance The companion item instance that is being healed.
--- @return number The amount of health to heal the companion by. If 0, the companion will not be healed (without a message, so show one if needed).
function ITEM:GetCompanionHealAmount(character, companionItemInstance)
	return self.companionHealAmount
end

--- Called to check whether or not the item can revive the companion.
--- @param character Character The character that is using the item.
--- @param companionItemInstance ItemInstance The companion item instance that is being healed.
--- @return boolean, string? # Whether or not the item can revive the companion. If false, the second return value is the reason why.
function ITEM:CanReviveCompanion(character, companionItemInstance)
	return self.companionCanBeRevived, "This item cannot revive companions!"
end

--- Called to get the healing range for the companion.
--- @param character Character The character that is using the item.
--- @param companionItemInstance ItemInstance The companion item instance that is being healed.
--- @return number # The range the companion can be from the player to be healed.
function ITEM:GetHealingRange(character, companionItemInstance)
	return self.healingRange
end

--- Called when a player heals a companion.
--- @param character Character The character that is using the item.
--- @param companionItemInstance ItemInstance The companion item instance that is being healed.
--- @return boolean?, boolean? # If the first return value is false the item won't be removed from the character's inventory. The second being false causes the default message to not be shown.
function ITEM:OnHealed(character, companionItemInstance) end

-- Network string for opening the companion selection UI
if (SERVER) then
	util.AddNetworkString("ixCompanionHealOpen")
	util.AddNetworkString("ixCompanionHealSelect")
end

-- Client-side VGUI creation
if (CLIENT) then
	net.Receive("ixCompanionHealOpen", function()
		local companions = net.ReadTable()
		local itemID = net.ReadUInt(32)

		local frame = vgui.Create("DFrame")
		frame:SetSize(ScrW() * 0.2, math.max(ScrH() * 0.2, 200))
		frame:Center()
		frame:SetTitle("Select Companion to Heal")
		frame:MakePopup()
		frame.OnFocusChanged = function(self, gained)
			if (not gained) then
				self:Close()
			end
		end

		local scrollPanel = vgui.Create("DScrollPanel", frame)
		scrollPanel:Dock(FILL)

		local list = vgui.Create("DListLayout", scrollPanel)
		list:Dock(TOP)

		local addedAnyButtons = false

		for _, companionData in ipairs(companions) do
			addedAnyButtons = true

			local button = list:Add("DButton")
			button:SetText(companionData.name ..
				" (" .. companionData.health .. " / " .. companionData.maxHealth .. " HP)")
			button:Dock(TOP)
			button:DockMargin(0, 0, 0, 5)
			button.DoClick = function()
				net.Start("ixCompanionHealSelect")
				net.WriteUInt(itemID, 32)
				net.WriteUInt(companionData.instanceID, 32)
				net.SendToServer()
				frame:Close()
			end

			if (companionData.health >= companionData.maxHealth) then
				button:SetEnabled(false)
			end
		end

		-- If we didn't add any buttons, add a label to inform the player.
		if (not addedAnyButtons) then
			local noCompanionsLabel = list:Add("DLabel")
			noCompanionsLabel:SetText("You have no companions to heal.")
			noCompanionsLabel:SetTextColor(Color(100, 150, 255))
			noCompanionsLabel:Dock(TOP)
		end

		-- Shrink the frame if the list is smaller than the frame
		list:InvalidateLayout(true)

		local listHeight = list:GetTall()
		local frameTitleHeightWithPadding = 26 + 8

		if (listHeight < (frame:GetTall() - frameTitleHeightWithPadding)) then
			frame:SetTall(listHeight + frameTitleHeightWithPadding)
		end
	end)
end

-- Server-side companion selection handler
if (SERVER) then
	net.Receive("ixCompanionHealSelect", function(len, client)
		local itemID = net.ReadUInt(32)
		local companionInstanceID = net.ReadUInt(32)

		local character = client:GetCharacter()
		if (not character) then return end

		local inventory = character:GetInventory()
		if (not inventory) then return end

		local item = inventory:GetItemByID(itemID)
		if (not item) then return end

		-- Find the companion item instance
		local companionItem = inventory:GetItemByID(companionInstanceID)
		if (not companionItem or not companionItem.isCompanion) then
			client:Notify("Invalid companion selected!")
			return
		end

		item:HealCompanion(character, item, companionItem)
	end)
end

function ITEM:HealCompanion(character, healingItem, companionItemInstance)
	local client = character:GetPlayer()
	local currentHealth = companionItemInstance.companionHealth or 0

	if (currentHealth <= 0) then
		local canRevive, reason = self:CanReviveCompanion(character, companionItemInstance)

		if (not canRevive) then
			client:Notify(reason)
			return
		end
	end

	local maxHealth = companionItemInstance.companionMaxHealth or 100
	local amountToHeal = self:GetCompanionHealAmount(character, companionItemInstance)

	if (amountToHeal <= 0) then
		return
	end

	if (companionItemInstance.spawned) then
		local entity = Entity(companionItemInstance.spawned)

		if (IsValid(entity)) then
			if (client:GetPos():DistToSqr(entity:GetPos()) > self:GetHealingRange(character, companionItemInstance) ^ 2) then
				client:Notify("Your companion is too far away to heal.")
				return
			end
		end
	end

	currentHealth = math.min(currentHealth + amountToHeal, maxHealth)
	companionItemInstance:SetData("companionHealth", currentHealth)

	local entity = companionItemInstance.spawned and Entity(companionItemInstance.spawned)

	if (IsValid(entity)) then
		entity:SetHealth(currentHealth)
	end

	local removeItem, showDefaultMessage = self:OnHealed(character, companionItemInstance)

	if (removeItem ~= false) then
		companionItemInstance:Remove()
	end

	if (showDefaultMessage ~= false) then
		if (currentHealth >= maxHealth) then
			client:Notify("You have healed your companion to full health.")
		else
			client:Notify("You have healed your companion for " .. tostring(amountToHeal) .. " HP.")
		end
	end

	if (healingItem.useSound) then
		client:EmitSound(healingItem.useSound)
	end
end

ITEM.functions.Heal = {
	OnRun = function(item)
		local client = item.player
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		-- Collect companion data to send to client
		local companions = {}

		for _, invItem in pairs(inventory:GetItems()) do
			if (invItem.isCompanion) then
				table.insert(companions, {
					instanceID = invItem:GetID(),
					name = invItem:GetName(),
					health = invItem.companionHealth or 0,
					maxHealth = invItem.companionMaxHealth or 100
				})
			end
		end

		-- Send companion data to client to open VGUI
		net.Start("ixCompanionHealOpen")
		net.WriteTable(companions)
		net.WriteUInt(item:GetID(), 32)
		net.Send(client)

		-- Don't remove the item yet, it will be removed in HealCompanion if successful
		return false
	end
}
