local ITEM = ITEM

ITEM.name = "Beer"
ITEM.price = 15
ITEM.shipmentSize = 6
ITEM.model = "models/props_junk/garbage_glassbottle003a.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Consumables"
ITEM.description = "A glass bottle filled with liquid, it has a funny smell. It might make you feel stronger."
ITEM.attributeBoosts = {
	["strength"] = {
		amount = 2,
		duration = 3600
	}
}

function ITEM:OnRegistered()
	self.functions.Consume.name = "Drink"
end

function ITEM:GetEmitBoostSound()
	return "npc/barnacle/barnacle_gulp" .. math.random(1, 2) .. ".wav"
end

function ITEM:OnBoosted()
	local client = self.player
	Schema.achievement.Progress("liquid_courage", client)

	hook.Run("OnPlayerDrinkAlcohol", client, self)
end
