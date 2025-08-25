local ITEM = ITEM

ITEM.name = "Explosive Compound"
ITEM.description = "A highly unstable chemical mixture. Extremely dangerous to handle."
ITEM.model = "models/props_junk/glassjug01.mdl"
ITEM.skin = 0
ITEM.category = "Chemicals"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 300

function ITEM:OnEntityCreated(entity)
	entity:SetColor(Color(255, 100, 100))
end
