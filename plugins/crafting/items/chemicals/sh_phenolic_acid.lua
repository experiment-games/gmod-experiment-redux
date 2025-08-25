local ITEM = ITEM

ITEM.name = "Phenolic Acid"
ITEM.description =
"A chemical compound derived from organic materials through distillation. Used in various chemical combinations."
ITEM.model = "models/props_junk/glassjug01.mdl"
ITEM.skin = 0
ITEM.category = "Chemicals"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 50

function ITEM:OnEntityCreated(entity)
	entity:SetMaterial("models/shiny")
	entity:SetColor(Color(150, 100, 50))
end
