local ITEM = ITEM

ITEM.name = "Crafting Chemistry Station"
ITEM.description = "Blueprint for building a crafting chemistry station."
ITEM.model = "models/mosi/fnv/props/workstations/chemistrylab.mdl"
ITEM.structureModel = "models/mosi/fnv/props/workstations/chemistrylab.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 1000
ITEM.health = 500
ITEM.constructionMaterials = {
	["material_plastic"] = 1,
	["material_glass"] = 4,
	["material_metal"] = 4
}
ITEM.structureOffset = Vector(0, 0, 1)

function ITEM:OnFinishConstruction(structure, client)
	local workstation = ents.Create("exp_chemistry_station")
	workstation:SetPos(structure:GetPos())
	workstation:SetAngles(structure:GetAngles())

	-- Remove the structure parts and add the entity in its place
	structure:Remove()

	workstation:Spawn()
	workstation:Activate()

	return workstation
end
