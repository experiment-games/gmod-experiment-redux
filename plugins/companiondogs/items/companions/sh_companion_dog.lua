local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.price = 100000
ITEM.name = "Mongrel Dog Companion"
ITEM.model = "models/fallout/mongrel.mdl"
ITEM.noBusiness = true
ITEM.category = "Companion"
ITEM.description = "A loyal companion that will follow you around."
ITEM.canBeRenamed = true
ITEM.entityID = "exp_companion_dog"

-- The model the entity should use
ITEM.companionModel = "models/fallout/mongrel.mdl"

-- The health of the entity and the maximum health it can have
ITEM.companionHealth = 500
ITEM.companionMaxHealth = 500

-- The entity will sit down after waiting standing still for this many seconds
ITEM.companionSitAfterWaiting = 10
