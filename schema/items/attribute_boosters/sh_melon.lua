local ITEM = ITEM

ITEM.name = "Melon"
ITEM.price = 15
ITEM.shipmentSize = 10
ITEM.model = "models/props_junk/watermelon01.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Consumables"
ITEM.description = "A fresh green fruit, it'll energize you and make you feel more agile."
ITEM.attributeBoosts = {
	["acrobatics"] = {
		amount = 2,
		duration = 600,
	},
	["agility"] = {
		amount = 2,
		duration = 600,
	},
}

function ITEM:OnRegistered()
	self.functions.Consume.name = "Eat"
end

function ITEM:OnBoosted()
	local client = self.player
	client:SetHealth(math.Clamp(client:Health() + 1, 0, client:GetMaxHealth()))
end

function ITEM:GetEmitBoostSound()
	return "npc/barnacle/barnacle_crunch" .. math.random(2, 3) .. ".wav", 50, 155, 0.2
end
