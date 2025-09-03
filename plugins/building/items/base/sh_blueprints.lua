local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Blueprint"
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.description = "A blueprint that can be used to construct structures."
ITEM.category = "Learnable Blueprints"

ITEM.structureModel = "models/props_c17/oildrum001.mdl"
ITEM.constructionMaterials = {
	-- Which materials are required to build this
	-- ["material_metal"] = 5
}
ITEM.health = 100

function ITEM:GetFilters()
	return {
		["Is blueprint"] = "checkbox"
	}
end

function ITEM:GetModel()
	if (SERVER) then
		-- Attachments are really small, so to prevent them glitching, show a bigger model when spawning the item on the server
		return "models/props_lab/clipboard.mdl"
	end

	return self.model
end

function ITEM:GetConstructionMaterials()
	return self.constructionMaterials
end

local iconMaterial = Material("icon16/bricks.png")
local iconSize = 16
local iconMargin = 8
local overlayMaterial = Material("experiment-redux/blueprint.png")

function ITEM.PaintOver(icon, item, width, height)
	if (not icon.expOverridePaint) then
		icon.expOverridePaint = true

		icon.Paint = function(icon, width, height)
			surface.SetDrawColor(255, 255, 255, 100)
			surface.SetMaterial(overlayMaterial)
			surface.DrawTexturedRect(0, 0, width, height)
		end
	end

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(iconMaterial)
	surface.DrawTexturedRect(width - iconSize - iconMargin, height - iconSize - iconMargin, iconSize, iconSize)
end

--- Override this function so it returns the structure and the way it's built at the position and angles`
--- This is used by the exp_structure_builder.
function ITEM:GetStructure(client)
	return {
		{
			model = self.structureModel,
			position = Vector(0, 0, 0),
			angles = Angle(0, 0, 0),
		}
	}
end

ITEM.functions.Learn = {
	name = "Learn",
	icon = "icon16/book_open.png",
	OnRun = function(item)
		local client = item.player

		if (PLUGIN:HasLearnedBlueprint(client, item.uniqueID)) then
			client:NotifyLocalized("alreadyLearnedBlueprint")
			return false
		end

		PLUGIN:LearnBlueprint(client, item.uniqueID)
		client:NotifyLocalized("learnedBlueprint")

		return true
	end,
}
