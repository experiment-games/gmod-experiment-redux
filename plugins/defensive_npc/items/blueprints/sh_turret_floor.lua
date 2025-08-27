local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Defensive Turret (Floor)"
ITEM.description = "Blueprint for building a defensive turret that can be set on the ground."
ITEM.model = "models/combine_turrets/floor_turret.mdl"
ITEM.skin = 1
ITEM.structureModel = ITEM.model
ITEM.width = 1
ITEM.height = 1
ITEM.price = 5000
ITEM.health = 2500
ITEM.constructionMaterials = {
	["material_plastic"] = 1,
	["material_metal"] = 4,
	["logic_board"] = 1,
}
ITEM.structureOffset = Vector(0, 0, 1)
ITEM.structureMaximum = 2
ITEM.requiresDefensivePerk = true
ITEM.iconCam = {
	pos = Vector(55.9871, -29.91, 59.9158),
	fov = 52.8,
	ang = Angle(25.0346, 148.8669, -0.0000)
}

function ITEM:OnFinishConstruction(structure, client)
	local position = structure:GetPos()
	local angles = structure:GetAngles()
	local turretType = "floor"
	local ownerID = client:GetCharacter():GetID()

	-- Remove the structure parts and add the entity in its place
	structure:Remove()

	local turret = PLUGIN:SpawnTurret(turretType, position, angles, ownerID)

	return turret
end
