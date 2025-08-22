local ITEM = ITEM

ITEM.name = "Generator Base"
ITEM.color = Color(0, 255, 255, 255)
ITEM.model = "models/props_combine/combine_mine01.mdl"
ITEM.width = 2
ITEM.height = 1
ITEM.noDrop = true
ITEM.category = "Generators"
ITEM.maximum = 1

function ITEM:OnRegistered()
	if (self.isBase) then
		return
	end

	if (not self.generator) then
		error("Generator table not found for item " .. self.uniqueID)
	end

	Schema.generator.Register(
		self.generator.name,
		self.generator.power,
		self.generator.health,
		self.generator.produce,
		self.generator.uniqueID,
		self.generator.upgrades
	)
end

function ITEM:GetPayTimeInSeconds()
	return self.payTimeInSeconds or ix.config.Get("generatorPayTime", 300)
end

if (CLIENT) then
	function ITEM:PopulateTooltip(tooltip)
		if (not self.maximum) then
			return
		end

		local panel = tooltip:AddRowAfter("name", "maximum")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		panel:SetText("You can only have " .. self.maximum .. " of this item in the world at a time!")
		panel:SizeToContents()
	end

	function ITEM:PaintOver(item, w, h)
		if (item:GetData("placed")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
end

function ITEM:CanTransfer(oldInventory, newInventory)
	-- Only allow moving within the same inventory
	return newInventory == nil
end

function ITEM:OnRemoved()
	self:SetData("placed", nil)
end

function ITEM:GetNextUpgrade(entity)
	local generator = Schema.generator.Get(self.generator.uniqueID)

	return generator.upgrades[entity:GetUpgrades() + 1]
end

function ITEM:OnEarned(entity, amount)
	-- Set the power of the generator on the item
	self:SetData("power", entity:GetPower() or 0)
end

function ITEM:OnUpgraded(entity, upgrades)
	self:SetData("upgrades", upgrades)
end

function ITEM:OnDestroyed(entity, damageInfo)
	self:SetData("upgrades", 0)
	self:SetData("power", 0)
end

function ITEM:OnCanOrder(client)
	if (CLIENT) then
		-- OnCanOnder will also be called clientside to see if it should display at all, we will display it, so
		-- users aren't confused why tne item isn't showing up in the business
		return
	end

	local character = client:GetCharacter()

	if (character and character:GetInventory():HasItem(self.uniqueID)) then
		client:Notify("You can not order this as you have reached the maximum amount of this item!")

		return false
	end

	-- TODO: Check existing shipments in the world, belonging to the player for the same item
	-- TODO: That would be friendly, but we can also consider it the players' own mistake since they were warned.
	-- TODO: We'll just let them destroy existing generators if they mistakenly order multiple.

	local generator = Schema.generator.Get(self.generator.uniqueID)

	if (client:IsObjectLimited(generator.uniqueID, self.maximum)) then
		client:Notify("You can not order this as you have reached the maximum amount of this item!")

		return false
	end
end

ITEM.functions.Place = {
	OnRun = function(item)
		local client = item.player
		local generator = Schema.generator.Get(item.generator.uniqueID)

		if (client:IsObjectLimited(generator.uniqueID, item.maximum)) then
			client:Notify("You can not place this as you have reached the maximum amount of this item!")
			return false
		end

		local success, message, trace = client:TryTraceInteractAtDistance()

		if (not success) then
			client:Notify(message)

			return false
		end

		local entity = Schema.generator.Spawn(generator, trace.HitPos, trace.HitNormal:Angle())
		entity:SetupGenerator(client, item)
		client:AddLimitedObject(generator.uniqueID, entity)
		client:RegisterEntityToRemoveOnLeave(entity)

		local physicsObject = entity:GetPhysicsObject()

		if (IsValid(physicsObject)) then
			physicsObject:EnableMotion(false)
		end

		item:SetData("placed", true)

		hook.Run("OnGeneratorPlaced", client, entity, item)

		return false
	end,

	OnCanRun = function(item)
		local client = item.player
		local generator = Schema.generator.Get(item.generator.uniqueID)

		return not client:IsObjectLimited(generator.uniqueID, item.maximum)
	end
}
