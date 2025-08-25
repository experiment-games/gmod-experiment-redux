local PLUGIN = PLUGIN

util.AddNetworkString("expChemistryStationMenu")
util.AddNetworkString("expChemistryDistill")
util.AddNetworkString("expChemistryCombine")
util.AddNetworkString("expWorkbenchMenu")
util.AddNetworkString("expWorkbenchCombine")

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

net.Receive("expChemistryCombine", function(len, player)
	local station = net.ReadEntity()
	local selectedItemIDs = net.ReadTable()

	if (not IsValid(station) or station:GetClass() ~= "exp_chemistry_station") then
		return
	end

	-- Convert table to actual item instances
	local items = {}
	for _, itemID in ipairs(selectedItemIDs) do
		local item = ix.item.instances[itemID]
		if (item) then
			table.insert(items, item)
		end
	end

	local recipe = PLUGIN:FindValidRecipe(items)
	if (recipe) then
		if (station:StartCombination(player, items, recipe)) then
			player:Notify("Combination started!")
		else
			player:Notify("Cannot start combination.")
		end
	else
		player:Notify(L("invalidRecipe", player))
	end
end)

net.Receive("expWorkbenchCombine", function(len, player)
	local station = net.ReadEntity()
	local selectedItems = net.ReadTable()

	if (not IsValid(station) or station:GetClass() ~= "exp_workbench") then
		return
	end

	-- Convert table to actual item instances
	local items = {}
	for _, itemData in pairs(selectedItems) do
		local item = ix.item.instances[itemData.id]
		if (item) then
			table.insert(items, item)
		end
	end

	local recipe = PLUGIN:FindValidRecipe(items)
	if (recipe) then
		if (station:StartCombination(player, items, recipe)) then
			player:Notify("Crafting started!")
		else
			player:Notify("Cannot start crafting.")
		end
	else
		player:Notify(L("invalidRecipe", player))
	end
end)
