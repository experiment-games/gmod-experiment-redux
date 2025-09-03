local ITEM = ITEM

ITEM.name = "Companion Base"
ITEM.model = "models/headcrabclassic.mdl"
ITEM.width = 2
ITEM.height = 2
ITEM.category = "Companions"
ITEM.isCompanion = true
ITEM.description = "A loyal companion that will follow you around."
ITEM.noDrop = true

-- Be neutral by default.
ITEM.defaultDisposition = { D_NU, 99 }

-- Starts every companion with no dispositions towards any character key.
ITEM.dispositions = {}

-- The health of the entity and the maximum health it can have
ITEM.companionHealth = 500
ITEM.companionMaxHealth = 500

-- The entity will sit down after waiting standing still for this many seconds
ITEM.companionSitAfterWaiting = 10

-- Whether this companion can be renamed
ITEM.canBeRenamed = true

-- Network strings
if (SERVER) then
	util.AddNetworkString("ixCompanionRename")
	util.AddNetworkString("ixCompanionQuickCommand")
end

if (CLIENT) then
	function ITEM:GetName()
		local customName = self:GetData("name")

		if (customName) then
			local baseName = self.name
			return customName .. " (" .. baseName .. ")"
		end

		return self.name
	end

	function ITEM.PaintOver(icon, item, width, height)
		local nameLabel = item.nameLabel

		-- Paint a health bar behind the name label, ensure it fits within the panel.
		if (not IsValid(nameLabel)) then
			return
		end

		local health = self:GetCompanionHealth()
		local maxHealth = self.companionMaxHealth or 100
		local color = ix.config.Get("color") or Color(140, 140, 140)
		local x, y = nameLabel:GetPos()
		local nameW, nameH = nameLabel:GetSize()

		-- Right aligned health bar
		x = x + nameW + 8
		local barW = math.min(width - x - 8, 256)
		x = width - barW - 8

		local borderThickness = 1

		y = (height * .5) - (nameH * .5)

		-- Draw the health bar background and bar
		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawRect(x - borderThickness, y - borderThickness, barW + (borderThickness * 2),
			nameH + (borderThickness * 2))
		surface.SetDrawColor(color.r, color.g, color.b, 100)
		local healthWidth = math.Clamp(barW * (health / maxHealth), 0, barW)
		surface.DrawRect(x, y, healthWidth, nameH)

		-- Draw the health text
		draw.SimpleText(
			health .. " / " .. maxHealth .. " HP",
			"ixSmallFont",
			x + barW / 2,
			y + nameH / 2,
			color_white,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)
	end

	-- Handle rename request from client
	net.Receive("ixCompanionRename", function()
		local itemID = net.ReadUInt(32)
		local character = LocalPlayer():GetCharacter()
		if (not character) then return end

		local inventory = character:GetInventory()
		if (not inventory) then return end

		local item = inventory:GetItemByID(itemID)
		if (not item or not item.isCompanion) then return end

		Derma_StringRequest(
			"Rename Companion",
			"What would you like to rename your companion to?",
			item:GetData("name") or item.name,
			function(name)
				net.Start("ixCompanionRename")
				net.WriteUInt(itemID, 32)
				net.WriteString(name)
				net.SendToServer()
			end
		)
	end)
end

if (SERVER) then
	function ITEM:GetModel()
		return "models/props_lab/kennel_physics.mdl"
	end

	-- Handle save data filtering
	function ITEM:OnSave()
		-- Copy all data except spawned state
		self:SetData("spawned", nil)
	end

	-- Handle rename from client
	net.Receive("ixCompanionRename", function(len, client)
		local itemID = net.ReadUInt(32)
		local name = net.ReadString()

		local character = client:GetCharacter()
		if (not character) then return end

		local inventory = character:GetInventory()
		if (not inventory) then return end

		local item = inventory:GetItemByID(itemID)
		if (not item or not item.isCompanion) then return end

		if (not name or name == "") then
			client:Notify("You must provide a name to rename your companion to!")
			return
		end

		item:SetData("name", name)
		client:Notify("You have renamed your companion to '" .. name .. "'.")

		-- Update spawned companion name if exists
		local companion = item:GetCompanionEntity()
		if (IsValid(companion)) then
			companion:SetDisplayName(name)
		end
	end)
end

function ITEM:GetCompanionHealth()
	local health = self:GetData("companionHealth", self.companionHealth or 100)

	-- If the companion is spawned in the world, ask the entity for the health.
	-- This is because we don't want to update the item each time the health changes
	-- for performance reasons.
	if (self:GetData("spawned")) then
		local entity = Entity(self:GetData("spawned"))

		if (IsValid(entity)) then
			health = entity:Health()
		else
			health = 0
		end
	end

	return health
end

function ITEM:GetCompanionEntity()
	if (not self:GetData("spawned")) then
		return nil, nil
	end

	local entity = Entity(self:GetData("spawned"))
	return entity, self
end

function ITEM:PopulateTooltip(tooltip)
	local health = self:GetCompanionHealth()
	local maxHealth = self.companionMaxHealth or 100

	local healthPanel = tooltip:AddRowAfter("description", "health")
	healthPanel:SetText("Health: " .. health .. "/" .. maxHealth)
	healthPanel:SetBackgroundColor(derma.GetColor("Success", tooltip))
end

function ITEM:OnPlayerUnequipped(character)
	local client = character:GetPlayer()
	local companion = self:GetCompanionEntity()

	if (IsValid(companion)) then
		-- This would call your companion system's remove function
		-- For now, just remove the entity
		companion:Remove()
		self:SetData("spawned", nil)
		client:Notify("You have removed your companion.")
		return
	end
end

--- Called when a character uses the item.
function ITEM:SpawnCompanion(client)
	local companion = self:GetCompanionEntity()

	if (IsValid(companion)) then
		client:Notify("You already have a companion spawned!")
		return false
	end

	local trace = client:GetEyeTrace()

	-- Basic distance check
	if (client:EyePos():DistToSqr(trace.HitPos) > 192 ^ 2) then
		client:Notify("You cannot spawn a companion that far away!")
		return false
	end

	-- Don't spawn the companion if it's out of health
	local health = self:GetCompanionHealth()
	if (health <= 0) then
		client:Notify("Your companion is out of health and cannot be spawned!")
		return false
	end

	local companion = Schema.companion.Spawn(self.entityID, client, trace.HitPos, self)

	if (self.OnSpawnedCompanion) then
		self:OnSpawnedCompanion(client, companion)
	end

	client:Notify("You have spawned your companion.")

	-- Don't remove the item from inventory
	return false
end

ITEM.functions.Rename = {
	name = "Rename",
	tip = "Rename this companion",
	icon = "icon16/textfield_rename.png",
	OnCanRun = function(item)
		return item.canBeRenamed ~= false
	end,
	OnRun = function(item)
		local client = item.player

		-- Send net message to open rename dialog on client
		net.Start("ixCompanionRename")
		net.WriteUInt(item:GetID(), 32)
		net.Send(client)

		return false -- Don't remove item
	end
}

ITEM.functions.Toggle = {
	name = "Toggle",
	tip = "Spawn or despawn this companion",
	icon = "icon16/arrow_refresh.png",
	OnRun = function(item)
		local client = item.player
		local character = client:GetCharacter()
		local companion = item:GetCompanionEntity()

		if (IsValid(companion)) then
			-- Despawn companion
			item:OnPlayerUnequipped(character)
			return false
		else
			-- Spawn companion
			return item:SpawnCompanion(client)
		end
	end
}

ITEM.functions.Command = {
	name = "Command",
	tip = "Issue a command to this companion",
	icon = "icon16/shape_ungroup.png",
	OnRun = function(item, data)
		local client = item.player
		local character = client:GetCharacter()
		if (not character) then return false end

		local companion = item:GetCompanionEntity()
		if (not IsValid(companion)) then return false end

		Schema.companion.PlayerTryCommand(client, companion, data.command, item)

		return false -- Don't remove item
	end,
	OnCanRun = function(item, data)
		-- Ensure it's in the world and a command has been provided
		if (data and data.command and item:GetData("spawned") and IsValid(Entity(item:GetData("spawned")))) then
			return true
		end

		return false
	end,
}
