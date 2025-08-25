local ITEM = ITEM

ITEM.name = "Ascorbic Acid"
ITEM.description = "A vitamin compound extracted from fruits and vegetables. Essential for various chemical processes."
ITEM.model = "models/props_junk/glassjug01.mdl"
ITEM.skin = 0
ITEM.category = "Chemicals"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 75

function ITEM:OnEntityCreated(entity)
	entity:SetColor(Color(255, 255, 100))
end
