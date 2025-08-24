local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Rot Prevention Spray"
ITEM.description = "A chemical spray that prevents crops from rotting when applied."
ITEM.category = "Farming"
ITEM.model = "models/props_junk/garbage_plasticbottle001a.mdl"
ITEM.width = 1
ITEM.height = 2
ITEM.price = 100

ITEM.functions.PreventRot = {
	name = "Prevent Rot",
	tip = "Apply to crops to prevent them from rotting.",
	icon = "icon16/shield.png",
	OnRun = function(item)
		local client = item.player
		local trace = client:GetEyeTrace()

		return PLUGIN:PreventCropRot(client, trace.HitPos)
	end,
	OnCanRun = function(item)
		return IsValid(item.player) and item.player:Alive()
	end,
}
