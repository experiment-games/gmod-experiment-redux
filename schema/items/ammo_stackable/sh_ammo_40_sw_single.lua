local ITEM = ITEM

ITEM.calibre = ".40 S&W"
ITEM.name = ITEM.calibre .. " Cartridge"
ITEM.name = Schema.ammo.GetCalibreName(ITEM.calibre)
ITEM.ammo = Schema.ammo.ConvertToAmmo(ITEM.calibre)
ITEM.model = "models/experiment-redux/ammo/45acp.mdl"
ITEM.noBusiness = true
ITEM.ammoAmount = 1
ITEM.description = "A single .40 S&W cartridge"
ITEM.chanceToScavenge = Schema.RARITY_UNCOMMON

if (SERVER) then
	ix.util.AddResourceFile("models/experiment-redux/ammo/45acp.mdl")
	ix.util.AddResourceFile("materials/models/experiment-redux/ammo/45acp.vmt")
end

function ITEM:GetName()
	if (self:GetData("poisoned")) then
		return "Poisoned " .. self.name
	end

	return self.name
end
