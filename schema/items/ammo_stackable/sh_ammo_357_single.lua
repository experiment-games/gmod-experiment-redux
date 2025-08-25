local ITEM = ITEM

ITEM.calibre = ".357"
ITEM.name = ITEM.calibre .. " Cartridge"
ITEM.ammo = Schema.ammo.ConvertToAmmo(ITEM.calibre)
ITEM.model = "models/experiment-redux/ammo/50ae.mdl"
ITEM.noBusiness = true
ITEM.ammoAmount = 1
ITEM.description = "A single .357 cartridge"
ITEM.chanceToScavenge = Schema.RARITY_RARE

if (SERVER) then
	ix.util.AddResourceFile("models/experiment-redux/ammo/50ae.mdl")
	ix.util.AddResourceFile("materials/models/experiment-redux/ammo/50ae.vmt")
end

function ITEM:GetName()
	if (self:GetData("poisoned")) then
		return "Poisoned " .. self.name
	end

	return self.name
end
