Schema.generator = ix.util.GetOrCreateLibrary("generator", {
  stored = {},
})

function Schema.generator.Register(name, power, health, produce, uniqueID, upgrades)
  Schema.generator.stored[uniqueID] = {
    upgrades = upgrades or {},
    produce = produce or 100,
    health = health or 100,
    uniqueID = uniqueID,
    power = power or 2,
    name = name,
  }
end

function Schema.generator.GetAll()
  return Schema.generator.stored
end

function Schema.generator.Get(name)
  if (Schema.generator.stored[name]) then
    return Schema.generator.stored[name]
  else
    local generator

    for k, v in pairs(Schema.generator.stored) do
      if (string.find(string.lower(v.name), string.lower(name))) then
        if (generator) then
          if (string.len(v.name) < string.len(generator.name)) then
            generator = v
          end
        else
          generator = v
        end
      end
    end

    return generator
  end
end

if (SERVER) then
  function Schema.generator.Spawn(generator, position, angles)
    local entity = ents.Create(generator.uniqueID)
    entity:SetPos(position)
    entity:SetAngles(angles)
    entity:Spawn()
    entity:Activate()

    return entity
  end
end
