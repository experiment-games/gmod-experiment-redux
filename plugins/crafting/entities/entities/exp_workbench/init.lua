local PLUGIN = PLUGIN

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/mosi/fnv/props/workstations/reloadingbench.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:Wake()
		phys:EnableMotion(false)
	end

	self.stationID = self:EntIndex()
end

function ENT:OnOptionSelected(client, option, data)
	if (option == "Retrieve Items") then
		local process = PLUGIN:GetStationProcess(self.stationID)

		if (process and process.completed) then
			local character = client:GetCharacter()
			local inventory = character:GetInventory()
			local recipe = process.recipe
			local output = recipe.craftingCombination.output

			-- Create output items
			for outputID, amount in pairs(output) do
				for i = 1, amount do
					local data

					-- Call recipe's output function if it exists
					if (recipe.GetCraftingOutputData) then
						data = recipe:GetCraftingOutputData(outputID)
					end

					PrintTable(data)

					inventory:Add(outputID, 1, data)
				end
			end

			client:Notify(L("combinationComplete", client))

			PLUGIN:CompleteStationProcess(self.stationID)
			self:SetInUse(false)
		else
			client:Notify("No items to retrieve.")
		end
	elseif (option == "Combine Items") then
		if (PLUGIN:IsStationBusy(self.stationID)) then
			client:Notify(L("stationInUse", client))
			return
		end

		-- Send network message to client to open combination selector
		net.Start("expOpenCombinationSelector")
		net.WriteEntity(self)
		net.Send(client)
	end
end

function ENT:StartCombination(player, selectedItems, recipe)
	if (PLUGIN:IsStationBusy(self.stationID)) then
		return false
	end

	self:SetInUse(true)
	self:SetProcessStartTime(CurTime())
	self:SetProcessDuration(recipe.craftingTime or 45) -- Workbench takes longer

	PLUGIN:ProcessCombination(self.stationID, selectedItems, recipe, player:UserID())
	return true
end
