--[[

	Organization, loading, saving and tick hooks

--]]

function Schema:GetGameDescription()
	return Schema.name
end

function Schema:PlayerSpray(client)
	-- Prevent player spraying their spray
	return true
end

function Schema:PrePlayerLoadedCharacter(client, curChar, prevChar)
	client.expLastCharacterLoadedAt = CurTime()

	if (prevChar) then
		local informers = prevChar:GetVar("boltInformers") or {}
		local inventory = prevChar:GetInventory()

		for _, v in ipairs(informers) do
			if (IsValid(v)) then
				v:Remove()
			end
		end

		prevChar:SetVar("boltInformers", nil)
	end
end

function Schema:CharacterLoaded(character)
	local client = character:GetPlayer()

	Schema.perk.LoadOwned(client, character)
	Schema.buff.LoadActive(client, character)
	Schema.achievement.LoadProgress(client, character)
	Schema.armor.RefreshNetworkArmor(character)
	Schema.progression.NetworkAll(client)

	if (character.isBot) then
		-- ! Workaround. This fixes a Helix bug with bots getting a random model from the faction,
		-- ! but not having their OnAdjust called on their character vars.
		-- ! In OnAdjust skins and bodygroups are extracted from the model and applied to the player.
		local payload = character.vars

		payload.description = "A test subject, living in this city."
		payload.faction = ix.faction.GetIndex(payload.faction)

		local faction = ix.faction.indices[payload.faction]

		payload.model = math.random(#faction:GetModels(client))

		local newPayload = {}

		for varName, var in SortedPairsByMemberValue(ix.char.vars, "index") do
			local value = payload[varName]

			if (var.OnAdjust) then
				var:OnAdjust(client, payload, value, newPayload)
			end
		end

		table.Merge(payload, newPayload, true)
	end
end

function Schema:PlayerSecondElapsed(client)
	local character = client:GetCharacter()

	if (not character) then
		return
	end

	client:CheckQueuedBoostRemovals(character)
	Schema.buff.CheckExpired(client)

	local ragdoll = client:GetLocalVar("ragdoll")
	local ragdollEntity = ragdoll and Entity(ragdoll) or nil

	if (IsValid(ragdollEntity)) then
		-- We can't rely on velocity, because spazzing ragdolls can have a high velocity whilst not moving much.
		-- local velocity = ragdollEntity:GetVelocity()
		local previousPosition = ragdollEntity.expPreviousPosition or ragdollEntity:GetPos()
		local position = ragdollEntity:GetPos()
		local downwardChange = position.z - previousPosition.z

		ragdollEntity.expLastDownwardChange = downwardChange
		ragdollEntity.expPreviousPosition = position
	end
end

function Schema:CharacterPreSave(character)
	Schema.buff.PrepareSaveActive(character:GetPlayer(), character)
end

function Schema:PlayerDisconnected(client)
	local character = client:GetCharacter()

	if (character) then
		local doors = character:GetVar("doors") or {}

		for _, v in ipairs(doors) do
			if (IsValid(v) and v:IsDoor() and v:GetDTEntity(0) == client) then
				v:RemoveDoorAccessData()
			end
		end

		character:SetVar("doors", nil)
	end

	if (client:SteamID() == nil or client:SteamID64() == nil) then
		--[[
		From the wiki:
		"
			NEED TO VALIDATE
			Player:SteamID, Player:SteamID64, and the like can return nil here.
		"
		https://wiki.facepunch.com/gmod/GM:PlayerDisconnected

		Let's return the favor and validate whether nil is ever returned.
		--]]
		local playerData = {
			time = os.time(),
			version = VERSION,
			versionStr = VERSIONSTR,
			jitVersion = jit.version,
			jitVersionNum = jit.version_num,
			steamID = tostring(client:SteamID()),
			steamID64 = tostring(client:SteamID64()),
			Name = tostring(client:Name()),
		}
		ix.util.SchemaErrorNoHaltWithStack(
			"Player disconnected (wiki bug/issue validation): "
			.. util.TableToJSON(playerData) .. "\n"
		)
		file.Write("disconnect_validation.txt", util.TableToJSON(playerData) .. "\n")
	end
end

function Schema:CharacterVarChanged(character, key, oldValue, value)
	if (key ~= "money") then
		return
	end

	local requiredMoney = Schema.achievement.GetProperty("northern_rock", "requiredMoney")

	if (value > requiredMoney) then
		Schema.achievement.Progress("northern_rock", character:GetPlayer())
	end
end

function Schema:CharacterAttributeUpdated(client, character, attributeKey, value)
	local attribute = ix.attributes.list[attributeKey]

	if (attribute and attribute.OnSetup) then
		-- client:GetCharacter() might be nil if the character is being created. For that reason we pass the character object.
		attribute:OnSetup(client, character:GetAttribute(attributeKey, value), character)
	end

	if (attributeKey == "strength") then
		local requiredAttribute = Schema.achievement.GetProperty("titans_strength", "requiredAttribute")

		if (value >= requiredAttribute) then
			Schema.achievement.Progress("titans_strength", client)
		end
	elseif (attributeKey == "dexterity") then
		local requiredAttribute = Schema.achievement.GetProperty("dextrous_rogue", "requiredAttribute")

		if (value >= requiredAttribute) then
			Schema.achievement.Progress("dextrous_rogue", client)
		end
	elseif (attributeKey == "acrobatics") then
		local requiredAttribute = Schema.achievement.GetProperty("natural_acrobat", "requiredAttribute")

		if (value >= requiredAttribute) then
			Schema.achievement.Progress("natural_acrobat", client)
		end
	elseif (attributeKey == "agility") then
		local requiredAttribute = Schema.achievement.GetProperty("agile_shadow", "requiredAttribute")

		if (value >= requiredAttribute) then
			Schema.achievement.Progress("agile_shadow", client)
		end
	end
end

function Schema:GetSalaryAmount(client, faction)
	local salary = faction.pay

	if (ix.config.Get("incomeMultiplier") ~= 1) then
		salary = salary * ix.config.Get("incomeMultiplier")
	end

	return salary
end

--[[

	Sandbox hooks (context/spawnmenu, spawning props, etc.)

--]]

function Schema:OnPhysgunFreeze(weapon, physObj, entity, client)
	if (not IsValid(physObj)) then
		return false
	end
end

--[[

	Spawning and Loadout hooks

--]]

function Schema:PlayerInitialSpawn(client)
	Schema.CleanupCorpses()
end

function Schema:PlayerSpawn(client)
	client:SetLocalVar("ragdoll", nil)

	-- Disable zooming
	client:SetCanZoom(false)

	-- Reset these so they don't interfere the next time the player dies
	client.expCorpseCharacter = nil
	client.expDropMode = nil
end

function Schema:PostPlayerLoadout(client)
	local character = client:GetCharacter()

	if (not character) then
		return
	end

	-- Make sure they're not still tied up (or tying or being tied) from a previous session.
	client:SetRestricted(false)
	client:SetNetVar("tied")
	client:SetNetVar("tying")
	client:SetNetVar("beingTied")
	client:SetNetVar("beingUntied")
	client.expRunSpeedBeforeTied = nil
	Schema.SetPlayerTiedBones(client, false)

	client:SetNetVar("chloroforming")
	client:SetNetVar("beingChloroformed")
end

--[[

	Damage hooks

--]]

function Schema:GetPlayerPunchDamage(client, damage, context)
	if (not client:GetCharacter()) then
		return
	end

	context.damage = context.damage
		+ (client:GetCharacter():GetAttribute("strength", 0) * ix.config.Get("strengthMultiplier"))
end

function Schema:EntityTakeDamage(entity, damageInfo)
	local inflictor = damageInfo:GetInflictor()
	local isRagdoll = entity:GetClass() == "prop_ragdoll"

	if (inflictor) then
		local inflictorClass = inflictor:GetClass()

		if (inflictorClass == "ix_item"
				or inflictorClass == "ix_money"
				or inflictorClass == "ix_shipment"
				or inflictorClass == "ix_container") then
			damageInfo:SetDamage(0)
			return
		end

		-- If it's a ragdoll and it's being damaged by worldspawn, then it's probably getting crushed.
		if (isRagdoll and inflictor == game.GetWorld()) then
			local lastDownwardChange = entity.expLastDownwardChange or 0

			-- If they actually fell from a height, then we'll let them take damage.
			if (lastDownwardChange > -300) then
				damageInfo:SetDamage(0)
				return
			end
		end

		-- If the inflictor is held by a player, then they may be trying to hurt someone with it.
		if (inflictor.ixHeldOwner) then
			damageInfo:SetDamage(0)
			return
		end

		-- If the inflictor is a prop_physics, then someone may be trying to prop kill.
		if (inflictorClass == "prop_physics" and not inflictor.expIsSafeProjectile) then
			damageInfo:SetDamage(0)
			return
		end
	end

	-- Ragdolls are prone to taking damage a lot of times when spazzing, so we'll prevent them from taking damage too often.
	if (isRagdoll and entity.expLastDamage and entity.expLastDamage + 0.5 > CurTime()) then
		damageInfo:SetDamage(0)
		return
	end

	entity.expLastDamage = CurTime()

	if (not entity:IsPlayer()) then
		return
	end

	local character = entity:GetCharacter()

	if (not character) then
		return
	end

	if (damageInfo:IsDamageType(Schema.armorAffectedTypes)) then
		local damage = damageInfo:GetDamage()
		damage = Schema.armor.DamageAfterArmor(character, damage)

		damageInfo:SetDamage(damage)
	end
end

function Schema:PostEntityTakeDamage(entity, damageInfo, tookDamage)
	if (not entity:IsPlayer()) then
		return
	end

	-- Disable default viewpunch
	entity:SetViewPunchAngles(Angle(0, 0, 0))

	if (hook.Run("PlayerShouldViewPunch", entity, damageInfo) == false) then
		return
	end

	local force = damageInfo:GetDamageForce()
	local damage = damageInfo:GetDamage()

	force.z = math.max(force.z, damage) * 0.05
	force.y = math.max(force.z, damage) * 0.5
	force.x = math.max(force.z, damage) * 0.5

	-- Maximum knockback values (before it gets ridiculous):
	-- p (0 - 50)
	-- y (-45 - 45)
	-- r (-10 - 10)
	local pitch = math.Clamp(math.random(force.z * .7, force.z), 0, 50)
	local yaw = math.Clamp(math.random(-force.y * .5, force.y * .5), -45, 45)
	local roll = math.Clamp(math.random(-force.x * .1, force.x * .1), -10, 10)

	entity:ViewPunch(Angle(pitch, yaw, roll))
end

function Schema:PlayerShouldViewPunch(client, damageInfo)
	if (Schema.perk.GetOwned("concentration", client)) then
		local pitch = math.random(0, 4)
		local yaw = math.random(-2, 2)
		local roll = math.random(-1, 1)

		-- SetViewPunchAngles will reset instead of adding to the current view punch, so we need to get the current view punch.
		client:SetViewPunchAngles(Angle(pitch, yaw, roll))

		return false
	end
end

function Schema:PlayerHurt(client, attacker, health, damage)
	if ((client.ixNextPain or 0) < CurTime() and health > 0) then
		local painSound, delay = hook.Run("GetPlayerPainSound", client)

		if (painSound) then
			if (not client:IsBot() and client:IsFemale() and ! painSound:find("female")) then
				painSound = painSound:gsub("male", "female")
			end

			client:EmitSound(painSound)
			client.ixNextPain = CurTime() + (delay or 0.4)
		end
	end

	ix.log.Add(client, "playerHurt", damage, attacker:GetName() ~= "" and attacker:GetName() or attacker:GetClass())

	-- We override this function to prevent the default damage sound handling
	return true
end

function Schema:GetPlayerPainSound(client)
	if (Schema.perk.GetOwned("hit_in_the_gut", client) and math.random() <= 0.5) then
		local delay = 2
		return "vo/npc/male01/hitingut0" .. math.random(1, 2) .. ".wav", delay
	end

	local hitGroup = client.expLastBulletDamageHitGroup

	if (hitGroup and math.random() <= 0.4) then
		local delay = 2
		if (hitGroup == HITGROUP_HEAD) then
			return "vo/npc/male01/ow0" .. math.random(1, 2) .. ".wav", delay
		elseif (hitGroup == HITGROUP_CHEST or hitGroup == HITGROUP_GENERIC) then
			return "vo/npc/male01/hitingut0" .. math.random(1, 2) .. ".wav", delay
		elseif (hitGroup == HITGROUP_LEFTLEG or hitGroup == HITGROUP_RIGHTLEG) then
			return "vo/npc/male01/myleg0" .. math.random(1, 2) .. ".wav", delay
		elseif (hitGroup == HITGROUP_LEFTARM or hitGroup == HITGROUP_RIGHTARM) then
			return "vo/npc/male01/myarm0" .. math.random(1, 2) .. ".wav", delay
		elseif (hitGroup == HITGROUP_GEAR) then
			return "vo/npc/male01/startle0" .. math.random(1, 2) .. ".wav", delay
		end
	end

	return "vo/npc/male01/pain0" .. math.random(1, 9) .. ".wav"
end

local function handleBeanbagWeaponDamage(client, attacker, damageInfo)
	local weapon = attacker:GetActiveWeapon()

	if (not IsValid(weapon)) then
		return
	end

	local ammo = game.GetAmmoName(weapon:GetPrimaryAmmoType())

	if (not ammo or ammo:lower() ~= Schema.ammo.ConvertToAmmo("beanbag")) then
		return
	end

	-- Do a bit of damage if they're already ragdolled and override to not proceed with the regular damage.
	if (client:GetLocalVar("ragdoll")) then
		damageInfo:SetDamage(5)
		return true
	end

	local luck = 0.9

	if (Schema.perk.GetOwned("thick_skin", client)) then
		luck = luck * Schema.perk.GetProperty("thick_skin", "chance")
	end

	local gotLucky = math.random() < luck
	local position = damageInfo:GetDamagePosition()

	Schema.ImpactEffect(position, 8, true)

	if (gotLucky) then
		damageInfo:SetDamage(25)
	else
		damageInfo:SetDamage(5)

		local duration = ix.config.Get("beanbagRagdollDuration")

		client:SetRagdolled(true, duration)

		hook.Run("PlayerBeanbagged", client, attacker, duration, damageInfo)
	end

	-- Override, do not proceed with regular damage, because the beanbag doesnt hurt more.
	return true
end

-- Note: This is called only for bullet damage a player receives, you should use GM:EntityTakeDamage instead if you need to detect ALL damage.
function Schema:ScalePlayerDamage(client, hitGroup, damageInfo)
	local character = client:GetCharacter()

	if (not character) then
		return
	end

	client.expLastBulletDamageHitGroup = hitGroup

	local attacker = damageInfo:GetAttacker()

	if (IsValid(attacker) and attacker:IsPlayer()) then
		if (handleBeanbagWeaponDamage(client, attacker, damageInfo) == true) then
			return
		end
	end

	-- Adjust head damage based on perks and items.
	if (hitGroup == HITGROUP_HEAD) then
		if (Schema.perk.GetOwned("headplate", client)) then
			local chance = Schema.perk.GetProperty("headplate", "chance")

			if (math.random() < chance) then
				damageInfo:ScaleDamage(0)
				return
			end
		end

		if (IsValid(attacker) and attacker:IsPlayer()) then
			local weapon = attacker:GetActiveWeapon()
			local weaponIsSilenced = IsValid(weapon) and weapon.ixItem and weapon.ixItem.isSilenced
			local attackerIsStealthed = attacker:HasStealthActivated()
			local hasAssassinsCreedPerk = Schema.perk.GetOwned("assassins_creed", attacker)

			if (weaponIsSilenced and attackerIsStealthed and hasAssassinsCreedPerk) then
				local chance = Schema.perk.GetProperty("assassins_creed", "chance")

				if (math.random() < chance) then
					local bonusDamage = Schema.perk.GetProperty("assassins_creed", "bonusDamage")

					damageInfo:ScaleDamage(bonusDamage)
				end
			end
		end

		local helmetItemId = character:GetData("helmet")
		if (helmetItemId ~= nil) then
			local item = ix.item.instances[helmetItemId]

			if (not item) then
				ix.log.Add(client, "schemaDebug", "Schema:ScalePlayerDamage",
					"Attempt to get invalid helmet item instance: " ..
					tostring(helmetItemId))
				return
			end

			damageInfo:ScaleDamage(item.damageScale)
			character:SetData("helmet", nil)
			item:Remove()
			client:EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 7) .. ".wav")
		end
	end

	-- Adjust melee damage based on perks and items.
	-- TODO: Check if ScalePlayerDamage is called for this type of melee damage
	if (damageInfo:IsDamageType(DMG_CLUB) or damageInfo:IsDamageType(DMG_SLASH)) then
		if (Schema.perk.GetOwned("blunt_defense", client)) then
			local damageScale = Schema.perk.GetProperty("blunt_defense", "damageScale")
			damageInfo:ScaleDamage(damageScale)
		end
	end

	-- Adjust fall damage based on perks and items.
	if (damageInfo:IsFallDamage()) then
		if (Schema.perk.GetOwned("leg_braces", client)) then
			local damageScale = Schema.perk.GetProperty("leg_braces", "damageScale")
			damageInfo:ScaleDamage(damageScale)
		end
	end
end

function Schema:PlayerDestroyGenerator(client, entity, generator, item)
	local destroyReward = 0
	local upgrades = entity:GetUpgrades()

	for i = 1, upgrades do
		local upgrade = generator.upgrades[i]
		destroyReward = destroyReward + upgrade.price
	end

	if (destroyReward == 0) then
		-- No upgrades, no money
		return
	end

	if (Schema.perk.GetOwned("payback", client)) then
		destroyReward = destroyReward * .5

		client:GetCharacter():GiveMoney(destroyReward)
	end

	client:GetCharacter():GiveMoney(math.ceil(destroyReward * .75))
end

--[[

	Healing hooks

--]]

function Schema:AdjustHealAmount(client, amount)
end

function Schema:PlayerHealed(client, target, item, healAmount)
	ix.log.Add(client, "playerHealed", target:Name(), healAmount)

	local buff, buffTable = Schema.buff.GetActive(client, "waning_ward")

	if (not buff) then
		Schema.buff.SetActive(client, "waning_ward")
		return
	end

	buffTable:Stack(client, buff)
end

--[[

	Death hooks

--]]

function Schema:ShouldSpawnClientRagdoll(client)
	return false
end

function Schema:ShouldRemoveRagdollOnDeath(client)
	return false
end

function Schema:OnPlayerCorpseCreated(client, entity)
	if (not ix.config.Get("dropItemsOnDeath", false) or not client:GetCharacter()) then
		return
	end

	local character = client.expCorpseCharacter or client:GetCharacter()
	local characterInventory = character:GetInventory()
	local width, height = characterInventory:GetSize()

	local corpseInventoryType = "player:corpse:" .. width .. "x" .. height
	ix.inventory.Register(corpseInventoryType, width, height)

	ix.inventory.New(0, corpseInventoryType, function(inventory)
		inventory.vars.isCorpse = true

		if (not IsValid(entity)) then
			local query = mysql:Delete("ix_inventories")
			query:Where("inventory_id", inventory:GetID())
			query:Execute()
			return
		end

		entity.ixInventory = inventory

		entity.StartSearchCorpse = function(corpse, client)
			if (not IsValid(client)) then
				return
			end

			if (not corpse.ixInventory or ix.storage.InUse(corpse.ixInventory)) then
				return
			end

			local ownerName = CLIENT and L "someone" or L("someone", client)

			if (character) then
				local ourCharacter = client:GetCharacter()

				if (ourCharacter and character and ourCharacter:DoesRecognize(character)) then
					ownerName = character:GetName()
				end
			end

			local name = L("corpseOwnerName", client, ownerName)
			local baseTaskTime = ix.config.Get("corpseSearchTime", 1)
			local searchTime = Schema.GetDexterityTime(client, baseTaskTime)

			ix.storage.Open(client, entity.ixInventory, {
				entity = entity,
				name = name,
				searchText = "@searchingCorpse",
				searchTime = searchTime
			})
		end

		-- Used to satisfy the saving for belongings
		entity.GetOwnerID = function(corpse)
			return character:GetID()
		end

		entity.GetInventory = function(corpse)
			return corpse.ixInventory
		end

		entity.SetMoney = function(corpse, amount)
			hook.Run("OnCorpseMoneyChanged", corpse, amount, corpse.ixMoney)
			corpse.ixMoney = amount
		end

		entity.GetMoney = function(corpse)
			return corpse.ixMoney or 0
		end

		hook.Run("OnPlayerCorpseFillInventory", client, inventory, entity)
	end)
end

function Schema:OnPlayerCorpseFillInventory(client, corpseInventory, entity)
	local character = client.expCorpseCharacter or client:GetCharacter()
	local dropMode = client.expDropMode or bit.bor(Schema.dropMode.RANDOM, Schema.dropMode.WITH_EQUIPPED_WEAPONS)
	local characterInventory = character:GetInventory()
	local money = character:GetMoney()

	local hasConfusingPockets, confusingPocketsPerkTable = Schema.perk.GetOwned("confusing_pockets", client)
	local dropEquippedArmor = bit.band(dropMode, Schema.dropMode.WITH_EQUIPPED_ARMOR) ==
		Schema.dropMode.WITH_EQUIPPED_ARMOR
	local dropEquippedWeapons = bit.band(dropMode, Schema.dropMode.WITH_EQUIPPED_WEAPONS) ==
		Schema.dropMode.WITH_EQUIPPED_WEAPONS
	local dropModeIsRandom = bit.band(dropMode, Schema.dropMode.RANDOM) == Schema.dropMode.RANDOM

	for _, slot in pairs(characterInventory.slots) do
		for _, item in pairs(slot) do
			if (item.noDrop) then
				continue
			end

			if (item:GetData("equip")) then
				if (item.isWeapon and not dropEquippedWeapons) then
					continue
				elseif (item:IsBasedOn("base_outfit") and not dropEquippedArmor) then
					continue
				end
			end

			local shouldDropItem = false
			local shouldOverrideDropItem = hook.Run("ShouldPlayerDeathDropItem", client, item, dropModeIsRandom)

			if (shouldOverrideDropItem ~= nil) then
				shouldDropItem = shouldOverrideDropItem
			elseif (dropModeIsRandom) then
				local loseItemChance = 0.75

				if (hasConfusingPockets) then
					loseItemChance = loseItemChance * confusingPocketsPerkTable.modifyLoseChance
				end

				shouldDropItem = (math.random() > loseItemChance)
			else
				shouldDropItem = true
			end

			if (shouldDropItem) then
				if (item.hooks["drop"]) then
					item.player = client
					item.hooks["drop"](item)
					item.player = nil
				end

				item:Transfer(corpseInventory:GetID(), item.gridX, item.gridY, nil, false, true)
			end
		end
	end

	if (money > 0) then
		local amountToLose = money

		if (dropModeIsRandom) then
			local fractionToLose = 0.75

			if (hasConfusingPockets) then
				fractionToLose = fractionToLose * confusingPocketsPerkTable.modifyLoseChance
			end

			amountToLose = math.floor(math.random(1, money * fractionToLose))
		end

		character:TakeMoney(amountToLose)

		if (not entity.SetMoney) then
			error("Attempt to set money on an entity that doesn't support it: " .. tostring(entity))
		end

		entity:SetMoney(amountToLose)

		if (character:GetMoney() == 0) then
			Schema.achievement.Progress("boltless_wanderer", client)
		end
	end

	-- character:Save()
end

function Schema:DoPlayerDeath(client, attacker, damageinfo)
	Schema.HandlePlayerDeathCorpse(client)
end

function Schema:PlayerDeath(client, inflictor, attacker)
	local character = client:GetCharacter()

	if (not character) then
		return
	end

	Schema.achievement.Progress("favored_target", client)

	-- Store this vector so we can use it to determine if the player can spawn at a spawn point.
	character:SetData("lastDeathPosition", client:GetPos())
	character:SetData("lastDeathTime", os.time())
end

--[[

	Interaction hooks

--]]

function Schema:OnAchievementAchieved(client, achievementTable)
	ix.log.Add(client, "achievementAchieved", achievementTable.name, achievementTable.reward)
end

function Schema:PlayerUse(client, entity)

end

function Schema:PlayerInteractEntity(client, entity, option, data)
	if (entity:GetClass() ~= "prop_ragdoll") then
		return
	end

	local entityPlayer = entity:GetNetVar("player", NULL)

	if (not IsValid(entityPlayer)) then
		return
	end

	entity.OnOptionSelected = function(entity, client, option, data)
		if (client:IsRestricted() or not client:Alive() or not client:GetCharacter()) then
			return
		end

		hook.Run("OnPlayerRagdollOptionSelected", client, entityPlayer, entity, option, data)
	end
end

function Schema:OnPlayerOptionSelected(target, client, option, data)
	if (option == L("untie", client)) then
		if (not client:IsRestricted() and target:IsPlayer() and target:IsRestricted() and not target:GetNetVar("beingUntied")) then
			Schema.PlayerTryUntieTarget(client, target)
		end
	end
end

function Schema:OnPlayerRagdollOptionSelected(client, target, ragdoll, option, data)
	if (client:IsRestricted() or not client:Alive() or not client:GetCharacter()) then
		return
	end

	local corpseOwnerID = ragdoll:GetNetVar("corpseOwnerID")

	if (not corpseOwnerID) then
		if (target:Alive() and target:IsRestricted() and not target:GetNetVar("beingUntied")) then
			if (option == L("untie", client)) then
				Schema.PlayerTryUntieTarget(client, ragdoll)
			elseif (option == L("searchTied", client)) then
				Schema.SearchPlayer(client, target)
			end
		end

		return
	end

	if (option == L("searchCorpse", client) and ragdoll.StartSearchCorpse) then
		ragdoll:StartSearchCorpse(client)
		return
	end

	if (option == L("mutilateCorpse", client)) then
		local hasMutilatorPerk, mutilatorPerkTable = Schema.perk.GetOwned("mutilator", client)

		if (not hasMutilatorPerk) then
			return
		end

		if (hook.Run("CanPlayerMutilate", client, target, ragdoll) == false) then
			return
		end

		if (ragdoll:GetNetVar("mutilated", 0) >= mutilatorPerkTable.maximumMutilations) then
			return
		end

		local baseTaskTime = mutilatorPerkTable.mutilateTime
		local mutilateTime = Schema.GetDexterityTime(client, baseTaskTime)
		local healthIncrease = mutilatorPerkTable.healthIncrease

		client:SetAction("@mutilatingCorpse", mutilateTime)
		client:DoStaredAction(ragdoll, function()
			-- Double check, so players cant mutilate the same corpse at once.
			if (ragdoll:GetNetVar("mutilated", 0) >= mutilatorPerkTable.maximumMutilations) then
				return
			end

			local trace = client:GetEyeTraceNoCursor()

			Schema.BloodEffect(ragdoll, ragdoll:NearestPoint(trace.HitPos))
			client:EmitSound("npc/barnacle/barnacle_crunch" .. math.random(2, 3) .. ".wav")

			client:SetHealth(math.min(client:Health() + healthIncrease, client:GetMaxHealth()))
			ragdoll:SetNetVar("mutilated", ragdoll:GetNetVar("mutilated", 0) + 1)
		end, mutilateTime, function()
			if (IsValid(client)) then
				client:SetAction()
			end
		end)

		return
	end
end

function Schema:PlayerPerkBought(client, perk)
	Schema.achievement.Progress("perk_purveyor", client)
end

function Schema:InventoryItemAdded(sourceInventory, targetInventory, item)
	-- If the item has base_stackable and we find existing base_stackable items in the target inventory
	-- Check if the existing item can stack with the new item, if so, stack them.
	if (not item:IsBasedOn("base_stackable")) then
		return
	end

	local client = targetInventory:GetOwner()

	if (not client) then
		return
	end

	if (client.expLastSplit and client.expLastSplit + 0.1 > CurTime()) then
		-- Don't stack items if the player just tried to split them.
		return
	end

	local tallestStackItem = nil
	local tallestStack = 0

	for _, otherItem in pairs(targetInventory:GetItems()) do
		if (otherItem:IsBasedOn("base_stackable") and otherItem:CanStackWith(item)) then
			local otherStacks = otherItem:GetData("stacks", 1)

			if (otherStacks > tallestStack) then
				tallestStack = otherStacks
				tallestStackItem = otherItem
			end
		end
	end

	if (tallestStackItem) then
		tallestStackItem:Stack(item)
		return
	end
end

function Schema:GeneratorAdjustEarnings(generator, earningsData)
	local client = generator:GetItemOwner()

	if (not IsValid(client)) then
		return
	end

	local hasThievingPerk, thievingPerkTable = Schema.perk.GetOwned("thieving", client)

	if (hasThievingPerk) then
		earningsData.earnings = earningsData.earnings * thievingPerkTable.generatorEarningsMultiplier
	end

	local hasMetalshipPerk, metalshipPerkTable = Schema.perk.GetOwned("metalship", client)

	if (hasMetalshipPerk) then
		earningsData.earnings = earningsData.earnings * metalshipPerkTable.generatorEarningsMultiplier
	end
end

-- Fix Nexus doors not opening when using them
function Schema:PlayerUseDoor(client, door)
	if (game.GetMap() ~= "rp_c18_v2" or door:GetClass() ~= "func_door") then
		return
	end

	if (door:IsLocked() or door:GetNetVar("disabled")) then
		return
	end

	if (client:IsRestricted()) then
		return
	end

	door:Fire("open")
end

function Schema:OnCorpseMoneyChanged(corpse, newAmount, oldAmount)
	if (oldAmount == nil) then
		-- When setting up the corpse inventory
		return
	end

	local requiredMoney = Schema.achievement.GetProperty("ransacked", "requiredMoney")
	local change = oldAmount - newAmount

	if (change < requiredMoney) then
		return
	end

	local client = corpse:GetNetVar("player")

	if (not IsValid(client)) then
		return
	end

	Schema.achievement.Progress("ransacked", client)
end

function Schema:OnCharacterFallover(client, ragdoll, isFallenOver)
	-- Kick anyone inspecting this players inventory
	if (isFallenOver) then
		return
	end

	local inventory = client:GetCharacter():GetInventory()

	if (not inventory) then
		return
	end

	-- Check if anyone is searching the player, then close their searching
	if (inventory.storageInfo) then
		Schema.CloseInventory(inventory)
	end
end

function Schema:CanPlayerTie(client, target)
	-- Ensure that they're not tying or chloroforming someone already
	if (client:GetNetVar("tying") or client:GetNetVar("chloroforming")) then
		return false
	end

	local ragdollEntIndex = target:GetLocalVar("ragdoll")

	if (ragdollEntIndex) then
		-- Always tie ragdolls, no matter how they're facing
		return
	end

	local isFacingAway = (target:GetAimVector():DotProduct(client:GetAimVector()) > 0)

	if (not isFacingAway) then
		client:Notify("You must be standing behind the target to tie them!")
		return false
	end
end

function Schema:CanPlayerChloroform(client, target)
	-- Ensure that they're not tying or chloroforming someone already
	if (client:GetNetVar("tying") or client:GetNetVar("chloroforming")) then
		return false
	end
end

function Schema:OnPlayerBecameTied(client, tiedBy)
	Schema.achievement.Progress("zip_ninja", tiedBy)
end

function Schema:PlayerButtonDown(client, button)
	if (client:GetNetVar("tied")) then
		Schema.TiedPlayerPressedBreakFree(client, button)
	end
end

function Schema:OnPlayerLockerOpened(client, lockers)
	ix.log.Add(client, "openLockers")
end

function Schema:OnPlayerLockerClosed(client, lockers)
	ix.log.Add(client, "closeLockers")
end

function Schema:PlayerCanSelectSpawnPoint(client, spawn, spawnIndex)
	local availableSpawns = Schema.spawnPoints.GetAvailableSpawns(client)
	local spawn = availableSpawns[spawnIndex]

	if (spawn.status ~= Schema.spawnPoints.spawnStatus.SAFE and spawn.status ~= Schema.spawnPoints.spawnStatus.CHAOS) then
		return false, "You cannot spawn at this location!"
	end

	return true
end

Schema.chunkedNetwork.HandleSend("NpcEdit", function(client, data, extraData)
	local npcToEdit = Entity(data.entityIndex or 0)
	local name = data.name and data.name:Trim()
	local model = data.model and data.model:Trim()
	local uniqueID = data.uniqueID and data.uniqueID:Trim()
	local description = data.description and data.description:Trim()
	local voicePitch = data.voicePitch and tonumber(data.voicePitch) or 100
	local interactionSets = data.interactionSets or {}

	if (not Schema.npc.HasManagePermission(client)) then
		client:Notify("You do not have permission to manage NPCs!")
		return
	end

	if (uniqueID == "") then
		client:Notify("You must enter a uniqueID for the NPC!")
		return
	end

	if (not Schema.util.IsSafeFileName(uniqueID)) then
		client:Notify("The uniqueID you entered is not valid (must be usable as a file name)!")
		return
	end

	if (name == "") then
		client:Notify("You must enter a name for the NPC!")
		return
	end

	if (description == "") then
		client:Notify("You must enter a description for the NPC!")
		return
	end

	if (model == "") then
		client:Notify("You must enter a model for the NPC!")
		return
	end

	if (not util.IsValidModel(model)) then
		client:Notify("The model you entered is not valid!")
		return
	end

	if (voicePitch < 0 or voicePitch > 255) then
		client:Notify("The voice pitch must be between 0 and 255!")
		return
	end

	local existingNpc = Schema.npc.Get(uniqueID)
	local npcData = {
		uniqueID = uniqueID,
		name = name,
		model = model,
		description = description,
		voicePitch = voicePitch,
		interactionSets = interactionSets,
	}

	if (npcToEdit ~= Entity(0)) then
		if (not IsValid(npcToEdit) or not npcToEdit.IsExperimentNPC) then
			client:Notify("The NPC you are trying to edit is not a valid NPC!")
			return
		end

		local currentID = npcToEdit:GetNpcId()

		if (currentID ~= uniqueID) then
			if (existingNpc) then
				client:Notify("An NPC with this uniqueID already exists!")
				return
			end

			-- Remove the file so a new one can be created
			Schema.npc.Destroy(currentID)

			-- Remove the old registration
			local currentNpc = Schema.npc.Get(currentID)
			Schema.npc.UnRegister(currentNpc)
		else
			-- Ensure the tables are emptied so if there's no in the new data, we don't keep the old
			-- (since they're merged)
			local currentNpc = Schema.npc.Get(currentID)
			currentNpc.interactionSets = {}
		end
	else
		if (existingNpc) then
			client:Notify("An NPC with this uniqueID already exists!")
			return
		end
	end

	-- Save the data as configured by the user (before Register modifies it)
	Schema.npc.Save(npcData)

	local npc = Schema.npc.RegisterDynamic(npcData)

	if (npcToEdit ~= Entity(0)) then
		npcToEdit:SetupNPC(npc)
	else
		local npcEntity = Schema.npc.SpawnForPlayer(npc, client)
		Schema.npc.OpenEditor(client, npcEntity)
	end
end)

-- Hook into inline editting, when an admin edits the interaction inside the interaction panel.
Schema.chunkedNetwork.HandleSend("NpcInteractEdit", function(client, data, extraData)
	if (not Schema.npc.HasManagePermission(client)) then
		client:Notify("You do not have permission to edit NPC interactions!")
		return
	end

	local npcId = data[1]
	local npcName = data[2]
	local text = data[3]
	local answers = data[4]

	if (not isstring(npcName)) then
		client:Notify("Invalid NPC name specified!")
		return
	end

	if (not isstring(text)) then
		client:Notify("Invalid text specified!")
		return
	end

	if (not istable(answers)) then
		client:Notify("Invalid answers specified!")
		return
	end

	local npc = Schema.npc.Get(npcId)

	if (not npc) then
		client:Notify("Invalid NPC specified!")
		return
	end

	-- Check if this player is indeed interacting with this NPC
	if (not client.expCurrentInteraction or client.expCurrentInteraction.npcEntity:GetNpcId() ~= npcId) then
		client:Notify("You are not currently interacting with this NPC!")
		return
	end

	local interactionSet = client.expCurrentInteraction.interactionSet

	if (not interactionSet.isDynamic) then
		client:Notify("This NPC interaction set is not dynamic and cannot be edited!")
		return
	end

	local interaction = client.expCurrentInteraction.interaction

	if (not interaction) then
		client:Notify("You are not currently interacting with this NPC!")
		return
	end

	-- Try load the data, editting it, then saving it back
	local npcRegistration = Schema.npc.Load(npcId)

	if (not npcRegistration) then
		client:Notify("Failed to load NPC data for editing!")
		return
	end

	local foundSet = false
	local foundInter = false

	-- Find the interaction set and edit it
	for _, set in ipairs(npcRegistration.interactionSets) do
		if (set.uniqueID == interactionSet.uniqueID) then
			foundSet = true

			-- Find the interaction and edit it
			for _, inter in ipairs(set.interactions) do
				if (inter.uniqueID == interaction.uniqueID) then
					foundInter = true
					inter.text = text

					-- If an answer does not exist, we add it
					for i, answer in ipairs(answers) do
						if (not inter.responses[i]) then
							inter.responses[i] = {
								answer = answer,
							}
						else
							inter.responses[i].answer = answer
						end
					end

					-- If an answer exists that should not, we remove it
					for i = #answers + 1, #inter.responses do
						inter.responses[i] = nil
					end

					inter.responses = table.ClearKeys(inter.responses)

					break
				end
			end

			break
		end
	end

	if (not foundSet) then
		client:Notify("Failed to find the interaction set for editing!")
		return
	end

	if (not foundInter) then
		client:Notify("Failed to find the interaction for editing!")
		return
	end

	npcRegistration.name = npcName

	Schema.npc.Save(npcRegistration)

	-- Reload the data
	local newNpc = Schema.npc.RegisterDynamic(npcRegistration)

	local npcEntity = client.expCurrentInteraction.npcEntity

	if (IsValid(npcEntity)) then
		npcEntity:SetupNPC(newNpc)
	end
end)

Schema.chunkedNetwork.HandleRequest("Progressions", function(client, respond, requestData)
	if (not Schema.progression.HasManagePermission(client)) then
		client:Notify("You do not have permission to manage progression trackers!")
		return
	end

	local progressions = Schema.util.CopyOmitCyclicReference(Schema.progression.GetAllDynamic())

	respond(progressions)
end)

Schema.chunkedNetwork.HandleSend("ProgressionEdit", function(client, data, extraData)
	if (not Schema.progression.HasManagePermission(client)) then
		client:Notify("You do not have permission to manage progression trackers!")
		return
	end

	local name = data.name and data.name:Trim()
	local scope = data.scope and data.scope:Trim()
	local currentUniqueID = data.currentUniqueID and data.currentUniqueID:Trim()
	local uniqueID = data.uniqueID and data.uniqueID:Trim()
	local completedKey = data.completedKey
	local isInProgressInfo = data.isInProgressInfo
	local progressionKeys = data.progressionKeys or {}
	local goals = data.goals or {}

	if (uniqueID == "") then
		client:Notify("You must enter a uniqueID for the progression tracker!")
		return
	end

	if (not Schema.util.IsSafeFileName(uniqueID)) then
		client:Notify("The uniqueID you entered is not valid (must be usable as a file name)!")
		return
	end

	if (scope == "") then
		client:Notify("You must enter a scope for the progression tracker!")
		return
	end

	if (name == "") then
		client:Notify("You must enter a name for the progression tracker!")
		return
	end

	local existingProgression = Schema.progression.GetTracker(uniqueID)
	local progressionData = {
		uniqueID = uniqueID,
		scope = scope,
		name = name,
		completedKey = completedKey,
		isInProgressInfo = isInProgressInfo,
		progressionKeys = progressionKeys,
		goals = goals,
	}

	if (currentUniqueID) then
		if (currentUniqueID ~= uniqueID) then
			if (existingProgression) then
				client:Notify("An progression tracker with this uniqueID already exists!")
				return
			end

			-- Remove the file so a new one can be created
			Schema.progression.Destroy(currentUniqueID)

			-- Remove the old registration
			local currentProgression = Schema.progression.GetTracker(currentUniqueID)
			assert(currentProgression, "The current progression should exist")
			Schema.progression.UnRegisterTracker(currentProgression)
		else
			-- Ensure the tables are emptied so if there's no in the new data, we don't keep the old
			-- (since they're merged)
			local currentProgression = Schema.progression.GetTracker(currentUniqueID)
			currentProgression.progressionKeys = {}
			currentProgression.goals = {}
		end
	end

	-- Save the data as configured by the user (before Register modifies it)
	Schema.progression.Save(progressionData)

	local progression = Schema.progression.RegisterDynamic(progressionData)

	Schema.PrintTableDev(progression)

	-- Ensure the player has updated info
	Schema.progression.NetworkDynamicChanges(client)
end)
