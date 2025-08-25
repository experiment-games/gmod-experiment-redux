local ITEM = ITEM

ITEM.name = "Explosive Compound Recipe"
ITEM.description = "Dangerous instructions for creating explosive compounds. Handle with extreme care."
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.category = "Recipes"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 1000

ITEM.craftingCombination = {
	output = { explosive_compound = 1 },
	components = { phenolic_acid = 2, ascorbic_acid = 2, poisonous_acid = 1 }
}

ITEM.craftingTime = 60

function ITEM:OnCraftingOutput(outputItem)
	if (outputItem) then
		outputItem:SetData("explosive_power", 150)
		outputItem:SetData("blast_radius", 200)
	end
end
