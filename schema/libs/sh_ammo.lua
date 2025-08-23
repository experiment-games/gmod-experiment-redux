Schema.ammo = ix.util.GetOrCreateLibrary("ammo", {
  ammoCalibre = {},
  lookupCalibre = {},
})

function Schema.ammo.RegisterCalibre(ammo, calibre, calibreName)
  local ammoName = (isstring(ammo) and ammo or ammo.name):lower()
  Schema.ammo.ammoCalibre[ammoName] = {
    calibre = calibre,
    name = calibreName,
    ammo = istable(ammo) and ammo or nil,
  }
  Schema.ammo.lookupCalibre[calibre] = ammoName
end

local function createCustomAmmoType(name)
  return {
    name = name,
    dmgtype = DMG_BULLET,
    force = 700,
    maxcarry = "sk_max_smg1",
    maxsplash = 8,
    minsplash = 4,
    flags = 0,
    npcdmg = "sk_npc_dmg_smg1",
    plydmg = "sk_plr_dmg_smg1",
    tracer = TRACER_LINE_AND_WHIZ,
  }
end

-- Since libs load before items, we must register all calibres here if we want to use them in items.
Schema.ammo.RegisterCalibre(createCustomAmmoType("5.7x28mm"), "5.7x28mm", "5.7x28mm Rounds")
Schema.ammo.RegisterCalibre(createCustomAmmoType("5.56x45mm"), "5.56x45mm", "5.56x45mm Rounds")
Schema.ammo.RegisterCalibre(createCustomAmmoType("7.62x39mm"), "7.62x39mm", "7.62x39mm Rounds")
Schema.ammo.RegisterCalibre(createCustomAmmoType("6x35mm"), "6x35mm", "6mm Whisper Rounds")
Schema.ammo.RegisterCalibre(createCustomAmmoType("7.62x51mm"), "7.62x51mm", "7.62x51mm Rounds")
Schema.ammo.RegisterCalibre(createCustomAmmoType(".223 Remington"), ".223 Remington", ".223 Remington Rounds")
Schema.ammo.RegisterCalibre(createCustomAmmoType(".308 Winchester"), ".308 Winchester", ".308 Winchester Rounds")
Schema.ammo.RegisterCalibre(createCustomAmmoType("12.7x99mm"), "12.7x99mm", ".50 BMG Rounds")

Schema.ammo.RegisterCalibre(createCustomAmmoType("beanbag"), "beanbag", "Beanbag Pellets")
Schema.ammo.RegisterCalibre("buckshot", "12 Gauge", "12 Gauge Shells")
Schema.ammo.RegisterCalibre(createCustomAmmoType("16 Gauge"), "16 Gauge", "16 Gauge Shells")
Schema.ammo.RegisterCalibre(createCustomAmmoType("23x75mmR"), "23x75mmR", "23x75mmR Shells")

Schema.ammo.RegisterCalibre("357", ".357", ".357 Rounds")
Schema.ammo.RegisterCalibre(createCustomAmmoType(".357 SIG"), ".357 SIG", ".357 SIG Rounds")
Schema.ammo.RegisterCalibre("pistol", "9x19mm", "9x19mm Rounds")
Schema.ammo.RegisterCalibre(createCustomAmmoType(".32 ACP"), ".32 ACP", ".32 ACP Rounds")
Schema.ammo.RegisterCalibre(createCustomAmmoType(".45 ACP"), ".45 ACP", ".45 ACP Rounds")
Schema.ammo.RegisterCalibre(createCustomAmmoType(".40 S&W"), ".40 S&W", ".40 S&W")

Schema.ammo.RegisterCalibre(createCustomAmmoType("4.6x30mm"), "4.6x30mm", "4.6x30mm Rounds")

function Schema.ammo.GetCalibreName(calibre)
  local ammo = Schema.ammo.lookupCalibre[calibre]

  if (not ammo) then
    error("Attempt to get name of invalid calibre '" .. calibre .. "'. Ammo not found!")
  end

  if (istable(ammo)) then
    ammo = ammo.name:lower()
  end

  local calibreData = Schema.ammo.ammoCalibre[ammo]

  if (not calibreData) then
    error("Attempt to get name of invalid calibre '" .. calibre .. "'.")
  end

  return calibreData.name
end

function Schema.ammo.GetAllCalibres()
  return table.GetKeys(Schema.ammo.lookupCalibre)
end

function Schema.ammo.ConvertToCalibreName(ammo)
  local calibre = Schema.ammo.ammoCalibre[ammo:lower()]

  if (not calibre) then
    error("Attempt to convert invalid ammo '" .. ammo .. "' to calibre.")
  end

  return calibre.name
end

function Schema.ammo.ConvertToAmmo(calibre)
  local ammo = Schema.ammo.lookupCalibre[calibre]

  if (not ammo) then
    error("Attempt to convert invalid calibre '" .. calibre .. "' to ammo.")
  end

  return ammo
end

-- Only call this in InitializedPlugins on custom ammo (because that must be registered in GM:Initialize)
function Schema.ammo.ForceWeaponCalibre(swepClass, calibre)
  local swep = weapons.GetStored(swepClass)
  local ammoName = Schema.ammo.lookupCalibre[calibre]

  if (not Schema.ammo.ammoCalibre[ammoName]) then
    error("Attempt to force invalid calibre '" ..
      calibre ..
      "' on weapon '" ..
      swepClass .. "'. You should add this type of ammo to the schema first (don't forget to also make an item!)")
  end

  local ammo = Schema.ammo.ammoCalibre[ammoName].ammo

  if (ammo and istable(ammo)) then
    game.AddAmmoType(ammo)
    ammoName = ammo.name
  end

  if (not swep) then
    error("Attempt to force calibre on invalid weapon '" .. swepClass .. "'.")
  end

  if (weapons.IsBasedOn(swepClass, "exp_tacrp_base")) then
    swep.Ammo = ammoName -- For our TacRP modification
  else
    swep.Primary.Ammo = ammoName
  end
end

--- Finds all ammo items that match the given ammo type.
--- @param ammo string|number The ammo type to search for.
--- @return table # A table of items that match the ammo type.
function Schema.ammo.FindAmmoItems(ammo)
  local items = {}

  if (isnumber(ammo)) then
    ammo = game.GetAmmoName(ammo)
  end

  for _, item in pairs(ix.item.list) do
    if (item.ammo and item.ammo:lower() == ammo:lower()) then
      table.insert(items, item)
    end
  end

  return items
end

--- Finds the main ammo item for the given ammo type.
--- @param ammo string|number The ammo type to search for.
--- @return table|nil # The item that matches the ammo type, or nil if not
function Schema.ammo.FindMainAmmoItem(ammo)
  local items = Schema.ammo.FindAmmoItems(ammo)

  if (#items == 0) then
    return nil
  end

  -- Find the first item that has the base base_ammo, since we also have stackable ammo items in some cases
  for _, item in ipairs(items) do
    if (item.base == "base_ammo") then
      return item
    end
  end

  return items[1] -- Fallback to the first item if no base_ammo found
end
