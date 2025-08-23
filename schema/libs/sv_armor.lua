Schema.armor = ix.util.GetOrCreateLibrary("armor")

function Schema.armor.FindArmor(character, itemId)
  local allArmor = character:GetData("armor", {})

  for i = 1, #allArmor do
    if (allArmor[i] == itemId) then
      return allArmor[i], i
    end
  end

  return nil
end

function Schema.armor.SetArmor(character, itemId)
  local allArmor = character:GetData("armor", {})
  local existingArmor = Schema.armor.FindArmor(character, itemId)

  if (existingArmor) then
    -- Will happen on respawn
    return
  end

  allArmor[#allArmor + 1] = itemId

  character:SetData("armor", allArmor)

  Schema.armor.RefreshNetworkArmor(character)
end

function Schema.armor.RemoveArmor(character, itemId)
  local allArmor = character:GetData("armor", {})
  local existingArmor, index = Schema.armor.FindArmor(character, itemId)

  if (not existingArmor) then
    ErrorNoHalt("[Experiment] Attempt to remove an armor item that doesn't exist on the character!\n")
    return
  end

  table.remove(allArmor, index)

  character:SetData("armor", allArmor)

  Schema.armor.RefreshNetworkArmor(character)
end

function Schema.armor.RefreshNetworkArmor(character)
  local client = character:GetPlayer()
  local allArmor = character:GetData("armor", {})
  local armorUniqueIDs = {}

  for _, itemId in ipairs(allArmor) do
    local item = ix.item.instances[itemId]

    if (item) then
      armorUniqueIDs[#armorUniqueIDs + 1] = item.uniqueID
    end
  end

  client:SetCharacterNetVar("armorItems", armorUniqueIDs)
end

function Schema.armor.GetTotalArmor(character)
  local allArmor = character:GetData("armor", {})
  local armor = 0

  for _, itemId in ipairs(allArmor) do
    local item = ix.item.instances[itemId]

    if (item) then
      armor = armor + item:GetData("armor", 0)
    end
  end

  return armor
end

-- Damages the armor items on the character, returns the remaining damage.
function Schema.armor.DamageAfterArmor(character, damage)
  local allArmor = character:GetData("armor", {})
  local effectiveness = ix.config.Get("armorEffectiveness")
  local preventableDamage = damage * effectiveness
  local remaining = preventableDamage
  local totalArmor = 0

  for _, itemId in ipairs(allArmor) do
    local item = ix.item.instances[itemId]

    if (not item) then
      continue
    end

    -- If an item has no armor, then it can't prevent damage.
    -- This can be used for items that only provide hasTearGasProtection.
    if (item.noArmor) then
      continue
    end

    local armor = item:GetData("armor", 0)

    if (armor > 0) then
      local newArmor = math.max(armor - remaining, 0)
      remaining = math.max(remaining - armor, 0)
      armor = newArmor

      totalArmor = totalArmor + newArmor

      item:SetData("armor", newArmor)
    end

    if (armor == 0) then
      if (item.removeOnDestroy) then
        Schema.armor.RemoveArmor(character, itemId)
        character:GetInventory():Remove(itemId)
        character.player:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav")
      end
    end

    if (remaining == 0) then
      break
    end
  end

  return damage - (preventableDamage - remaining)
end

function Schema.armor.ProtectedFromTearGas(character)
  local allArmor = character:GetData("armor", {})

  for _, itemId in ipairs(allArmor) do
    local item = ix.item.instances[itemId]

    if (item and item.hasTearGasProtection) then
      return true
    end
  end

  return false
end
