local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Newbie Nano Tech"
ITEM.noBusiness = true
ITEM.noDrop = true
ITEM.model = "models/computergibs.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Consumables"
ITEM.description = "A takeout carton, it's filled with cold noodles. Eating this might make you feel more enduring."

ITEM.functions.Implant = {
	OnRun = function(item)
		local client = item.player

		Schema.buff.SetActive(client, "newbie")

		client:EmitSound("items/medshot4.wav")

		Schema.progression.Change(client, PLUGIN.uniqueID, PLUGIN.PROGRESSION_MISSION_2_USE_NANO_TECH_ITEM, true)
	end
}
