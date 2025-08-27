local PLUGIN = PLUGIN

include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

-- Based on: Oil Pumps [Thumper] (https://steamcommunity.com/sharedfiles/filedetails/?id=3005727817)
-- Original Model by Renafox (https://sketchfab.com/3d-models/pump-jack-021faf828156426bb99a1cf87b5cefad)
function ENT:Initialize()
	self:SetModel("models/experiment-redux/big_oil_pump02.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	-- Initialize networked variables
	self:SetOwnerID(-1)
	self:SetOilAmount(0)
	self:SetScrapAmount(0)
	self:SetIsBroken(false)
	self:SetIsRunning(false)

	self:SetMaxHealth(1000)
	self:SetHealth(1000)

	-- Pump state
	self.lastCycle = CurTime()
	self.nextCycle = CurTime() + PLUGIN.pumpCycleTime

	-- Set up physics
	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:EnableMotion(false)
		phys:SetMass(1000)
	end

	-- Set initial animation speed to 0 (stopped)
	self:SetPlaybackRate(0)
end

function ENT:Think()
	local curTime = CurTime()

	-- Handle extraction cycle
	if (not self:GetIsBroken() and self:GetScrapAmount() > 0 and curTime >= self.nextCycle) then
		self:PerformExtractionCycle()
		self.nextCycle = curTime + PLUGIN.pumpCycleTime
	end

	-- Update running status
	local shouldBeRunning = not self:GetIsBroken() and self:GetScrapAmount() > 0 and
		self:GetOilAmount() < PLUGIN.pumpMaxCapacity

	if (shouldBeRunning ~= self:GetIsRunning()) then
		self:SetIsRunning(shouldBeRunning)
		self:UpdateAnimation()
	end
end

function ENT:UpdateAnimation()
	if (self:GetIsRunning()) then
		-- Set animation speed to normal when running
		self:SetPlaybackRate(1)
		self:ResetSequence("idle")
	else
		-- Stop animation when not running or broken
		self:SetPlaybackRate(0)
	end
end

function ENT:PerformExtractionCycle()
	if (self:GetIsBroken() or self:GetScrapAmount() <= 0) then
		return
	end

	local currentOil = self:GetOilAmount()
	local currentScrap = self:GetScrapAmount()

	-- Check if we can extract more oil
	if (currentOil >= PLUGIN.pumpMaxCapacity) then
		return -- Pump is full
	end

	-- Consume scrap
	self:SetScrapAmount(math.max(0, currentScrap - PLUGIN.scrapConsumption))

	-- Extract oil
	local extractedAmount = math.min(PLUGIN.pumpExtractionRate, PLUGIN.pumpMaxCapacity - currentOil)
	self:SetOilAmount(currentOil + extractedAmount)

	-- Create pumping effect
	local effectData = EffectData()
	effectData:SetOrigin(self:GetPos())
	effectData:SetScale(1)
	util.Effect("ThumperDust", effectData)

	-- Play pumping sound
	self:EmitSound("ambient/machines/thumper_hit.wav", 75, 100)
end

function ENT:OnTakeDamage(dmgInfo)
	if (self:GetIsBroken()) then
		return
	end

	local damage = dmgInfo:GetDamage()
	local newHealth = math.max(0, self:Health() - damage)
	self:SetHealth(newHealth)

	-- Break if health reaches 0
	if (newHealth <= 0) then
		self:Break()
	end

	return true
end

function ENT:Break()
	if (self:GetIsBroken()) then
		return
	end

	self:SetIsBroken(true)
	self:SetIsRunning(false)

	-- Stop the animation
	self:UpdateAnimation()

	-- Create break effect
	local explosion = EffectData()
	explosion:SetOrigin(self:GetPos())
	explosion:SetMagnitude(1)
	explosion:SetScale(0.5)
	util.Effect("Explosion", explosion)

	self:EmitSound("ambient/explosions/explode_4.wav", 100, 150)
end

function ENT:Repair()
	if (not self:GetIsBroken()) then
		return false
	end

	self:SetIsBroken(false)
	self:SetHealth(self:GetMaxHealth())

	-- Update animation based on current state
	self:UpdateAnimation()

	-- Create repair effect
	local effect = EffectData()
	effect:SetOrigin(self:GetPos())
	effect:SetMagnitude(1)
	util.Effect("TeleportSplash", effect)

	self:EmitSound("ambient/machines/combine_terminal_idle4.wav", 75, 120)

	return true
end

function ENT:AddScrap(amount)
	local currentScrap = self:GetScrapAmount()
	self:SetScrapAmount(currentScrap + amount)

	-- Update animation in case we just added scrap to start the pump
	self:UpdateAnimation()

	-- Create refuel effect
	local effectData = EffectData()
	effectData:SetOrigin(self:GetPos() + Vector(0, 0, 30))
	effectData:SetScale(0.5)
	util.Effect("Sparks", effectData)
end

function ENT:OnOptionSelected(client, option, data)
	if (option == L("oilPumpRepair", client)) then
		if (not self:GetIsBroken()) then
			client:Notify("Oil pump does not need repairs.")
			return
		end

		-- TODO: Add repair cost/requirements
		if (self:Repair()) then
			client:Notify("Oil pump repaired!")
		else
			client:Notify("Failed to repair oil pump.")
		end
	elseif (option == L("oilPumpAddScrap", client)) then
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		local scrapItem = inventory:HasItem("scrap")
		if (scrapItem) then
			scrapItem:Remove()
			self:AddScrap(1)
			client:Notify("Added scrap to the oil pump.")
		else
			client:Notify("You don't have any scrap.")
		end
	elseif (option == L("oilPumpExtractOilDrum", client)) then
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		local emptyDrum = inventory:HasItem("oil_drum_empty")
		if (emptyDrum) then
			local success, message = PLUGIN:ExtractOilFromPump(client, self, 500)
			if (success) then
				emptyDrum:Remove()
				inventory:Add("oil_drum_full")
				client:Notify("Filled oil drum with 500 liters of oil.")
			else
				client:Notify(message)
			end
		else
			client:Notify("You need an empty oil drum.")
		end
	elseif (option == L("oilPumpExtractGasCan", client)) then
		local character = client:GetCharacter()
		local inventory = character:GetInventory()

		local emptyCan = inventory:HasItem("gas_can_empty")
		if (emptyCan) then
			local success, message = PLUGIN:ExtractOilFromPump(client, self, 50)
			if (success) then
				emptyCan:Remove()
				inventory:Add("gas_can_full")
				client:Notify("Filled gas can with 50 liters of oil.")
			else
				client:Notify(message)
			end
		else
			client:Notify("You need an empty gas can.")
		end
	end
end
