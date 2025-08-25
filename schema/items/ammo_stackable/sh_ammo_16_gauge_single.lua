local ITEM = ITEM

ITEM.calibre = "16 Gauge"
ITEM.name = ITEM.calibre .. " Shell"
ITEM.ammo = Schema.ammo.ConvertToAmmo(ITEM.calibre)
ITEM.model = "models/experiment-redux/ammo/12gauge.mdl"
ITEM.noBusiness = true
ITEM.ammoAmount = 1
ITEM.description = "A single 16 gauge shell"
ITEM.chanceToScavenge = Schema.RARITY_RARE

if (SERVER) then
	ix.util.AddResourceFile("models/experiment-redux/ammo/12gauge.mdl")
	ix.util.AddResourceFile("materials/models/experiment-redux/ammo/12gauge.vmt")
end

function ITEM:GetName()
	if (self:GetData("poisoned")) then
		return "Poisoned " .. self.name
	end

	return self.name
end
