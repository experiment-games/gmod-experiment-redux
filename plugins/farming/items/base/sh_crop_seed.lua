local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Jar of Seeds"
ITEM.model = Model("models/props_lab/jar01b.mdl")
ITEM.category = "Farming"
ITEM.width = 1
ITEM.height = 1
ITEM.description = "A jar filled with seeds."
ITEM.noBusiness = true
ITEM.cropType = "carrot" -- Default crop type, should be overridden

ITEM.functions.Plant = {
	name = "Plant",
	tip = "Plant these seeds in the ground.",
	icon = "icon16/arrow_down.png",
	OnRun = function(item)
		local client = item.player
		local trace = client:GetEyeTrace()
		local config = PLUGIN:GetCropConfig(item.cropType)

		if (not config) then
			ix.util.SchemaErrorNoHalt("Invalid crop type " .. item.cropType)
			client:Notify("This seed seems to be corrupted and cannot be planted. (Please inform a developer)")
			return false
		end

		if (trace.HitPos:DistToSqr(client:GetPos()) > ix.config.Get("maxInteractionDistance") ^ 2) then
			client:Notify("You're too far away to plant seeds there.")
			return false
		end

		if (not PLUGIN:CheckValidGround(trace.HitPos)) then
			client:Notify("You can only plant seeds in farming soils.")
			return false
		end

		-- Check if there's already a crop nearby
		for _, ent in pairs(ents.FindInSphere(trace.HitPos, config.plantingRadius)) do
			if (ent:GetClass() == "exp_crop") then
				client:Notify("There's already a crop planted nearby.")
				return false
			end
		end

		-- Create the crop entity
		local crop = ents.Create("exp_crop")
		crop:SetPos(trace.HitPos)
		crop.cropType = item.cropType
		crop:Spawn()

		client:Notify("You planted " .. item.name .. "!")
	end,
	OnCanRun = function(item)
		return IsValid(item.player) and item.player:Alive()
	end,
}
