local ITEM = ITEM

ITEM.name = "Melon"
ITEM.noBusiness = true
ITEM.model = "models/a31/fallout4/props/plants/melon_item.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Consumables"
ITEM.description = "A fresh green fruit, it'll energize you and make you feel more agile."
ITEM.attributeBoosts = {
	["acrobatics"] = {
		amount = 3,
		duration = 600,
	},
	["agility"] = {
		amount = 3,
		duration = 600,
	},
}

-- Distillation configuration
ITEM.craftingDistillation = {
	time = 180, -- 3 minutes to distill
	output = {
		phenolic_acid = { 1, 3 },
		ascorbic_acid = { 0, 2 } -- Sometimes gives ascorbic acid
	}
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
