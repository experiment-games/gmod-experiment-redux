local PLUGIN = PLUGIN

PLUGIN.name = "Defensive NPC's"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Let super admins spawn defensive NPC's."

-- Configuration
PLUGIN.turretDetectionRange = 500 -- Range to detect hostile activity
PLUGIN.turretTypes = {
	["ceiling"] = function(trace)
		-- The hitnormal Z must be around -1 to ensure it's a ceiling turret
		return trace.Hit and not trace.HitSky and trace.HitNormal.z < -0.9
	end,

	["floor"] = function(trace)
		-- Check if the player can spawn a floor turret here
		return trace.Hit and not trace.HitSky and trace.HitNormal.z > 0
	end,
}

PLUGIN.TURRET_MODES = {
	-- Turret is disabled
	DISABLED = 0,
	-- Default behavior - defend against hostile activity
	DEFEND_ALL = 1,
	-- Only defend when owner is attacked
	DEFEND_OWNER = 2,
	-- Only defend alliance members
	DEFEND_ALLIANCE = 3,
	-- Attack anyone except owner
	DEFEND_AREA_OWNER = 4,
	-- Attack anyone not in owner's alliance
	DEFEND_AREA_ALLIANCE = 5
}

ix.util.Include("sv_plugin.lua")

ix.lang.AddTable("english", {
	turretOwnerSelf = "Your Turret",
	turretOwnerName = "%s's Turret",
	turretOwnerTheBusiness = "The Business' Turret",

	turretHealth = "Health: ",
	turretMode = "Mode: %s",

	turretRepair = "Repair Turret",

	-- Turret mode options
	turretModeDisable = "Disable Turret",
	turretModeDefendAll = "Defend All",
	turretModeDefendOwner = "Defend Owner Only",
	turretModeDefendAlliance = "Defend Alliance Members",
	turretModeDefendAreaOwner = "Attack All Except Owner",
	turretModeDefendAreaAlliance = "Attack All Except Alliance Members",
})

--- Checks if a turret of this type can be spawned at the given trace
--- @param turretType string
--- @param trace TraceResult
--- @return boolean
function PLUGIN:CanSpawnTurret(turretType, trace)
	local canSpawn = PLUGIN.turretTypes[turretType]

	return canSpawn and canSpawn(trace)
end

--[[
	Hooks
--]]

function PLUGIN:CanPlayerUseBusiness(client, uniqueID)
	local itemTable = ix.item.list[uniqueID]

	if (itemTable.requiresDefensivePerk and not Schema.perk.GetOwned("fortress_rights", client)) then
		return false
	end
end

--[[
	Commands
--]]

do
	local COMMAND = {}

	COMMAND.description = "Spawn a defensive NPC."
	COMMAND.arguments = {
		bit.bor(ix.type.string, ix.type.optional),
	}

	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, turretType)
		turretType = turretType or "floor"

		local trace = client:GetEyeTraceNoCursor()

		if (not PLUGIN:CanSpawnTurret(turretType, trace)) then
			client:Notify("Cannot spawn a " .. turretType .. " defensive NPC here.")
			return
		end

		local facingAwayFromPlayerUpright = Angle(0, client:EyeAngles().y, 0)
		local character = client:GetCharacter()
		local ownerID = character and character:GetID() or -1
		local entity = PLUGIN:SpawnTurret(turretType, trace.HitPos, facingAwayFromPlayerUpright, ownerID)

		client:Notify("You have spawned a defensive turret (" .. turretType .. ").")
	end

	ix.command.Add("DefensiveNpcSpawn", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Remove a defensive NPC you are looking at or all within a range."
	COMMAND.arguments = {
		bit.bor(ix.type.number, ix.type.optional)
	}
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, range)
		if (range) then
			local removed = 0

			for _, ent in ipairs(ents.FindInSphere(client:GetPos(), range)) do
				if (IsValid(ent) and ent:GetClass() == "exp_turret") then
					ent:Remove()
					removed = removed + 1
				end
			end

			client:Notify("Removed " .. removed .. " turret(s) within range " .. range .. ".")

			return
		end

		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		if (not IsValid(entity) or entity:GetClass() ~= "exp_turret") then
			client:Notify("You are not looking at a valid defensive NPC.")
			return
		end

		entity:Remove()
		client:Notify("You have removed a defensive NPC.")
	end

	ix.command.Add("DefensiveNpcRemove", COMMAND)
end
