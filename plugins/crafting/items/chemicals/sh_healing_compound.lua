local ITEM = ITEM

ITEM.name = "Healing Compound"
ITEM.description = "A beneficial chemical that promotes healing and recovery."
ITEM.model = "models/props_junk/glassjug01.mdl"
ITEM.skin = 0
ITEM.category = "Chemicals"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 150

function ITEM:OnEntityCreated(entity)
	entity:SetColor(Color(100, 150, 255))
end

ITEM.functions.Use = {
	name = "Drink",
	tip = "Consume this healing compound.",
	icon = "icon16/heart.png",
	OnRun = function(item)
		local client = item.player

		-- Heal the player
		local currentHealth = client:Health()
		local newHealth = math.min(currentHealth + 40, client:GetMaxHealth())
		client:SetHealth(newHealth)

		client:Notify("You feel rejuvenated!")
		client:EmitSound("npc/barnacle/barnacle_gulp" .. math.random(1, 2) .. ".wav")

		return true -- Remove the item after use
	end,
	OnCanRun = function(item)
		return IsValid(item.player) and item.player:Alive()
	end
}
