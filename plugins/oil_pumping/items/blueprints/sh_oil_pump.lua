local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Oil Pump"
ITEM.description =
"A heavy-duty oil pump for extracting crude oil from underground reserves. Requires installation in oil fields."
ITEM.model = "models/experiment-redux/big_oil_pump02.mdl"
ITEM.skin = 0
ITEM.structureModel = ITEM.model
ITEM.width = 2
ITEM.height = 2
ITEM.price = 15000
ITEM.health = 1000
ITEM.constructionMaterials = {
	["material_metal"] = 8,
	["logic_board"] = 1,
}
ITEM.structureOffset = Vector(0, 0, 1)
ITEM.structureMaximum = 1 -- Only one oil pump per player
ITEM.requiresOilPerk = true
ITEM.iconCam = {
	pos = Vector(2012.0795, 947.563, 577.0753),
	ang = Angle(12.8614, 203.923, 0),
	fov = 5.696185702226523
}

function ITEM:GetBoundsCube(structureEntity, boundsMin, boundsMax)
	local boundsMin, boundsMax = structureEntity:GetCollisionBounds()

	-- Shrink the bounds in a bit, because this model has a larger collision box
	boundsMin = boundsMin * 0.9
	boundsMax = boundsMax * 0.9

	-- Raise the bounds up a bit from the ground
	boundsMin = boundsMin + Vector(0, 0, 55)
	boundsMax = boundsMax + Vector(0, 0, 55)

	local cube = Schema.util.ExpandBoundsToCube(
		boundsMin,
		boundsMax,
		structureEntity:GetPos(),
		structureEntity:GetAngles()
	)

	return cube
end

function ITEM:OnCanBuild(client, position, angles)
	if (not PLUGIN:IsValidOilField(position)) then
		client:Notify("Oil pumps can only be constructed in oil fields.")
		return false
	end

	-- TODO: Is the trace ever different from position, angles?
	local trace = client:GetEyeTraceNoCursor()

	if (not PLUGIN:CanSpawnOilPump(trace)) then
		client:Notify("Cannot construct oil pump here. Need flat ground in an oil field.")
		return false
	end

	-- Check for nearby oil pumps
	local nearbyPumps = ents.FindInSphere(position, 500)
	for _, ent in pairs(nearbyPumps) do
		if (IsValid(ent) and ent:GetClass() == "exp_oil_pump") then
			client:Notify("Cannot construct oil pump too close to another oil pump.")
			return false
		end
	end

	return true
end

function ITEM:OnFinishConstruction(structure, client)
	local position = structure:GetPos()
	local angles = structure:GetAngles()
	local ownerID = client:GetCharacter():GetID()

	-- Remove the structure and create the oil pump
	structure:Remove()

	local pump = PLUGIN:SpawnOilPump(position, angles, ownerID)

	-- Give it some initial scrap
	pump:SetScrapAmount(5)

	return pump
end
