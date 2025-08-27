local PLUGIN = PLUGIN

PLUGIN.name = "Oil Pumps"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Adds oil pumps for extracting oil from oil fields."


--- Oil extracted per cycle (liters)
PLUGIN.pumpExtractionRate = 100

--- Maximum oil capacity (liters)
PLUGIN.pumpMaxCapacity = 500

--- Time between extraction cycles (seconds)
PLUGIN.pumpCycleTime = 60

--- Scrap consumed per cycle
PLUGIN.scrapConsumption = 1

--- Max scrap that can be loaded into the pump
PLUGIN.maxScrap = 10

ix.util.Include("sv_plugin.lua")

ix.lang.AddTable("english", {
	oilPumpOwnerSelf = "Your Oil Pump",
	oilPumpOwnerName = "%s's Oil Pump",
	oilPumpOwnerTheBusiness = "The Business' Oil Pump",

	oilPumpStatus = "Status: %s",
	oilPumpOil = "Oil: %d/%d Liters",
	oilPumpScrap = "Scrap: %d / %d",

	oilPumpEnable = "Enable Oil Pump",
	oilPumpDisable = "Disable Oil Pump",

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
