local ITEM = ITEM

ITEM.name = "Poisonous Acid"
ITEM.description = "A highly toxic chemical compound. Handle with extreme care. Can be used to poison weapons."
ITEM.model = "models/props_junk/glassjug01.mdl"
ITEM.skin = 0
ITEM.category = "Chemicals"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 200

function ITEM:OnEntityCreated(entity)
	entity:SetMaterial("models/shiny")
	entity:SetColor(Color(100, 255, 100))
end
