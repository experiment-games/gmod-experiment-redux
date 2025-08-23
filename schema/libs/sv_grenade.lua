Schema.grenade = ix.util.GetOrCreateLibrary("grenade")

function Schema.grenade.SpawnFlash(position)
  Schema.MakeExplosion(position, 16)

  for _, otherClient in ipairs(player.GetAll()) do
    if (otherClient:GetPos():Distance(position) > 192) then
      continue
    end

    if (not Schema.CanSeePosition(otherClient, position, 0.9, true)) then
      continue
    end

    if (hook.Run("FlashbangExploded", otherClient, position) ~= nil) then
      continue
    end

    net.Start("expFlashed")
    net.Send(otherClient)
  end
end

function Schema.grenade.SpawnSmoke(position, scale)
  local effectData = EffectData()

  effectData:SetOrigin(position)
  effectData:SetScale(scale or 2)

  util.Effect("exp_effect_smoke", effectData, true, true)
end

function Schema.grenade.SpawnTearGas(position, grenadeEntityIndex)
  local effectData = EffectData()

  effectData:SetStart(position)
  effectData:SetOrigin(position)
  effectData:SetScale(16)

  util.Effect("Explosion", effectData, true, true)

  hook.Run("TearGasExploded", position)

  timer.Create("Tear Gas: " .. grenadeEntityIndex, 1, 30, function()
    local curTime = CurTime()

    for _, otherClient in ipairs(ents.FindInSphere(position, 512)) do
      if (not otherClient:IsPlayer()) then
        continue
      end

      local character = otherClient:GetCharacter()

      if (not character) then
        continue
      end

      if (not Schema.CanSeePosition(otherClient, position, 0.9, true)) then
        continue
      end

      local hasTearGasProtection = Schema.armor.ProtectedFromTearGas(character)

      if (hasTearGasProtection) then
        continue
      end

      if (not otherClient.nextTearGas or curTime >= otherClient.nextTearGas) then
        otherClient.nextTearGas = curTime + 30

        net.Start("expTearGassed")
        net.Send(otherClient)
      end
    end
  end)
end

function Schema.grenade.CreateGrenadeEntity(client, power)
  local position = client:GetShootPos() + (client:GetAimVector() * 64)
  local entity = ents.Create("prop_physics")
  local trace = client:GetEyeTraceNoCursor()

  if (trace.HitPos:Distance(client:GetShootPos()) <= 80) then
    position = trace.HitPos - (client:GetAimVector() * 16)
  end

  entity:SetModel("models/items/grenadeammo.mdl")
  entity:SetPos(position)
  entity:Spawn()

  if (not IsValid(entity)) then
    return
  end

  if (IsValid(entity:GetPhysicsObject())) then
    entity:GetPhysicsObject():ApplyForceCenter(client:GetAimVector() * (800 + power))
    entity:GetPhysicsObject():AddAngleVelocity(Vector(600, math.random(-1200, 1200), 0))
  end

  local grenadeTrailsEnabled = ix.config.Get("grenadeTrailsEnabled")

  if (grenadeTrailsEnabled) then
    local grenadeTrailColor = ix.config.Get("grenadeTrailColor")
    local grenadeTrailMaxLifetime = ix.config.Get("grenadeTrailMaxLifetime")

    local trail = util.SpriteTrail(entity, entity:LookupAttachment("fuse"), grenadeTrailColor, true, 8, 1, 1,
      (1 / 9) * 0.5, "sprites/bluelaser1.vmt")

    if (grenadeTrailMaxLifetime > -1) then
      local fadeOutTime = grenadeTrailMaxLifetime * .25
      local fadeOutAfter = grenadeTrailMaxLifetime - fadeOutTime

      timer.Simple(fadeOutAfter, function()
        if (not IsValid(trail)) then
          return
        end

        local fadeSteps = 10
        local fadeStepDuration = fadeOutTime / fadeSteps
        local startAlpha = trail:GetColor().a
        local timerName = "GrenadeTrailFadeOut: " .. entity:EntIndex()

        timer.Create(timerName, fadeStepDuration, fadeSteps, function()
          if (not IsValid(trail)) then
            return
          end

          local alpha = Lerp(1 - (timer.RepsLeft(timerName) / fadeSteps), startAlpha, 0)
          trail:Fire("Alpha", alpha * 255, 0)

          if (alpha == 0) then
            trail:Remove()
          end
        end)
      end)
    end

    if (IsValid(trail)) then
      entity:DeleteOnRemove(trail)
    end
  end

  return entity
end

function Schema.grenade.HandleRemoveItem(client, weapon)
  local character = client:GetCharacter()

  if (not character) then
    return
  end

  local inventory = character:GetInventory()

  if (not weapon.ixItem) then
    return
  end

  weapon.ixItem:RemovePAC(client)
  inventory:Remove(weapon.ixItem.id)
  client.carryWeapons[weapon.ixItem.weaponCategory] = nil
end
