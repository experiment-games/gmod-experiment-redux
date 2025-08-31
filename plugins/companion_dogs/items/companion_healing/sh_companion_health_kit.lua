local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Companion First Aid Kit"
ITEM.price = 500
ITEM.shipmentSize = 1
ITEM.model = "models/Items/HealthKit.mdl"
ITEM.noBusiness = true
ITEM.useText = "Apply"
ITEM.category = "Medical (Companion)"
ITEM.useSound = "items/medshot4.wav"
ITEM.description = "A first aid kit that will heal your companion by 100 HP."

--- The amount of health to heal the companion by.
ITEM.companionHealAmount = 100

-- Whether or not this item can be used to revive companions from <= 0 health.
ITEM.companionCanBeRevived = true

-- Instead of only ITEM.companionHealAmount, you can use this function to get the heal amount for
-- the companion with more complex logic. For example:
-- --- Called to get the heal amount for the companion.
-- --- @param player Player The player that is using the item.
-- --- @param companionItemInstance ItemInstance The companion item instance that is being healed.
-- --- @return number # The amount of health to heal the companion by.
-- function ITEM:GetCompanionHealAmount(player, companionItemInstance)
-- 	return player:IsSuperAdmin() and 1000 or self.companionHealAmount
-- end

-- Instead of only ITEM.companionCanBeRevived, you can use this function to check whether or not the item
-- can revive the companion with more complex logic. For example:
-- --- Called to check whether or not the item can revive the companion.
-- --- @param player Player The player that is using the item.
-- --- @param companionItemInstance ItemInstance The companion item instance that is being healed.
-- --- @return boolean, string? # Whether or not the item can revive the companion. If false, the second return value is the reason why.
-- function ITEM:CanReviveCompanion(player, companionItemInstance)
-- 	return player:HasReviveSuperpowers() or self.companionCanBeRevived, "You do not have the power to revive companions."
-- end
