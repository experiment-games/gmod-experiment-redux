ix.currency.symbol = ""
ix.currency.singular = "bolt"
ix.currency.plural = "bolts"
ix.currency.model = "models/props_lab/box01a.mdl"

if (SERVER) then
	ix.util.AddResourceFile("resource/fonts/HanSrf.ttf")
	ix.util.AddResourceFile("resource/fonts/HanSrf.woff")
	ix.util.AddResourceFile("resource/fonts/lightout.ttf")
	ix.util.AddResourceFile("resource/fonts/lightout.woff")
end

-- We probably shouldn't be forcing these configs, but I have yet to look for another way to "recommend" them.
-- If anyone starts using this besides us, we should probably move this behind a command or something.
hook.Add("InitializedConfig", "expInitializedConfigWhyNotSooner", function()
	ix.config.Set("intro", false)
	ix.config.Set("music", "music/HL2_song26.mp3")
	ix.config.Set("maxAttributes", 100)
	ix.config.Set("communityURL", "")

	ix.config.Set("color", Color(160, 78, 69, 255))

	-- TODO: Check if players find this font hard to read.
	ix.config.Set("font", "Lights Out BRK")
	ix.config.Set("genericFont", "Handserif")

	-- We set this to a long time, so it's worth resurrecting someone -- TODO: or getting the perk that speeds up spawn time.
	ix.config.Set("spawnTime", 60)

	-- Make inventory management more bearable by increasing the size.
	ix.config.Set("inventoryWidth", 6)
	ix.config.Set("inventoryHeight", 6)

	-- Don't show descriptions of unrecognized characters.
	ix.config.Set("scoreboardRecognition", true)
end)

if (CLIENT) then
	ix.option.Add("accessibilityFont", ix.type.bool, false, {
		category = "appearance",
		OnChanged = function()
			hook.Run("LoadFonts", ix.config.Get("font"), ix.config.Get("genericFont"))
		end,
	})
	ix.option.Add("accessibilityFontScale", ix.type.number, 1, {
		category = "appearance",
		min = 0.5,
		max = 1.5,
		decimals = 2,
		OnChanged = function()
			hook.Run("LoadFonts", ix.config.Get("font"), ix.config.Get("genericFont"))
		end,
	})
end

ix.config.Add("breakFreeIntervalSeconds", 60,
	"After how many seconds does the player start getting chances to break free.", nil, {
		data = { min = 1, max = 600 },
		category = "restraints"
	})

ix.config.Add("breakFreeChancePercent", 5, "How likely a tied player is to get a chance to break free in percent.", nil,
	{
		data = { min = 1, max = 100 },
		category = "restraints"
	})

ix.config.Add("breakFreeMaxReactDuration", 1, "How long a tied player has to react to the break free prompt in seconds.",
	nil, {
		data = { min = 1, max = 10 },
		category = "restraints"
	})

ix.config.Add("allianceCost", 10000, "How much an alliance costs to create.", nil, {
	data = { min = 0, max = 1000000 },
	category = "alliances"
})

ix.config.Add("incomeMultiplier", 1, "The income multiplier for generators and salary", nil, {
	data = { min = 0, max = 100, decimals = 1 },
	category = "income"
})

ix.config.Add("generatorPayTime", 300, "How often generators pay out income in seconds.", function(oldValue, newValue)
	if (SERVER) then
		-- Go through all entities, check if IsBoltGenerator and set the payTimeInSeconds
		for _, entity in ipairs(ents.GetAll()) do
			if (not entity.IsBoltGenerator) then
				continue
			end

			local itemID = entity.expItemID
			local itemTable = itemID and ix.item.instances[itemID] or nil

			if (not itemTable) then
				continue
			end

			entity:SetupPayTimer(itemTable)
		end
	end
end, {
	data = { min = 1, max = 3600 },
	category = "income",
})

ix.config.Add("generatorPickupGracePeriod", 20,
	"How long after placing a generator it can be picked up without delay (in seconds).", nil, {
		data = { min = 0, max = 120 },
		category = "income",
	})

ix.config.Add("generatorPickupInterval", 30, "How long it takes to pick up a generator in seconds.", nil, {
	data = { min = 1, max = 60 },
	category = "income",
})

ix.config.Add("teleportGeneratorEarnings", false,
	"Wether income from generators should be teleported to the player. If not they'll have to get it from the generator manually.",
	nil, {
		category = "income"
	}
)

ix.config.Add("npcAnswerGracePeriod", 2,
	"How many seconds between answering an NPC and getting the next question.",
	nil, {
		data = { min = 0, max = 10 },
		category = "npc"
	}
)

Schema.armorAffectedTypes = DMG_BULLET + DMG_SLASH + DMG_CLUB

ix.config.Add("armorEffectiveness", 0.75,
	"How much damage armor will prevent, for example 0.75 will let a quarter of the damage through.", nil, {
		data = { min = 0, max = 1, decimals = 2 }
	})

ix.config.Add("beanbagRagdollDuration", 15, "How long players knocked out by beanbags will be ragdolled for.", nil, {
	data = { min = 0, max = 600 }
})

ix.config.Add("requiredGraceAfterDamage", 60,
	"How long after taking damage a player can disconnect without dropping everything.", nil, {
		data = { min = 0, max = 300 },
		category = "moderation"
	})

ix.config.Add("grenadeTrailsEnabled", true, "Whether or not grenades leave a colored trail behind them.", nil, {
	category = "grenades"
})

ix.config.Add("grenadeTrailColor", Color(255, 100, 0), "The color of the grenade trail.", nil, {
	category = "grenades"
})

ix.config.Add("grenadeTrailMaxLifetime", 10,
	"How long the grenade trail lasts for (-1 means for as long as the grenade exists).", nil, {
		data = { min = -1, max = 10, decimals = 0 },
		category = "grenades"
	})

ix.config.Add("maxInteractionDistance", 192, "How far away from the player an item/object can be placed.", nil, {
	data = { min = 128, max = math.huge, decimals = 0 },
})

ix.config.Add("strengthMultiplier", 0.3, "The strength multiplier scale", nil, {
	data = { min = 0, max = 1.0, decimals = 1 },
	category = "attributes"
})

Schema.hardCorpseMax = 64

ix.config.Add("corpseMax", 64, "Maximum number of corpses that are allowed to be spawned.", nil, {
	data = { min = 0, max = Schema.hardCorpseMax },
	category = "Persistent Corpses"
})

ix.config.Add("corpseDecayTime", 60, "How long it takes for a corpse to decay in seconds. Set to 0 to never decay.", nil,
	{
		data = { min = 0, max = 1800 },
		category = "Persistent Corpses"
	})

ix.config.Add("corpseSearchTime", 1, "How long it takes to search a corpse.", nil, {
	data = { min = 0, max = 60 },
	category = "Persistent Corpses"
})

ix.config.Add("dropItemsOnDeath", true, "Whether or not to drop specific items on death.", nil, {
	category = "Persistent Corpses"
})

Schema.util.ForceConVars({
	["cl_showhints"] = { isServer = false, value = false },
})
