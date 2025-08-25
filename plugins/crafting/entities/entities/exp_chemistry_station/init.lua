local PLUGIN = PLUGIN

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/mosi/fnv/props/workstations/chemistrylab.mdl")
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

			client:Notify(L("distillationComplete", client))

			PLUGIN:CompleteStationProcess(self.stationID)
			self:SetInUse(false)
		else
			client:Notify("No items to retrieve.")
		end
	elseif (option == "Distill Items") then
		if (PLUGIN:IsStationBusy(self.stationID)) then
			client:Notify(L("stationInUse", client))
			return
		end

		-- Send network message to client to open distillation selector
		net.Start("expOpenDistillationSelector")
		net.WriteEntity(self)
		net.Send(client)
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

function ENT:StartDistillation(player, itemID)
	if (PLUGIN:IsStationBusy(self.stationID)) then
		return false
	end

	local item = ix.item.instances[itemID]
	if (not item or not item.craftingDistillation) then
		return false
	end

	self:SetInUse(true)
	self:SetProcessType("distillation")
	self:SetProcessStartTime(CurTime())
	self:SetProcessDuration(item.craftingDistillation.time)

	PLUGIN:ProcessDistillation(self.stationID, itemID, player:UserID())
	return true
end

function ENT:StartCombination(player, selectedItems, recipe)
	if (PLUGIN:IsStationBusy(self.stationID)) then
		return false
	end

	self:SetInUse(true)
	self:SetProcessType("combination")
	self:SetProcessStartTime(CurTime())
	self:SetProcessDuration(recipe.craftingTime or 30)

	PLUGIN:ProcessCombination(self.stationID, selectedItems, recipe, player:UserID())
	return true
end
