local PLUGIN = PLUGIN

PLUGIN.name = "Building"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Restricts construction to only allowed props. Requiring blueprints and materials to build."

ix.util.Include("sv_plugin.lua")

ix.config.Add("maxBuildGroundLevel", 2,
	"The maximum distance from the ground players can build (in structures on top of structures).", nil, {
	data = { min = 0, max = 100, decimals = 0 },
	category = "Building"
})

function PLUGIN:EntityIsDoor(entity)
	if (entity.IsStructureOrPart) then
		return true
	end
end

if (CLIENT) then
	-- Have the blueprint weapon not show the hazardous environment sheet, but a custom one with blueprints on them
	Schema.util.ReplaceMaterialTexture(
		Material("models/props_lab/clipboard_sheet"),
		Material("experiment-redux/replacements/clipboard")
	)

	function PLUGIN:RequestBuildStructure(position, angles)
		net.Start("ixBuildingRequestBuildStructure")
		net.WriteVector(position)
		net.WriteAngle(angles)
		net.SendToServer()
	end

	function PLUGIN:GetDoorMenu(door, access, entity)
		if (not entity.IsStructureOrPart) then
			return
		end

		door = door.IsStructurePart and door:GetParent() or door

		local menu = vgui.Create("expStructureAccessMenu")
		menu:SetStructure(door, access, entity)
		return menu
	end
end

function PLUGIN:InitializedPlugins()
	local helperMetaTable = {}
	helperMetaTable.__index = helperMetaTable
	local toBeRemoved = {}

	function helperMetaTable:Add(data)
		table.insert(self, data)
	end

	function helperMetaTable:Remove(uniqueID)
		table.insert(toBeRemoved, uniqueID)
	end

	function helperMetaTable:RemoveQueued()
		for _, uniqueID in ipairs(toBeRemoved) do
			for i, data in ipairs(self) do
				if (data.uniqueID == uniqueID) then
					table.remove(self, i)
				end
			end
		end

		toBeRemoved = {}
	end

	self.allowedProps = setmetatable({}, helperMetaTable)

	hook.Run("AdjustAllowedProps", self.allowedProps)

	self.allowedProps:RemoveQueued()

	-- Register the allowed props as blueprint items
	for _, data in ipairs(self.allowedProps) do
		local uniqueID = string.lower(data.uniqueID)
		local ITEM = ix.item.Register(uniqueID, "base_blueprints", false, nil, true)

		table.Merge(ITEM, data, true)

		ITEM.structureModel = data.model
		ITEM.uniqueID = uniqueID
	end
end

function PLUGIN:GetPlacementTrace(client)
	local maxDistance = 100
	local eyesPosition = client:EyePos()
	local trace = util.TraceLine({
		start = eyesPosition,
		endpos = eyesPosition + (client:GetAimVector() * maxDistance),
		filter = client
	})

	return trace.HitPos, Angle(0, client:EyeAngles().y, 0)
end

function PLUGIN:GetPlacementValid(client, position, angles)
	-- Allow buildings to clip by a margin
	local clipMargin = 10
	local maxDistance = clipMargin + 10
	local groundTrace = util.TraceLine({
		start = position + Vector(0, 0, clipMargin),
		endpos = position - Vector(0, 0, maxDistance),
		filter = client
	})

	-- ! This sucks: It's always close to a spawn point with the amount we have.
	-- ! I "solve" the problem of people prop blocking eachother, by just giving everyone a crowbar by default.
	-- 	-- Check if this is close to a spawn point
	-- 	local spawns = Schema.spawnPoints.GetAll()
	-- 	local minimumDistance = 1048

	-- 	for _, spawn in ipairs(spawns) do
	-- 		local distance = spawn.position:DistToSqr(position)

	-- 		if (distance < (minimumDistance * minimumDistance)) then
	-- 			return false, "You cannot build this close to a spawn point."
	-- 		end
	-- 	end

	if (groundTrace.HitWorld) then
		return true
	end

	if (IsValid(groundTrace.Entity) and (groundTrace.Entity.IsStructure or groundTrace.Entity.IsStructurePart)) then
		-- Limit how far up players can build upon structures
		local maxBuildGroundLevel = ix.config.Get("maxBuildGroundLevel")

		if (groundTrace.Entity.IsStructure or groundTrace.Entity.IsStructurePart) then
			local groundLevel = groundTrace.Entity:GetGroundLevel()

			if (groundLevel >= maxBuildGroundLevel) then
				return false, "You cannot build this far off the ground."
			end
		end

		return true, groundTrace.Entity
	end

	return false, "You cannot build this far off the ground."
end

function PLUGIN:AdjustAllowedProps(allowedProps)
	--[[
		Plastic props
	--]]
	allowedProps:Add({
		uniqueID = "blueprint_blue_barrel",
		name = "Blue Barrel",
		description = "A blue barrel.",
		price = 100,
		health = 100,
		model = "models/props_borealis/bluebarrel001.mdl",
		constructionMaterials = {
			["material_plastic"] = 5,
			["material_metal"] = 1
		},
		structureOffset = Vector(0, 0, 28),
	})

	--[[
		Hard metal props
	--]]
	allowedProps:Add({
		uniqueID = "blueprint_storefront_bars",
		name = "Storefront Bars",
		description = "Strong bars to protect your storefront.",
		price = 200,
		health = 4000,
		model = "models/props_building_details/Storefront_Template001a_Bars.mdl",
		constructionMaterials = {
			["material_metal"] = 10
		},
		structureOffset = Vector(0, 0, 54),
	})

	allowedProps:Add({
		uniqueID = "blueprint_blast_door",
		name = "Blast Door",
		description = "A blast door to protect your base.",
		price = 200,
		health = 5000,
		model = "models/props_lab/blastdoor001b.mdl",
		constructionMaterials = {
			["material_metal"] = 15
		},
		structureOffset = Vector(0, 0, 1),
	})

	-- Commented because we should only provide small to medium props (in order to prevent prop climbing to high places)
	-- allowedProps:Add({
	-- 	uniqueID = "blueprint_blast_door_double",
	-- 	name = "Welded Double Blast Door",
	-- 	description = "Double blast doors welded together.",
	-- 	price = 400,
	-- 	health = 400,
	-- 	model = "models/props_lab/blastdoor001c.mdl",
	-- 	constructionMaterials = {
	-- 		["material_metal"] = 25
	-- 	}
	-- })

	--[[
		Wooden props
	--]]
	allowedProps:Add({
		uniqueID = "blueprint_furniture_shelf",
		name = "Shelf",
		description = "A shelf to store your items.",
		price = 150,
		health = 400,
		model = "models/props_c17/FurnitureShelf001a.mdl",
		constructionMaterials = {
			["material_wood"] = 10
		},
		structureOffset = Vector(0, 0, 44),
	})

	allowedProps:Add({
		uniqueID = "blueprint_furniture_table",
		name = "Table",
		description = "A table to place your items.",
		price = 150,
		health = 300,
		model = "models/props_c17/FurnitureTable001a.mdl",
		constructionMaterials = {
			["material_wood"] = 10
		},
		structureOffset = Vector(0, 0, 20),
	})

	allowedProps:Add({
		uniqueID = "blueprint_oil_drum",
		name = "Oil Drum",
		description = "A barrel to store oil.",
		price = 100,
		health = 100,
		model = "models/props_c17/oildrum001.mdl",
		constructionMaterials = {
			["material_metal"] = 5
		},
		structureOffset = Vector(0, 0, 1),
	})
end
