local ITEM = ITEM

ITEM.calibre = "9x19mm"
ITEM.name = ITEM.calibre .. " Cartridge"
ITEM.ammo = Schema.ammo.ConvertToAmmo(ITEM.calibre)
ITEM.model = "models/experiment-redux/ammo/9mm.mdl"
ITEM.noBusiness = true
ITEM.ammoAmount = 1
ITEM.description = "A single 9x19mm cartridge"
ITEM.chanceToScavenge = Schema.RARITY_RARE

if (SERVER) then
	ix.util.AddResourceFile("models/experiment-redux/ammo/9mm.mdl")
	ix.util.AddResourceFile("materials/models/experiment-redux/ammo/9mm.vmt")
end
