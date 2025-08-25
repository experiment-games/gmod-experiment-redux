local ITEM = ITEM

ITEM.calibre = "7.62x39mm"
ITEM.name = ITEM.calibre .. " Cartridge"
ITEM.ammo = Schema.ammo.ConvertToAmmo(ITEM.calibre)
ITEM.model = "models/experiment-redux/ammo/7_62x39.mdl"
ITEM.noBusiness = true
ITEM.ammoAmount = 1
ITEM.description = "A single 7.62x39mm cartridge"
ITEM.chanceToScavenge = Schema.RARITY_RARE

if (SERVER) then
	ix.util.AddResourceFile("models/experiment-redux/ammo/7_62x39.mdl")
	ix.util.AddResourceFile("materials/models/experiment-redux/ammo/7_62x39.vmt")
end
