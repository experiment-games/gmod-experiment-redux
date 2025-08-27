local PLUGIN = PLUGIN

PLUGIN.name = "Oil Pumps"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Adds oil pumps for extracting oil from oil fields."

-- Configuration
PLUGIN.pumpExtractionRate = 100 -- Oil extracted per cycle (liters)
PLUGIN.pumpMaxCapacity = 500    -- Maximum oil capacity (liters)
PLUGIN.pumpCycleTime = 60       -- Time between extraction cycles (seconds)
PLUGIN.scrapConsumption = 1     -- Scrap consumed per cycle

ix.util.Include("sv_plugin.lua")

ix.lang.AddTable("english", {
	oilPumpOwnerSelf = "Your Oil Pump",
	oilPumpOwnerName = "%s's Oil Pump",
	oilPumpOwnerTheBusiness = "The Business' Oil Pump",

	oilPumpStatus = "Status: %s",
	oilPumpOil = "Oil: %d/%d Liters",
	oilPumpScrap = "Scrap: %d",

	oilPumpRepair = "Repair Oil Pump",
	oilPumpAddScrap = "Add Scrap",
	oilPumpExtractOilDrum = "Extract Oil (Drum - 500L)",
	oilPumpExtractGasCan = "Extract Oil (Gas Can - 50L)",

	oilPumpStatusRunning = "Running",
	oilPumpStatusStopped = "Stopped",
	oilPumpStatusBroken = "Broken",
	oilPumpStatusNoScrap = "Out of Scrap",
})

--[[
    Helper Functions
--]]

function PLUGIN:CanSpawnOilPump(trace)
	return trace.Hit
		and not trace.HitSky
		and self:IsValidOilField(trace.HitPos)
end

function PLUGIN:IsValidOilField(position)
	if (true) then
		-- TODO: Remove once we add resource areas for oil
		return true
	end

	local triggers = ents.FindInSphere(position, 512)

	for _, trigger in ipairs(triggers) do
		if (IsValid(trigger) and trigger:GetClass() == "exp_resource_area") then
			local mins, maxs = trigger:GetCollisionBounds()
			local triggerMins = trigger:GetPos() + mins
			local triggerMaxs = trigger:GetPos() + maxs

			-- Check if position is inside trigger bounds
			if (position.x >= triggerMins.x and position.x <= triggerMaxs.x and
					position.y >= triggerMins.y and position.y <= triggerMaxs.y and
					position.z >= triggerMins.z and position.z <= triggerMaxs.z) then
				if (trigger:GetResourceTypeID() == "oil") then
					return true
				end
			end
		end
	end

	return false
end

--[[
    Hooks
--]]

function PLUGIN:CanPlayerUseBusiness(client, uniqueID)
	local itemTable = ix.item.list[uniqueID]

	-- TODO:
	-- if (itemTable.requiresOilPerk and not Schema.perk.GetOwned("oil_rigger", client)) then
	-- 	return false
	-- end
end

--[[
    Commands
--]]

do
	local COMMAND = {}

	COMMAND.description = "Spawn an oil pump."
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client)
		local trace = client:GetEyeTraceNoCursor()

		if (not PLUGIN:CanSpawnOilPump(trace)) then
			client:Notify("Cannot spawn an oil pump here. Must be on flat ground in an oil field.")
			return
		end

		local character = client:GetCharacter()
		local ownerID = character and character:GetID() or -1
		local entity = PLUGIN:SpawnOilPump(trace.HitPos, client:EyeAngles(), ownerID)

		client:Notify("You have spawned an oil pump.")
	end

	ix.command.Add("OilPumpSpawn", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Remove an oil pump you are looking at or all within a range."
	COMMAND.arguments = {
		bit.bor(ix.type.number, ix.type.optional)
	}
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, range)
		if (range) then
			local removed = 0

			for _, ent in ipairs(ents.FindInSphere(client:GetPos(), range)) do
				if (IsValid(ent) and ent:GetClass() == "exp_oil_pump") then
					ent:Remove()
					removed = removed + 1
				end
			end

			client:Notify("Removed " .. removed .. " oil pump(s) within range " .. range .. ".")

			return
		end

		local trace = client:GetEyeTraceNoCursor()
		local entity = trace.Entity

		if (not IsValid(entity) or entity:GetClass() ~= "exp_oil_pump") then
			client:Notify("You are not looking at a valid oil pump.")
			return
		end

		entity:Remove()
		client:Notify("You have removed an oil pump.")
	end

	ix.command.Add("OilPumpRemove", COMMAND)
end
