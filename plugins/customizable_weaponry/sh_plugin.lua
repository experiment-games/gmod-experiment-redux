--[[
	Based on PLUGIN: https://steamcommunity.com/sharedfiles/filedetails/?id=2588031232

	Copied credits from that Workshop listing:
	- 8Z: Weapon balance, post-launch features, extra weapons.
	- speedonerd: Model edits and various contributions.
	- Fesiug: Attachment highlight display.
	- Arqu: Animations for Riot Shield.
	- FIXGames Korea: Tactical Intervention
	- Minh "Gooseman" Le: Original animator
	- Arctic: Laying the foundations

	We copied over this addon and the weapons, such that we can remove any unwanted features and prevent the
	author from updating the addon and breaking our schema. This version is a fork from the version that
	was on the Steam Workshop @ 25-5-2024.
--]]
local PLUGIN = PLUGIN

PLUGIN.name = "Customizable Weaponry"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Adds the Customizable Weaponry to the schema."

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")

local conVarsToSet = {
	["tacrp_hud"] = { isServer = true, value = false },
	["tacrp_drawhud"] = { isServer = false, value = false },
	["tacrp_shutup"] = { isServer = false, value = true },
	["tacrp_hints"] = { isServer = false, value = false },

	-- Note that without setting this to false the server errors in PLUGIN.LoadAtt.
	-- This is because Material("*.png") fails to load on the server
	-- See https://wiki.facepunch.com/gmod/Global.Material#description
	["tacrp_generateattentities"] = { isServer = true, value = false },

	-- Balance recoil, damage and other features
	["tacrp_mult_recoil_kick"] = { isServer = true, value = 0.75 },
	["tacrp_mult_recoil_vis"] = { isServer = true, value = 0.85 },
	["tacrp_sway"] = { isServer = true, value = false },          -- false disables: Weapon point of aim will move around gently. While aiming, hold sprint key to hold breath and steady aim
	["tacrp_freeaim"] = { isServer = true, value = false },       -- false disables: While not aiming, moving around will cause the crosshair to move off center
	["tacrp_autoreload"] = { isServer = false, value = true },
	["tacrp_flashlight_blind"] = { isServer = true, value = false }, -- false disables the blinding glare growing, the hook.Remove for TacRP_TranslucentDraw actually fully disables its functionality. We manually re-enable lasers in PostDrawTranslucentRenderables

	["tacrp_autosave"] = { isServer = false, value = false },     -- Prevents TacRP's SWEP:LoadPreset from being called and wiping attachments we add
	-- ["tacrp_physbullet"] = false, -- false disables: Bullets will be hitscan up to a certain range depending on muzzle velocity
	-- ["tacrp_recoilpattern"] = false,
	-- ["tacrp_altrecoil"] = false, -- false disables: If enabled, gaining bloom intensifies recoil but does not modify spread.\nIf disabled, gaining bloom increases spread but does not modify recoil kick (old behavior).\nBloom is gained when firing consecutive shots.
	-- ["tacrp_mult_damage"] = 0.5,
	-- ["tacrp_mult_damage_magnum"] = 0.8,
	-- ["tacrp_mult_damage_sniper"] = 0.8,
	-- ["tacrp_mult_damage_shotgun"] = 0.8,
	-- ["tacrp_mult_damage_explosive"] = 0.5,
	-- ["tacrp_penalty_reload"] = false,
	-- ["tacrp_penalty_melee"] = false,
}

Schema.util.ForceConVars(conVarsToSet)

PLUGIN.compatibleItemsLookup = PLUGIN.compatibleItemsLookup or {}

function PLUGIN:GetCompatibleItems(attachmentId)
	local attachment = PLUGIN.GetAttTable(attachmentId)
	local categories = istable(attachment.Category) and attachment.Category or { attachment.Category }
	local compatibleItems = {}

	for _, category in ipairs(categories) do
		local items = self.compatibleItemsLookup[category]

		if (items) then
			for _, item in ipairs(items) do
				compatibleItems[item.uniqueID] = item
			end
		end
	end

	return compatibleItems
end

function PLUGIN:InitializedPlugins()
	local items = ix.item.list

	for _, item in pairs(items) do
		if (item.base ~= "base_customizable_weaponry") then
			continue
		end

		local swep = weapons.Get(item.class)

		if (not swep or not swep.Attachments) then
			continue
		end

		for attachmentSlotId, attachmentSlot in pairs(swep.Attachments) do
			local categories = istable(attachmentSlot.Category) and attachmentSlot.Category or
				{ attachmentSlot.Category }

			for _, category in ipairs(categories) do
				if (not self.compatibleItemsLookup[category]) then
					self.compatibleItemsLookup[category] = {}
				end

				local newIndex = #self.compatibleItemsLookup[category] + 1
				self.compatibleItemsLookup[category][newIndex] = item
			end
		end
	end
end

do
	local COMMAND = {}

	COMMAND.description = "(DEBUG) Spawns an NPC to test weapon damage."
	COMMAND.arguments = {
		bit.bor(ix.type.number, ix.type.optional),
	}

	function COMMAND:OnRun(client, health)
		if (IsValid(client.expDebugDamageNpc)) then
			client.expDebugDamageNpc:Remove()
			client.expDebugDamageNpc = nil
		end

		health = health or 100

		if (health <= 0) then
			client:Notify("Invalid health value, must be greater than 0.")
			return
		end

		local trace = client:GetEyeTraceNoCursor()

		if (trace.HitPos:DistToSqr(client:GetPos()) > 512 ^ 2) then
			client:Notify("You are too far away to spawn an NPC.")
			return
		end

		-- Spawn the NPC
		local npc = ents.Create("npc_citizen")
		npc:SetPos(trace.HitPos)
		npc:SetAngles(Angle(0, client:EyeAngles().y, 0))
		npc:Spawn()
		npc:CapabilitiesClear()
		npc:SetHealth(health)

		client.expDebugDamageNpc = npc

		client:Notify("You have spawned an NPC to test weapon damage.")
	end

	ix.command.Add("DebugDamageNpcSpawn", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "(DEBUG) Remove the NPC spawned for weapon damage testing."

	function COMMAND:OnRun(client)
		if (not IsValid(client.expDebugDamageNpc)) then
			client:Notify("There is no NPC to remove.")
			return
		end

		client.expDebugDamageNpc:Remove()
		client.expDebugDamageNpc = nil
	end

	ix.command.Add("DebugDamageNpcRemove", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "(DEBUG) Gives you all weapons that exist for damage testing."

	function COMMAND:OnRun(client)
		local weapons = {}

		for _, item in pairs(ix.item.list) do
			if (item.base == "base_customizable_weaponry"
					or item.base == "base_weapons") then
				table.insert(weapons, item)
			end
		end

		if (#weapons == 0) then
			client:Notify("There are no weapons available for damage testing.")
			return
		end

		for _, weaponItem in ipairs(weapons) do
			client:Give(weaponItem.class)
		end

		client:Notify("You have been given " .. tostring(#weapons) .. " weapons for damage testing.")
	end

	ix.command.Add("DebugDamageAllWeapons", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "(DEBUG) Gives you ammo for all weapons that you have on you."

	function COMMAND:OnRun(client)
		local totalPrimaryAmmoCount = 0

		for _, weapon in ipairs(client:GetWeapons()) do
			if (not IsValid(weapon) or not weapon:IsWeapon()) then
				continue
			end

			local primaryAmmoType = weapon:GetPrimaryAmmoType()

			if (primaryAmmoType > -1) then
				local primaryAmmoCount = weapon:GetMaxClip1()
				client:GiveAmmo(primaryAmmoCount, primaryAmmoType, true)
				totalPrimaryAmmoCount = totalPrimaryAmmoCount + primaryAmmoCount
			end
		end

		client:Notify(
			"You have been given " .. totalPrimaryAmmoCount
			.. " rounds of primary ammo in total for all weapons you have on you."
		)
	end

	ix.command.Add("DebugDamageRefillAmmo", COMMAND)
end
