local PLUGIN = PLUGIN

PLUGIN.name = "Crafting"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Adds crafting mechanics including distillation and combination recipes."

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")

if (SERVER) then
	-- Fallout: New Vegas - Crafting Station Props (steamcommunity.com/sharedfiles/filedetails/?id=1906251322)
	resource.AddWorkshop("1906251322")

	ix.util.AddResourceFile("materials/experiment-redux/icons/chemistry.png")
	ix.util.AddResourceFile("materials/experiment-redux/icons/workbench.png")
	ix.util.AddResourceFile("materials/experiment-redux/icons/distill.png")
	ix.util.AddResourceFile("materials/experiment-redux/icons/combine.png")
end

ix.lang.AddTable("english", {
	chemistryStation = "Chemistry Station",
	workbench = "Workbench",
	distilling = "Distilling...",
	combining = "Combining...",
	distillationComplete = "Distillation Complete!",
	combinationComplete = "Combination Complete!",
	noValidItems = "No valid items for this operation.",
	invalidRecipe = "Invalid recipe combination.",
	missingComponents = "Missing required components.",
	stationInUse = "Station is currently in use.",
	selectItems = "Select Items",
	startDistillation = "Start Distillation",
	startCombination = "Start Combination",
	retrieveItems = "Retrieve Items",
})

-- Track active distillations and combinations
PLUGIN.activeProcesses = PLUGIN.activeProcesses or {}

function PLUGIN:GetDistillableItems(inventory)
	local items = {}

	for _, item in pairs(inventory:GetItems()) do
		if (item.craftingDistillation) then
			table.insert(items, item)
		end
	end

	return items
end

function PLUGIN:GetCombinationRecipes()
	local recipes = {}

	for _, item in pairs(ix.item.list) do
		if (item.craftingCombination) then
			table.insert(recipes, item)
		end
	end

	return recipes
end

function PLUGIN:FindValidRecipe(selectedItems)
	local recipes = self:GetCombinationRecipes()

	for _, recipe in pairs(recipes) do
		if (self:CanCraftRecipe(recipe, selectedItems)) then
			return recipe
		end
	end

	return nil
end

function PLUGIN:CanCraftRecipe(recipe, selectedItems)
	local components = recipe.craftingCombination.components
	local itemCounts = {}

	-- Count selected items
	for _, item in pairs(selectedItems) do
		local uniqueID = item.uniqueID

		itemCounts[uniqueID] = (itemCounts[uniqueID] or 0) + 1
	end

	-- Check if we have enough components
	for componentID, required in pairs(components) do
		local available = itemCounts[componentID] or 0

		if (available < required) then
			return false
		end
	end

	return true
end

function PLUGIN:ProcessDistillation(stationID, itemID, playerID)
	local item = ix.item.instances[itemID]
	local player = Player(playerID)

	if (not item or not IsValid(player)) then
		return
	end

	local distillation = item.craftingDistillation
	if (not distillation) then
		return
	end

	-- Store process info
	self.activeProcesses[stationID] = {
		type = "distillation",
		startTime = CurTime(),
		duration = distillation.time,
		playerID = playerID,
		itemID = itemID,
		output = distillation.output
	}

	-- Remove the item from inventory
	item:Remove()

	-- Set timer for completion
	timer.Create("crafting_distillation_" .. stationID, distillation.time, 1, function()
		self:CompleteDistillation(stationID)
	end)
end

function PLUGIN:CompleteDistillation(stationID)
	local process = self.activeProcesses[stationID]

	if (not process) then
		return
	end

	local player = Player(process.playerID)

	if (not IsValid(player)) then
		self.activeProcesses[stationID] = nil

		return
	end

	local character = player:GetCharacter()
	local inventory = character:GetInventory()

	if (not inventory) then
		self.activeProcesses[stationID] = nil

		return
	end

	-- Give output items
	for outputID, amount in pairs(process.output) do
		local count = amount

		-- Handle random amounts
		if (type(amount) == "table") then
			count = math.random(amount[1], amount[2])
		end

		for i = 1, count do
			inventory:Add(outputID)
		end
	end

	player:Notify(L("distillationComplete", player))

	-- Mark process as complete for retrieval
	process.completed = true
end

function PLUGIN:ProcessCombination(stationID, selectedItems, recipe, playerID)
	local player = Player(playerID)

	if (not IsValid(player) or not recipe) then
		return
	end

	-- Store process info
	self.activeProcesses[stationID] = {
		type = "combination",
		startTime = CurTime(),
		duration = recipe.craftingTime or 30, -- Default 30 seconds
		playerID = playerID,
		recipe = recipe,
		selectedItems = selectedItems
	}

	-- Remove component items from inventory
	for _, item in pairs(selectedItems) do
		item:Remove()
	end

	-- Set timer for completion
	timer.Create("crafting_combination_" .. stationID, recipe.craftingTime or 30, 1, function()
		self:CompleteCombination(stationID)
	end)
end

function PLUGIN:CompleteCombination(stationID)
	local process = self.activeProcesses[stationID]

	if (not process) then
		return
	end

	local player = Player(process.playerID)

	if (not IsValid(player)) then
		self.activeProcesses[stationID] = nil

		return
	end

	local character = player:GetCharacter()
	local inventory = character:GetInventory()

	if (not inventory) then
		self.activeProcesses[stationID] = nil

		return
	end

	local recipe = process.recipe
	local output = recipe.craftingCombination.output

	-- Create output items
	for outputID, amount in pairs(output) do
		for i = 1, amount do
			local item = inventory:Add(outputID)

			-- Call recipe's output function if it exists
			if (recipe.OnCraftingOutput and item) then
				recipe:OnCraftingOutput(item)
			end
		end
	end

	player:Notify(L("combinationComplete", player))

	-- Mark process as complete for retrieval
	process.completed = true
end

function PLUGIN:GetStationProcess(stationID)
	return self.activeProcesses[stationID]
end

function PLUGIN:IsStationBusy(stationID)
	local process = self.activeProcesses[stationID]

	return process and not process.completed
end

function PLUGIN:CompleteStationProcess(stationID)
	local process = self.activeProcesses[stationID]

	if (process and process.completed) then
		self.activeProcesses[stationID] = nil
		return true
	end

	return false
end
