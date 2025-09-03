local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Defensive Turret (Ceiling)"
ITEM.description = "Blueprint for building a defensive turret that can be mounted on the ceiling."
ITEM.model = "models/combine_turrets/ceiling_turret.mdl"
ITEM.structureModel = ITEM.model
ITEM.width = 1
ITEM.height = 1
-- ITEM.price = 5000
-- TODO: Disabled because we can't interact with the structure somehow. Perhaps the USE trace doesn't hit?
ITEM.noBusiness = true
ITEM.requiresDefensivePerk = true
ITEM.health = 15000
ITEM.constructionMaterials = {
	["material_plastic"] = 1,
	["material_metal"] = 4,
	["logic_board"] = 1,
}
ITEM.structureOffset = Vector(0, 0, -40)
ITEM.structureMaximum = 3
ITEM.iconCam = {
	pos = Vector(43.4826, 61.2703, -19.9838),
	fov = 46.4,
	ang = Angle(-32.5985, 594.9489, -180)
}

function ITEM:OnCanBuild(client, position, angles)
	-- TODO: Can position and angles passed here ever not equal where the trace is?
	local trace = client:GetEyeTraceNoCursor()
	local turretType = "ceiling"

	return PLUGIN:CanSpawnTurret(turretType, trace)
end

function ITEM:OnFinishConstruction(structure, client)
	local position = structure:GetPos()
	local angles = structure:GetAngles()
	local turretType = "ceiling"
	local ownerID = client:GetCharacter():GetID()

	-- Remove the structure parts and add the entity in its place
	structure:Remove()

	local turret = PLUGIN:SpawnTurret(turretType, position, angles, ownerID)

	return turret
end
