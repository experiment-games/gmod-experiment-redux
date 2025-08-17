local SCENE = SCENE

SCENE.cinematicSpawnID = "prologue_riot2"

ix.util.Include("prologue_riot3/sh_mission_tracker.lua", "shared")

if (SERVER) then
	local function findItemSpawnPoint(sequenceID, itemSpawnID)
		for _, ent in ipairs(ents.FindByClass("exp_cinematic_item_spawn")) do
			if (ent:GetSequenceID() == sequenceID and ent:GetItemSpawnID() == itemSpawnID) then
				return ent
			end
		end

		return nil
	end

	local function findEnemySpawnPoint(sequenceID, enemySpawnID)
		for _, ent in ipairs(ents.FindByClass("exp_cinematic_enemy_spawn")) do
			if (ent:GetSequenceID() == sequenceID and ent:GetEnemySpawnID() == enemySpawnID) then
				return ent
			end
		end

		return nil
	end

	function SCENE:OnEnterServer(client)
		Schema.instance.AddPlayer(client)

		Schema.progression.Change(client, "prologue", SCENE.PROGRESSION_INTRO_STARTED, true)

		-- Spawn weapon and ammo in this client's instance
		local weaponSpawn = findItemSpawnPoint(SCENE.cinematicSpawnID, "weapon")
		local ammoSpawn = findItemSpawnPoint(SCENE.cinematicSpawnID, "ammo")

		if (not weaponSpawn or not ammoSpawn) then
			ix.util.SchemaErrorNoHalt("Prologue scene 'prologue_riot2' is missing item spawn points for weapon or ammo!")
			Schema.cinematics.RemovePlayerFromSceneFadeOut(client)
			return
		end

		local weaponItemTable = ix.item.Get("ex_glock")
		local ammo = Schema.ammo.ConvertToAmmo(weaponItemTable.forcedWeaponCalibre)
		local ammoItemTable = Schema.ammo.FindMainAmmoItem(ammo)

		if (not ammoItemTable) then
			ix.util.SchemaErrorNoHalt("Prologue scene 'prologue_riot2' is missing ammo item for weapon!")
			Schema.cinematics.RemovePlayerFromSceneFadeOut(client)
			return
		end

		local instanceID = Schema.instance.GetPlayerInstance(client)

		-- Track the items this player has to pick up
		client.expPrologueRiot3Items = {}

		ix.item.Spawn(weaponItemTable.uniqueID, weaponSpawn:GetPos(), function(item, itemEntity)
			if (not IsValid(client)) then
				itemEntity:Remove()
				return
			end

			-- Prevent the map saving this item
			itemEntity.bTemporary = true

			Schema.instance.AddEntity(itemEntity, instanceID)

			client.expPrologueRiot3Items["weapon"] = item

			Schema.entityMarker.MarkForPlayer(client, itemEntity)
		end)

		ix.item.Spawn(ammoItemTable.uniqueID, ammoSpawn:GetPos(), function(item, itemEntity)
			if (not IsValid(client)) then
				itemEntity:Remove()
				return
			end

			-- Prevent the map saving this item
			itemEntity.bTemporary = true

			Schema.instance.AddEntity(itemEntity, instanceID)

			client.expPrologueRiot3Items["ammo"] = item

			Schema.entityMarker.MarkForPlayer(client, itemEntity)
		end)

		-- TODO: instruct player how to equip weapon and ammo
		-- TODO: End scene after they kill the manhack, or when the time expires
		-- TODO: Handle softlocks, like where they drop the weapon outside bounds or something (currently handled with removal of items, we should detect that and respawn them or something)

		--[[
		Some sounds to have an NPC possibly say:
			vo/canals/arrest_helpme.wav <- cry for help

			vo/npc/female01/coverwhilereload01.wav
			vo/npc/female01/coverwhilereload02.wav
			vo/npc/male01/coverwhilereload01.wav
			vo/npc/male01/coverwhilereload02.wav

			vo/npc/male01/ammo03.wav
			vo/npc/male01/ammo04.wav
			vo/npc/male01/ammo05.wav

			vo/npc/male01/behindyou01.wav

			vo/npc/male01/gethellout.wav

			vo/npc/male01/herecomehacks01.wav
			vo/npc/male01/herecomehacks02.wav
			vo/npc/male01/heretheycome01.wav

			vo/npc/male01/youdbetterreload01.wav
	--]]

		-- Hard-timer to end scene after some time
		timer.Simple(60 * 10, function()
			if (IsValid(client) and Schema.cinematics.IsPlayerInScene(client, "prologue_riot2")) then
				Schema.cinematics.RemovePlayerFromSceneFadeOut(client)
			end
		end)

		-- TODO: Hard-timer to spawn the manhacks regardless of whether the player has picked up the items
	end

	function SCENE:OnLeaveServer(client)
		Schema.progression.Change(client, "prologue", SCENE.PROGRESSION_INTRO_COMPLETED, true)

		local instanceID = Schema.instance.GetPlayerInstance(client)
		Schema.instance.DestroyInstance(instanceID, "end_of_scene")

		client:GetCharacter():SetData("prologue_finished", true)

		client.expPrologueRiot3Items = nil
		client.expPrologueRiot3ManhacksSpawned = nil

		client:KillSilent()
		client:Spawn()

		-- Strip all items from the player in this flashback
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		for item, _ in inventory:Iter() do
			item:Remove()
		end

		hook.Run("PlayerFillDefaultInventory", client, character, inventory)
	end

	local function spawnManhack(position, targetClient)
		local instanceID = Schema.instance.GetPlayerInstance(targetClient)

		if (not instanceID) then
			-- If the player somehow left the instance we don't need manhacks anymore
			return
		end

		local manhack = ents.Create("npc_manhack")
		manhack:SetPos(position)
		manhack:Spawn()

		-- Set relationships with anything neutral, except the target
		manhack:AddRelationship("player D_NU 98")
		manhack:AddEntityRelationship(targetClient, D_HT, 99)

		manhack:SetTarget(targetClient)
		manhack:UpdateEnemyMemory(targetClient, targetClient:GetPos())

		Schema.instance.AddEntity(manhack, instanceID)


		Schema.entityMarker.MarkForPlayer(targetClient, manhack)

		return manhack
	end

	-- Track the next phase if the player picks up both items
	hook.Add("OnItemTransferred", "expPrologueRiot3OnItemTransferred", function(item, oldInventory, newInventory)
		if (not item.entity or not newInventory) then
			return
		end

		local itemInstanceID = Schema.instance.GetEntityInstance(item.entity)

		if (not itemInstanceID) then
			return
		end

		local inventoryOwner = newInventory:GetOwner()

		if (not IsValid(inventoryOwner) or not inventoryOwner.expPrologueRiot3Items) then
			return
		end

		local weaponToPickup = inventoryOwner.expPrologueRiot3Items["weapon"]
		local ammoToPickup = inventoryOwner.expPrologueRiot3Items["ammo"]

		if (weaponToPickup and weaponToPickup == item) then
			-- Player picked up the weapon
			Schema.progression.Change(inventoryOwner, "prologue", SCENE.PROGRESSION_GLOCK_PICKED_UP, true)
		end

		if (ammoToPickup and ammoToPickup == item) then
			-- Player picked up the ammo
			Schema.progression.Change(inventoryOwner, "prologue", SCENE.PROGRESSION_AMMO_PICKED_UP, true)
		end
	end)

	-- Also track the next phase if the player picks up the weapon and immediately loads the ammo
	hook.Add("PlayerAmmoChanged", "expPrologueRiot3PlayerAmmoChanged", function(client, ammoID, oldCount, newCount)
		if (not IsValid(client) or not client.expPrologueRiot3Items or not client.expPrologueRiot3Items["ammo"]) then
			return
		end

		local ammoItemTable = Schema.ammo.FindMainAmmoItem(ammoID)

		if (not ammoItemTable or client.expPrologueRiot3Items["ammo"].uniqueID ~= ammoItemTable.uniqueID) then
			return
		end

		client.expPrologueRiot3Items["ammo"] = nil

		Schema.progression.Change(client, "prologue", SCENE.PROGRESSION_AMMO_PICKED_UP, true)
		Schema.progression.Change(client, "prologue", SCENE.PROGRESSION_AMMO_LOADED, true)
	end)

	-- Track if the player equipped the Glock
	hook.Add("WeaponEquip", "expPrologueRiot3WeaponEquip", function(weapon, client)
		if (not IsValid(client) or not client.expPrologueRiot3Items) then
			return
		end

		if (client.expPrologueRiot3Items["weapon"].class ~= weapon:GetClass()) then
			return
		end

		Schema.progression.Change(client, "prologue", SCENE.PROGRESSION_GLOCK_EQUIPPED, true)
	end)

	-- Track if the player switched to the Glock
	hook.Add("PlayerSwitchWeapon", "expPrologueRiot3PlayerSwitchWeapon", function(client, oldWeapon, newWeapon)
		if (not IsValid(client) or not client.expPrologueRiot3Items) then
			return
		end

		if (client.expPrologueRiot3Items["weapon"].class ~= newWeapon:GetClass()) then
			return
		end

		Schema.progression.Change(client, "prologue", SCENE.PROGRESSION_GLOCK_ACTIVE, true)
	end)

	-- Track if the player raised the Glock
	hook.Add("PlayerChangedWeaponRaised", "expPrologueRiot3PlayerChangedWeaponRaised", function(client, weapon, bState)
		if (not IsValid(client) or not client.expPrologueRiot3Items or not bState) then
			return
		end

		if (client.expPrologueRiot3Items["weapon"].class ~= weapon:GetClass()) then
			return
		end

		Schema.progression.Change(client, "prologue", SCENE.PROGRESSION_GLOCK_RAISED, true)
	end)

	-- Based on the player's progression, we spawn the manhacks
	hook.Add("PlayerProgressionChange", "expPrologueRiot3PlayerProgressionChange", function(client, scope, key, value)
		if (scope ~= "prologue" or not Schema.cinematics.IsPlayerInScene(client, "prologue_riot3")) then
			return
		end

		if (client.expPrologueRiot3ManhacksSpawned) then
			if (key == SCENE.PROGRESSION_MANHACKS_KILLED_COUNT and value >= SCENE.REQUIRED_MANHACKS) then
				-- They've defeated all manhacks, remove them from the scene
				Schema.cinematics.RemovePlayerFromSceneFadeOut(client)
			end

			return
		end

		-- Check if all items have been picked up, equipped and raised
		local weaponEquipped = Schema.progression.Check(client, "prologue", SCENE.PROGRESSION_GLOCK_EQUIPPED, true)
		local ammoLoaded = Schema.progression.Check(client, "prologue", SCENE.PROGRESSION_AMMO_LOADED, true)
		local glockRaised = Schema.progression.Check(client, "prologue", SCENE.PROGRESSION_GLOCK_RAISED, true)

		if (not weaponEquipped or not ammoLoaded or not glockRaised) then
			return
		end

		local spawnPoint = findEnemySpawnPoint(SCENE.cinematicSpawnID, "manhack")

		if (not spawnPoint) then
			return
		end

		-- Spawn manhacks at an interval
		local spawnIntervalSeconds = 2

		client.expPrologueRiot3ManhacksSpawned = true

		for i = 0, SCENE.REQUIRED_MANHACKS - 1 do
			print("Spawning manhack #" .. (i + 1) .. " for client ", client)
			timer.Simple(i * spawnIntervalSeconds, function()
				spawnManhack(spawnPoint:GetPos(), client)
			end)
		end
	end)

	hook.Add("OnNPCKilled", "expPrologueRiot3OnNPCKilled", function(npc, attacker, inflictor)
		if (
				not IsValid(attacker)
				or not attacker:IsPlayer()
				or not Schema.cinematics.IsPlayerInScene(attacker, "prologue_riot3")
			) then
			return
		end

		Schema.progression.Change(attacker, "prologue", SCENE.PROGRESSION_MANHACKS_KILLED_COUNT, function(value)
			return (value or 0) + 1
		end)
	end)

	-- Edge case, if the player is in the scene and they die, get them out
	hook.Add("PostPlayerDeath", "expPrologueRiot3PostPlayerDeath", function(client)
		if (not Schema.cinematics.IsPlayerInScene(client, "prologue_riot3")) then
			return
		end

		Schema.cinematics.RemovePlayerFromSceneFadeOut(client)
	end)
end

if (CLIENT) then
	function SCENE:OnDraw()
		-- Schema.draw.DrawUndimmedRect(x, y, w, h)
	end

	function SCENE:OnEnterLocalPlayer()
		Schema.cinematics.SetFogData(50, 850, color_black, 1)
		Schema.cinematics.SetBlackAndWhite(true)

		local nemesisPlugin = ix.plugin.Get("nemesis_ai")

		if (nemesisPlugin) then
			nemesisPlugin:SetClientSpecificMonitorVgui("prologue_riot2", function(parent)
				return vgui.Create("expPrologueMonitorRiot2", parent)
			end)
		end

		local tracker = Schema.progression.GetTracker(SCENE.SCENE_TRACKER_ID)
		Schema.progression.SetTrackerOnHUD(tracker, true)

		-- Call again after a delay, to ensure the HUD is updated. This is because the progression may not
		-- have networked by now, so we need to force an update.
		timer.Simple(0.5, function()
			Schema.progression.SetTrackerOnHUD(tracker, true)
		end)
		timer.Simple(1.5, function() -- failsafe
			Schema.progression.SetTrackerOnHUD(tracker, true)
		end)
	end

	function SCENE:OnLeaveLocalPlayer()
		local nemesisPlugin = ix.plugin.Get("nemesis_ai")

		if (nemesisPlugin) then
			nemesisPlugin:ClearClientSpecificMonitorVgui("prologue_riot2")
		end

		Schema.entityMarker.ClearAll()
	end

	hook.Add("ProgressionNetworkChange", "expPrologueRiot3ProgressionNetworkChange", function(client, scope, key, value)
		if (scope ~= "prologue") then
			return
		end

		-- TODO: Update hints based on what hasn't been done yet (e.g: weapon pickup, ammo pickup, open inventory and equip + load ammo)
	end)
end

hook.Add("ExperimentMonitorsFilter", "expPrologueRiot3DisableNormalBehaviour", function(monitors, filterType)
	for i = #monitors, 1, -1 do
		local monitor = monitors[i]
		local specialID = monitor:GetSpecialID()

		if (specialID and specialID == "prologue_riot2") then
			table.remove(monitors, i)
		end
	end
end)
