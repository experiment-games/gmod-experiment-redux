local PLUGIN = PLUGIN
local ITEM = ITEM

ITEM.name = "Fertilizer"
ITEM.description = "Organic fertilizer that speeds up crop growth when applied."
ITEM.category = "Farming"
ITEM.model = "models/props/cs_militia/fertilizer.mdl"
ITEM.modelScale = 0.5
ITEM.width = 1
ITEM.height = 2
ITEM.price = 100

function ITEM:OnEntityCreated(entity)
	entity:SetModelScale(self.modelScale)

	-- Disable collisions with players
	entity:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

	-- Set the weight to way less so it isn't so funky in it's behaviour
	local physObj = entity:GetPhysicsObject()

	if (IsValid(physObj)) then
		physObj:SetMass(10)
	end
end

ITEM.functions.Fertilize = {
	name = "Fertilize",
	tip = "Apply fertilizer to nearby crops.",
	icon = "experiment-redux/icons/silk_fertilize.png",
	OnRun = function(item)
		local client = item.player
		local trace = client:GetEyeTrace()

		return PLUGIN:FertilizeCrop(client, trace.HitPos)
	end,
	OnCanRun = function(item)
		return IsValid(item.player) and item.player:Alive()
	end,
}
