local PLUGIN = PLUGIN

util.AddNetworkString("expOpenDistillationSelector")
util.AddNetworkString("expOpenCombinationSelector")
util.AddNetworkString("expChemistryDistill")
util.AddNetworkString("expCraftingCombine")

-- Fallout: New Vegas - Crafting Station Props (steamcommunity.com/sharedfiles/filedetails/?id=1906251322)
resource.AddWorkshop("1906251322")

ix.util.AddResourceFile("materials/experiment-redux/icons/chemistry.png")
ix.util.AddResourceFile("materials/experiment-redux/icons/workbench.png")
ix.util.AddResourceFile("materials/experiment-redux/icons/distill.png")
ix.util.AddResourceFile("materials/experiment-redux/icons/combine.png")

ix.util.AddResourceFile("materials/experiment-redux/illustrations/distillation.png")
ix.util.AddResourceFile("materials/experiment-redux/illustrations/combination.png")

--[[
	Hooks
--]]

--- Clean up timers when entities are removed
function PLUGIN:EntityRemoved(entity)
	if (entity:GetClass() == "exp_chemistry_station" or entity:GetClass() == "exp_workbench") then
		local stationID = entity:EntIndex()
		timer.Remove("crafting_distillation_" .. stationID)
		timer.Remove("crafting_combination_" .. stationID)
		PLUGIN.activeProcesses[stationID] = nil
	end
end

--[[
	Net Messages
--]]

net.Receive("expChemistryDistill", function(len, player)
	local station = net.ReadEntity()
	local itemID = net.ReadUInt(32)

	if (not IsValid(station) or station:GetClass() ~= "exp_chemistry_station") then
		return
	end

	if (station:StartDistillation(player, itemID)) then
		player:Notify("Distillation started!")
	else
		player:Notify("Cannot start distillation.")
	end
end)

net.Receive("expCraftingCombine", function(len, client)
	local station = net.ReadEntity()
	local selectedItemIDs = net.ReadTable()

	-- Convert table to actual item instances
	local items = {}

	for _, itemID in ipairs(selectedItemIDs) do
		local item = ix.item.instances[itemID]
		if (item) then
			table.insert(items, item)
		end
	end

	local recipe = PLUGIN:FindValidRecipe(station, items)

	if (recipe) then
		if (station:StartCombination(client, items, recipe)) then
			client:Notify("Successfully started brewing!")
			Schema.PlayerClearEntityInfoTooltip(client, station)
		else
			client:Notify("Cannot start combination.")
		end
	else
		client:Notify(L("invalidRecipe", client))
	end
end)
