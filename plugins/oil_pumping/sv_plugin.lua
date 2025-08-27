local PLUGIN = PLUGIN

-- Store active oil pumps for efficient lookup
PLUGIN.activeOilPumps = PLUGIN.activeOilPumps or {}

function PLUGIN:SpawnOilPump(position, angles, ownerID)
	local entity = ents.Create("exp_oil_pump")
	entity:SetPos(position)
	entity:SetAngles(angles)
	entity:SetOwnerID(ownerID or -1)
	entity:Spawn()
	entity:Activate()

	-- Add to our tracking list
	table.insert(self.activeOilPumps, entity)

	return entity
end

-- Clean up pump tracking when entities are removed
function PLUGIN:EntityRemoved(entity)
	if (entity:GetClass() == "exp_oil_pump") then
		for i = #self.activeOilPumps, 1, -1 do
			if (self.activeOilPumps[i] == entity) then
				table.remove(self.activeOilPumps, i)
				break
			end
		end
	end
end

-- Utility function to get all oil pumps in range of a position
function PLUGIN:GetOilPumpsInRange(position, range)
	local nearbyPumps = {}
	range = range or 1000

	for _, pump in ipairs(self.activeOilPumps) do
		if (IsValid(pump) and not pump:GetIsBroken()) then
			if (pump:GetPos():Distance(position) <= range) then
				table.insert(nearbyPumps, pump)
			end
		end
	end

	return nearbyPumps
end

-- Hook for handling oil extraction with containers
function PLUGIN:ExtractOilFromPump(client, pump, extractAmount)
	if (not IsValid(pump) or pump:GetClass() ~= "exp_oil_pump") then
		return false, "Invalid oil pump."
	end

	if (not pump:IsOwner(client)) then
		return false, "You are not the owner of this oil pump."
	end

	if (pump:GetIsBroken()) then
		return false, "This oil pump is broken and needs repair."
	end

	local currentOil = pump:GetOilAmount()

	if (currentOil < extractAmount) then
		return false, string.format("Not enough oil. Pump has %d liters, need %d liters.", currentOil, extractAmount)
	end

	-- Extract the oil
	pump:SetOilAmount(currentOil - extractAmount)

	return true, string.format("Extracted %d liters of oil.", extractAmount)
end
