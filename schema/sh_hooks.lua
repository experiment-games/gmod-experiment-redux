local function hackOptionRestrictions()
	timer.Simple(0, function()
		if (not ix.option.stored["language"]) then
			return
		end

		-- ! Hack to disable other languages for now.
		-- TODO: Write translations for other languages than English
		ix.option.stored["language"].populate = function()
			return {
				["english"] = "English"
			}
		end

		local function hide()
			return true
		end

		ix.option.stored["language"].hidden = hide

		if (CLIENT) then
			-- ! Hack to not show option for enabling intro
			ix.option.stored["showIntro"].hidden = hide

			-- ! This options doesn't work I think
			ix.option.stored["altLower"].hidden = hide
		end
	end)
end

hook.Add("InitializedSchema", "hackEnglishOnlyInitialize", hackOptionRestrictions)
hook.Add("OnReloaded", "hackEnglishOnlyOnReloaded", hackOptionRestrictions)

function Schema:DoPluginIncludes(path, plugin)
	Schema.cinematics.IncludeDirectory(path .. "/cinematic_scenes", "SCENE")
	Schema.achievement.IncludeDirectory(path .. "/achievements")
	Schema.buff.IncludeDirectory(path .. "/buffs")
	Schema.perk.IncludeDirectory(path .. "/perks")
	Schema.npc.IncludeDirectory(path .. "/npcs")
	Schema.map.IncludeDirectory(path .. "/maps")
	Schema.tutorial.IncludeDirectory(path .. "/tutorials")
end

function Schema:Tick()
	if (CLIENT) then
		if (IsValid(ix.gui.openedStorage)
				and ix.gui.openedStorage.storageInventory.invID
				and ix.gui.inv1.invID
				and not ix.gui.openedStorage.hasSchemaSetup) then
			ix.gui.openedStorage.hasSchemaSetup = true

			Schema.SetupStoragePanel(ix.gui.openedStorage, ix.gui.openedStorage.storageInventory, ix.gui.inv1)
		end

		if (IsValid(ix.gui.inv1)
				and not ix.gui.inv1.hasSchemaSetup) then
			ix.gui.inv1.hasSchemaSetup = true

			Schema.SetupInventorySlots(ix.gui.inv1)
		end
	end

	if (self.nextPlayerTick and CurTime() < self.nextPlayerTick) then
		return
	end

	self.nextPlayerTick = CurTime() + 1

	for _, client in ipairs(player.GetAll()) do
		hook.Run("PlayerSecondElapsed", client)
	end
end

function Schema:CanPlayerUseBusiness(client, uniqueID)
	local itemTable = ix.item.list[uniqueID]

	if (itemTable.OnCanOrder) then
		return itemTable:OnCanOrder(client)
	end

	local requirementKeys = {
		requiresGunsmith = "gunsmith",
		requiresArmadillo = "armadillo",
	}

	for key, perk in pairs(requirementKeys) do
		if (itemTable[key] and not Schema.perk.GetOwned(perk, client)) then
			return false
		end
	end
end

function Schema:InitializedPlugins()
	local ammoItems = {}
	local items = ix.item.list

	for _, item in pairs(items) do
		if (item.mergeIntoSwep and item.class) then
			local swep = weapons.GetStored(item.class)

			if (not swep) then
				ErrorNoHaltWithStack("Item " ..
					tostring(item.uniqueID) ..
					" has a mergeIntoSwep but the weapon class (" .. tostring(item.class) .. ") does not exist!\n")
			end

			table.Merge(swep, item.mergeIntoSwep, true)
		end

		if (item.isAttachment and item.class) then
			Schema.RegisterWeaponAttachment(item)
		end

		if (item:IsBasedOn("base_ammo") and item.calibre) then
			ammoItems[item.calibre] = item
		end

		if (item.forcedWeaponCalibre) then
			if (not item.class) then
				ix.util.SchemaErrorNoHalt("Item " ..
					item.uniqueID .. " does not have a class, can't force bullet calibre.")
				continue
			end

			Schema.ammo.ForceWeaponCalibre(item.class, item.forcedWeaponCalibre)
		end
	end

	local calibres = Schema.ammo.GetAllCalibres()

	-- Check if the calibre has a matching ammo item
	for _, calibre in ipairs(calibres) do
		if (not ammoItems[calibre]) then
			ix.util.SchemaErrorNoHalt("No ammo item found for calibre '" ..
				calibre .. "'. You should create an ammo item for this calibre.\n")
		end
	end

	if (SERVER) then
		local anyNewUnloaded = false

		for _, pluginID in ipairs(Schema.disabledPlugins) do
			local pluginUnloaded = ix.plugin.unloaded[pluginID] == true

			if (not pluginUnloaded) then
				anyNewUnloaded = true
				ix.plugin.SetUnloaded(pluginID, true)
				ix.util.SchemaErrorNoHalt("Helix Plugin Notice: The plugin '" ..
					pluginID .. "' is marked as disabled in the schema.\n")
			end
		end

		if (anyNewUnloaded) then
			ix.util.SchemaErrorNoHalt(
				"Helix Plugin Notice: Some plugins were disabled by the schema. You should most definitely restart the server to apply these changes!\n"
			)
		end
	end

	Schema.RegisterMaterialSources()
end

function Schema:EntityKeyValue(entity, key, value)
	local maps = Schema.map.FindByProperty("mapName", game.GetMap(), true)

	for _, map in ipairs(maps) do
		if (map.EntityKeyValue) then
			local override = map:EntityKeyValue(entity, key, value)

			if (override ~= nil) then
				return override
			end
		end
	end
end

function Schema:PlayerFootstep(client, position, foot, soundName, volume, filter)
	local mode = client:IsRunning() and "run" or "walk"

	if (mode == "walk" and Schema.perk.GetOwned("light_step", client)) then
		return true
	end

	if (client:IsBot()) then
		-- Bots wont have an inventory
		return
	end

	local armorItems = client:GetCharacterNetVar("armorItems", {})
	local soundOverride

	for _, uniqueId in ipairs(armorItems) do
		local item = ix.item.list[uniqueId]

		if (not item or not item.footstepSounds) then
			continue
		end

		local footstepSounds = item.footstepSounds[mode]

		if (not footstepSounds) then
			continue
		end

		soundOverride = footstepSounds[math.random(#footstepSounds)]
	end

	if (soundOverride) then
		EmitSound(soundOverride, position, 0, CHAN_BODY, volume, 75, 0, 100, 0, filter)
		return true
	end

	if (soundName:StartsWith("player/footsteps/wood")) then
		local shouldPlaySqueekSound = math.Rand(0, 100) <= 0.5

		if (shouldPlaySqueekSound) then
			soundOverride = mode == "walk" and "ambient/materials/squeekyfloor1.wav" or
				"ambient/materials/squeekyfloor2.wav"

			EmitSound(soundOverride, position, 0, CHAN_BODY, volume, 75, 0, math.random(95, 105), 0, filter)
		end
	end
end

function Schema:GetDefaultAttributePoints(client)
	return 5
end

function Schema:AdjustMaterialSources(materialSources)
	--[[
		Wooden props
	--]]

	-- Wooden drawer

	materialSources:Add({
		uniqueID = "source_wood_drawer_chunk1",
		name = "Wooden Drawer Chunk",
		chanceToScavenge = Schema.RARITY_UNCOMMON,
		model = "models/props_c17/furnituredrawer001a_chunk01.mdl",
		scrapMaterials = {
			["material_wood"] = 3,
		}
	})

	materialSources:Add({
		uniqueID = "source_wood_drawer_chunk2",
		name = "Wooden Drawer Chunk",
		chanceToScavenge = Schema.RARITY_UNCOMMON,
		model = "models/props_c17/furnituredrawer001a_chunk02.mdl",
		scrapMaterials = {
			["material_wood"] = 3,
		}
	})

	materialSources:Add({
		uniqueID = "source_wood_drawer_chunk3",
		name = "Wooden Drawer Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_c17/furnituredrawer001a_chunk03.mdl",
		scrapMaterials = {
			["material_wood"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_wood_drawer_chunk4",
		name = "Wooden Drawer Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_c17/furnituredrawer001a_chunk04.mdl",
		scrapMaterials = {
			["material_wood"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_wood_drawer_chunk5",
		name = "Wooden Drawer Chunk",
		chanceToScavenge = Schema.RARITY_UNCOMMON,
		model = "models/props_c17/furnituredrawer001a_chunk05.mdl",
		scrapMaterials = {
			["material_wood"] = 3,
		}
	})

	materialSources:Add({
		uniqueID = "source_wood_drawer_chunk6",
		name = "Wooden Drawer Chunk",
		chanceToScavenge = Schema.RARITY_UNCOMMON,
		model = "models/props_c17/furnituredrawer001a_chunk06.mdl",
		scrapMaterials = {
			["material_wood"] = 3,
		}
	})

	-- Wooden chair

	materialSources:Add({
		uniqueID = "source_wood_chair_chunk1",
		name = "Wooden Chair Chunk",
		chanceToScavenge = Schema.RARITY_UNCOMMON,
		model = "models/props_c17/furniturechair001a_chunk01.mdl",
		scrapMaterials = {
			["material_wood"] = 3,
		}
	})

	materialSources:Add({
		uniqueID = "source_wood_chair_chunk2",
		name = "Wooden Chair Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_c17/furniturechair001a_chunk02.mdl",
		scrapMaterials = {
			["material_wood"] = 2,
			-- ["material_cloth"] = 1,
		}
	})

	materialSources:Add({
		uniqueID = "source_wood_chair_chunk3",
		name = "Wooden Chair Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_c17/furniturechair001a_chunk03.mdl",
		scrapMaterials = {
			["material_wood"] = 2,
		}
	})

	-- Barricade 1

	materialSources:Add({
		uniqueID = "source_barricade_chunk1",
		name = "Barricade Chunk",
		chanceToScavenge = Schema.RARITY_UNCOMMON,
		model = "models/props_wasteland/barricade001a_chunk01.mdl",
		scrapMaterials = {
			["material_wood"] = 1,
			["material_metal"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_barricade_chunk2",
		name = "Barricade Chunk",
		chanceToScavenge = Schema.RARITY_UNCOMMON,
		model = "models/props_wasteland/barricade001a_chunk02.mdl",
		scrapMaterials = {
			["material_wood"] = 1,
			["material_metal"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_barricade_chunk3",
		name = "Barricade Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_wasteland/barricade001a_chunk03.mdl",
		scrapMaterials = {
			["material_wood"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_barricade_chunk4",
		name = "Barricade Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_wasteland/barricade001a_chunk04.mdl",
		scrapMaterials = {
			["material_wood"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_barricade_chunk5",
		name = "Barricade Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_wasteland/barricade001a_chunk05.mdl",
		scrapMaterials = {
			["material_wood"] = 2,
		}
	})

	-- Barricade 2

	materialSources:Add({
		uniqueID = "source_barricade2_chunk1",
		name = "Barricade Chunk",
		chanceToScavenge = Schema.RARITY_UNCOMMON,
		model = "models/props_wasteland/barricade002a_chunk01.mdl",
		scrapMaterials = {
			["material_wood"] = 1,
			["material_metal"] = 3,
		}
	})

	materialSources:Add({
		uniqueID = "source_barricade2_chunk2",
		name = "Barricade Chunk",
		chanceToScavenge = Schema.RARITY_UNCOMMON,
		model = "models/props_wasteland/barricade002a_chunk02.mdl",
		scrapMaterials = {
			["material_wood"] = 1,
			["material_metal"] = 3,
		}
	})

	for i = 3, 6 do
		materialSources:Add({
			uniqueID = "source_barricade2_chunk" .. i,
			name = "Barricade Chunk",
			chanceToScavenge = Schema.RARITY_COMMON,
			model = "models/props_wasteland/barricade001a_chunk0" .. i .. ".mdl",
			scrapMaterials = {
				["material_wood"] = 2,
			}
		})
	end

	--[[
		Hard metal props
	--]]

	-- Big props

	materialSources:Add({
		uniqueID = "source_metal_bedframe_chunk1",
		name = "Damaged Bedframe",
		chanceToScavenge = Schema.RARITY_RARE,
		model = "models/props_wasteland/prison_bedframe001a.mdl",
		scrapMaterials = {
			["material_metal"] = 6,
		},
		noDrop = true,
	})

	materialSources:Add({
		uniqueID = "source_metal_bedframe_chunk2",
		name = "Damaged Bedframe",
		chanceToScavenge = Schema.RARITY_RARE,
		model = "models/props_wasteland/prison_bedframe001b.mdl",
		scrapMaterials = {
			["material_metal"] = 6,
		},
		noDrop = true,
	})

	-- Small props

	for i = 1, 8 do
		materialSources:Add({
			uniqueID = "source_metal_vent_chunk" .. i,
			name = "Ventilation Cover Chunk",
			chanceToScavenge = Schema.RARITY_COMMON,
			model = "models/props_junk/vent001_chunk" .. i .. ".mdl",
			scrapMaterials = {
				["material_metal"] = 2,
			}
		})
	end

	materialSources:Add({
		uniqueID = "source_metal_toilet_chunk1",
		name = "Toilet Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_wasteland/prison_toiletchunk01c.mdl",
		scrapMaterials = {
			["material_metal"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_metal_sink_chunk1",
		name = "Sink Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_wasteland/prison_sinkchunk001e.mdl",
		scrapMaterials = {
			["material_metal"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_metal_connector_chunk2",
		name = "Connector Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_c17/utilityconnecter002.mdl",
		scrapMaterials = {
			["material_metal"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_metal_connector_chunk3",
		name = "Connector Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_c17/utilityconnecter003.mdl",
		scrapMaterials = {
			["material_metal"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_metal_connector_chunk5",
		name = "Connector Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_c17/utilityconnecter005.mdl",
		scrapMaterials = {
			["material_metal"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_metal_connector_chunk6",
		name = "Connector Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_c17/utilityconnecter006.mdl",
		scrapMaterials = {
			["material_metal"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_metal_gascan",
		name = "Empty Gas Can",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/metalgascan.mdl",
		scrapMaterials = {
			["material_metal"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_metal_popcan",
		name = "Empty Pop Can",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/popcan01a.mdl",
		scrapMaterials = {
			["material_metal"] = 1,
		}
	})

	--[[
		Plastic props
	--]]

	-- Small props

	materialSources:Add({
		uniqueID = "source_plastic_milkcarton",
		name = "Empty Milk Carton",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/garbage_milkcarton001a.mdl",
		scrapMaterials = {
			["material_plastic"] = 1,
		}
	})

	materialSources:Add({
		uniqueID = "source_plastic_bottle",
		name = "Empty Plastic Bottle",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/garbage_plasticbottle001a.mdl",
		scrapMaterials = {
			["material_plastic"] = 1,
		}
	})

	materialSources:Add({
		uniqueID = "source_plastic_bottle_chunk2",
		name = "Empty Plastic Bottle",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/garbage_plasticbottle002a.mdl",
		scrapMaterials = {
			["material_plastic"] = 1,
		}
	})

	materialSources:Add({
		uniqueID = "source_plastic_bottle_chunk3",
		name = "Empty Plastic Bottle",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/garbage_plasticbottle003a.mdl",
		scrapMaterials = {
			["material_plastic"] = 1,
		}
	})

	materialSources:Add({
		uniqueID = "source_plastic_gascan",
		name = "Empty Gas Can",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/gascan001a.mdl",
		scrapMaterials = {
			["material_plastic"] = 2,
		}
	})

	--[[
		Glass props
	--]]

	materialSources:Add({
		uniqueID = "source_glass_bottle1",
		name = "Empty Glass Bottle",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/garbage_glassbottle001a.mdl",
		scrapMaterials = {
			["material_glass"] = 2,
		}
	})

	materialSources:Add({
		uniqueID = "source_glass_bottle2",
		name = "Empty Glass Bottle",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/garbage_glassbottle002a.mdl",
		scrapMaterials = {
			["material_glass"] = 2,
			-- ["material_paper"] = 1, (we don't have this material yet and no use for it)
		}
	})

	materialSources:Add({
		uniqueID = "source_glass_bottle3",
		name = "Empty Glass Bottle",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/garbage_glassbottle003a.mdl",
		scrapMaterials = {
			["material_glass"] = 2,
		}
	})


	-- Chunk props

	-- models/props_junk/glassbottle01a_chunk01a.mdl
	-- models/props_junk/glassbottle01a_chunk02a.mdl
	-- models/props_junk/garbage_glassbottle003a_chunk01.mdl
	-- ... models/props_junk/garbage_glassbottle003a_chunk03.mdl

	materialSources:Add({
		uniqueID = "source_glass_bottle1_chunk1",
		name = "Glass Bottle Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/garbage_glassbottle001a_chunk01.mdl",
		scrapMaterials = {
			["material_glass"] = 1,
		}
	})

	materialSources:Add({
		uniqueID = "source_glass_bottle1_chunk2",
		name = "Glass Bottle Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/garbage_glassbottle001a_chunk02.mdl",
		scrapMaterials = {
			["material_glass"] = 1,
		}
	})

	materialSources:Add({
		uniqueID = "source_glass_bottle1_chunk3",
		name = "Glass Bottle Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/garbage_glassbottle001a_chunk03.mdl",
		scrapMaterials = {
			["material_glass"] = 1,
		}
	})

	materialSources:Add({
		uniqueID = "source_glass_bottle1_chunk4",
		name = "Glass Bottle Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/garbage_glassbottle001a_chunk04.mdl",
		scrapMaterials = {
			["material_glass"] = 1,
		}
	})

	materialSources:Add({
		uniqueID = "source_glass_bottle2_chunk1",
		name = "Glass Bottle Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/garbage_glassbottle002a_chunk01.mdl",
		scrapMaterials = {
			["material_glass"] = 1,
		}
	})

	materialSources:Add({
		uniqueID = "source_glass_bottle2_chunk2",
		name = "Glass Bottle Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/garbage_glassbottle002a_chunk02.mdl",
		scrapMaterials = {
			["material_glass"] = 1,
		}
	})

	materialSources:Add({
		uniqueID = "source_glass_jug_chunk1",
		name = "Glass Jug Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/glassjug01_chunk01.mdl",
		scrapMaterials = {
			["material_glass"] = 1,
		}
	})

	materialSources:Add({
		uniqueID = "source_glass_jug_chunk2",
		name = "Glass Jug Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/glassjug01_chunk02.mdl",
		scrapMaterials = {
			["material_glass"] = 1,
		}
	})

	materialSources:Add({
		uniqueID = "source_glass_jug_chunk3",
		name = "Glass Jug Chunk",
		chanceToScavenge = Schema.RARITY_COMMON,
		model = "models/props_junk/glassjug01_chunk03.mdl",
		scrapMaterials = {
			["material_glass"] = 1,
		}
	})
end
