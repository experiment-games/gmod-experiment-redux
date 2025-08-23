local ITEM = ITEM

ITEM.name = "Junk (Material)"
ITEM.model = "models/gibs/scanner_gib02.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.description = "Junk that can be scrapped into useful materials."
ITEM.noBusiness = true
-- ITEM.scrapMaterials = {
-- ["material_plastic"] = 1,
-- ["material_metal"] = 1,
-- ["material_wood"] = 1
-- }

function ITEM:GetFilters()
	return {
		["Is junk"] = "checkbox"
	}
end

function ITEM:GetScrapMaterials(client)
	return self.scrapMaterials
end

ITEM.functions.Scrap = {
	name = "Scrap",
	tip = "Scrap this item",
	icon = "icon16/wrench.png",
	OnRun = function(item)
		local client = item.player
		local character = client:GetCharacter()
		local scrapMaterials = item:GetScrapMaterials(client)

		for materialItem, amount in pairs(scrapMaterials) do
			if (not character:GetInventory():Add(materialItem, amount)) then
				ix.item.Spawn(materialItem, client)
			end
		end

		client:Notify("You scrapped the item for materials.")

		client:EmitSound("ambient/materials/clang1.wav", 30, math.random(150, 200))

		hook.Run("OnItemScrapped", client, item, scrapMaterials)
	end
}
