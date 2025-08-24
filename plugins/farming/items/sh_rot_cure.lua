local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Rot Cure"
ITEM.description = "A powerful treatment that can cure rotting crops and restore their growth."
ITEM.category = "Farming"
ITEM.model = "models/props_junk/garbage_plasticbottle002a.mdl"
ITEM.width = 1
ITEM.height = 2
ITEM.price = 200

ITEM.functions.CureRot = {
	name = "Cure Rot",
	tip = "Apply to rotten crops to cure them.",
	icon = "icon16/heart.png",
	OnRun = function(item)
		local client = item.player
		local trace = client:GetEyeTrace()

		return PLUGIN:CureCropRot(client, trace.HitPos)
	end,
	OnCanRun = function(item)
		return IsValid(item.player) and item.player:Alive()
	end,
}
