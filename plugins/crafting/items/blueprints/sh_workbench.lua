local ITEM = ITEM

ITEM.name = "Crafting Workbench"
ITEM.description = "Blueprint for building a crafting workbench."
ITEM.model = "models/mosi/fnv/props/workstations/reloadingbench.mdl"
ITEM.structureModel = ITEM.model
ITEM.width = 1
ITEM.height = 1
ITEM.price = 3000
ITEM.health = 2500
ITEM.constructionMaterials = {
	["material_plastic"] = 1,
	["material_wood"] = 4,
	["material_metal"] = 4
}
ITEM.structureOffset = Vector(0, 0, 1)

function ITEM:OnFinishConstruction(structure, client)
	local workstation = ents.Create("exp_workbench")
	workstation:SetPos(structure:GetPos())
	workstation:SetAngles(structure:GetAngles())

	-- Remove the structure parts and add the entity in its place
	structure:Remove()

	workstation:Spawn()
	workstation:Activate()

	return workstation
end
