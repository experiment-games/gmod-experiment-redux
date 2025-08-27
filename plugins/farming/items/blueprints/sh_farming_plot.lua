local ITEM = ITEM

ITEM.name = "Farming Plot"
ITEM.description = "Blueprint for building a plot on which you can farm."
ITEM.model = "models/experiment-redux/farming_plot.mdl"
ITEM.structureModel = ITEM.model
ITEM.width = 1
ITEM.height = 1
ITEM.price = 1000
ITEM.health = 500
ITEM.constructionMaterials = {
	["material_wood"] = 4,
}
ITEM.structureOffset = Vector(0, 0, 1)
ITEM.requiresFarmingPerk = true

function ITEM:OnFinishConstruction(structure, client)
	structure.ValidSoilFor = "crops"

	-- Disable locking/unlocking, we don't want to pass through this like we may for other structures
	structure:DisableDoorAccess()

	-- We don't want to leave crops floating once the plot is removed
	structure:CallOnRemove("removeCropsNearby", function()
		for _, crop in ipairs(ents.FindInSphere(structure:GetPos(), 64)) do
			if (IsValid(crop) and crop:GetClass() == "exp_crop") then
				crop:Remove()
			end
		end
	end)
end
