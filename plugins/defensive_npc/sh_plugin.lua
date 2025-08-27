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

ix.util.Include("sv_plugin.lua")

ix.lang.AddTable("english", {
	turretOwnerSelf = "Your Turret",
	turretOwnerName = "%s's Turret",
	turretOwnerTheBusiness = "The Business' Turret",

	turretHealth = "Health: ",
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
		local entity = PLUGIN:SpawnTurret(turretType, trace.HitPos, facingAwayFromPlayerUpright)

		client:Notify("You have spawned a defensive turret (" .. turretType .. ").")
	end

	ix.command.Add("DefensiveNpcSpawn", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Remove a defensive NPC you are looking at."

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
