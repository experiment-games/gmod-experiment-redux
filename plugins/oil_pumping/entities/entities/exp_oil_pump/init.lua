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

	self:SetOwnerID(self:GetOwnerID() or -1)
	self:SetOilAmount(self:GetOilAmount() or 0)
	self:SetScrapAmount(self:GetScrapAmount() or 0)
	self:SetIsBroken(self:GetIsBroken() or false)
	self:SetIsRunning(self:GetIsRunning() or false)

	self:SetMaxHealth(1000)
	self:SetHealth(1000)

	self.lastCycle = CurTime()
	self.nextCycle = CurTime() + PLUGIN.pumpCycleTime

	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:EnableMotion(false)
		phys:SetMass(1000)
	end

	self:SetupAnimatedProp()
end

function ENT:SetupAnimatedProp()
	local pos = self:GetPos()
	local ang = self:GetAngles()

	self.animatedProp = ents.Create("prop_dynamic")
	self:SetAnimatedProp(self.animatedProp)

	self.animatedProp:SetModel(self:GetModel())
	self.animatedProp:SetPos(pos)
	self.animatedProp:SetAngles(ang)
	self.animatedProp:SetSolid(SOLID_VPHYSICS)
	self.animatedProp:Spawn()
	self.animatedProp:Activate()
	self.animatedProp:ResetSequence("idle")
	self.animatedProp:SetPlaybackRate(0)

	self.animatedProp:SetCollisionGroup(COLLISION_GROUP_NONE)
	self.animatedProp:SetParent(self)

	self.animatedProp:CallOnRemove("removeParent", function(entity)
		if (IsValid(self)) then
			self:Remove()
		end
	end)

	-- Hide original entity since we're using the animated prop for visuals
	self:SetNoDraw(true)
	self:SetNotSolid(true)

	-- Initialize easing variables
	self.targetPlaybackRate = 0
	self.currentPlaybackRate = 0
	self.easeStartTime = 0
	self.easeStartRate = 0
	self.easeDuration = 4.0
end

function ENT:Think()
	local curTime = CurTime()

	if (
			not self:GetIsBroken()
			and not self:GetIsDisabled()
			and self:GetScrapAmount() > 0
			and curTime >= self.nextCycle
		) then
		self:PerformExtractionCycle()
		self.nextCycle = curTime + PLUGIN.pumpCycleTime
	end

	local shouldBeRunning = not self:GetIsBroken()
		and self:GetScrapAmount() > 0
		and self:GetOilAmount() < PLUGIN.pumpMaxCapacity
		and not self:GetIsDisabled()

	if (shouldBeRunning ~= self:GetIsRunning()) then
		self:SetIsRunning(shouldBeRunning)
		self:UpdatePumpAnimation()
	end

	-- Handle playback rate easing
	self:UpdatePlaybackRateEasing()
end

function ENT:TransitionPlaybackRate(targetRate)
	if (not IsValid(self.animatedProp)) then
		return
	end

	self.targetPlaybackRate = targetRate
	self.easeStartTime = CurTime()
	self.easeStartRate = self.currentPlaybackRate
end

function ENT:UpdatePlaybackRateEasing()
	if (not IsValid(self.animatedProp)) then
		return
	end

	-- Check if we need to ease
	if (math.abs(self.currentPlaybackRate - self.targetPlaybackRate) < 0.01) then
		return
	end

	local curTime = CurTime()
	local elapsed = curTime - self.easeStartTime
	local progress = math.min(elapsed / self.easeDuration, 1.0)

	-- Ramp-up easing function (starts slow, accelerates toward target)
	local easedProgress = progress * progress

	self.currentPlaybackRate = Lerp(easedProgress, self.easeStartRate, self.targetPlaybackRate)
	self.animatedProp:SetPlaybackRate(self.currentPlaybackRate)
end

function ENT:UpdatePumpAnimation()
	if (not IsValid(self.animatedProp)) then
		return
	end

	if (self:GetIsRunning() and not self:GetIsBroken()) then
		self:TransitionPlaybackRate(1.0)
	else
		self:TransitionPlaybackRate(0.0)
	end
end

function ENT:PerformExtractionCycle()
	if (self:GetIsBroken() or self:GetScrapAmount() <= 0) then
		return
	end

	local currentOil = self:GetOilAmount()
	local currentScrap = self:GetScrapAmount()

	if (currentOil >= PLUGIN.pumpMaxCapacity) then
		return
	end

	self:SetScrapAmount(math.max(0, currentScrap - PLUGIN.scrapConsumption))

	local extractedAmount = math.min(PLUGIN.pumpExtractionRate, PLUGIN.pumpMaxCapacity - currentOil)
	self:SetOilAmount(currentOil + extractedAmount)

	local effectPos = self:GetPos()
	if (IsValid(self.animatedProp)) then
		effectPos = self.animatedProp:GetPos()
	end

	local effectData = EffectData()
	effectData:SetOrigin(effectPos)
	effectData:SetScale(1)
	util.Effect("ThumperDust", effectData)

	self:EmitSound("ambient/machines/thumper_hit.wav", 75, 100)
end

function ENT:OnTakeDamage(dmgInfo)
	if (self:GetIsBroken()) then
		return
	end

	local damage = dmgInfo:GetDamage()
	local newHealth = math.max(0, self:Health() - damage)
	self:SetHealth(newHealth)

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

	local effectPos = self:GetPos()
	if (IsValid(self.animatedProp)) then
		effectPos = self.animatedProp:GetPos()
	end

	local explosion = EffectData()
	explosion:SetOrigin(effectPos)
	explosion:SetMagnitude(1)
	explosion:SetScale(0.5)
	util.Effect("Explosion", explosion)

	self:EmitSound("ambient/explosions/explode_4.wav", 100, 150)

	-- Smoothly transition to stopped state
	self:TransitionPlaybackRate(0.0)
end

function ENT:Repair()
	if (not self:GetIsBroken()) then
		return false
	end

	self:SetIsBroken(false)
	self:SetHealth(self:GetMaxHealth())

	local effectPos = self:GetPos()
	if (IsValid(self.animatedProp)) then
		effectPos = self.animatedProp:GetPos()
	end

	local effect = EffectData()
	effect:SetOrigin(effectPos)
	effect:SetMagnitude(1)
	util.Effect("TeleportSplash", effect)

	self:EmitSound("ambient/machines/combine_terminal_idle4.wav", 75, 120)

	self:UpdatePumpAnimation()

	return true
end

function ENT:AddScrap(amount)
	local currentScrap = self:GetScrapAmount()
	local newScrapAmount = math.min(PLUGIN.maxScrap, currentScrap + amount)
	local added = newScrapAmount - currentScrap

	self:SetScrapAmount(newScrapAmount)

	-- Reset cycle timing if pump was empty and we just added scrap, otherwise
	-- it may be immediately consumed.
	if (currentScrap == 0 and added > 0) then
		self.nextCycle = CurTime() + PLUGIN.pumpCycleTime
	end

	local effectPos = self:GetPos() + Vector(0, 0, 30)
	if (IsValid(self.animatedProp)) then
		effectPos = self.animatedProp:GetPos() + Vector(0, 0, 30)
	end

	local effectData = EffectData()
	effectData:SetOrigin(effectPos)
	effectData:SetScale(0.5)
	util.Effect("Sparks", effectData)

	return added
end

function ENT:OnRemove()
	if (IsValid(self.animatedProp)) then
		self.animatedProp:Remove()
	end
end

function ENT:OnOptionSelected(client, option, data)
	if (option == L("oilPumpRepair", client)) then
		if (not self:GetIsBroken()) then
			client:Notify("Oil pump does not need repairs.")
			return
		end

		if (self:Repair()) then
			client:Notify("Oil pump repaired!")
		else
			client:Notify("Failed to repair oil pump.")
		end
	elseif (option == L("oilPumpAddScrap", client)) then
		local character = client:GetCharacter()
		local inventory = character:GetInventory()
		local ownedAmount = inventory:GetItemCount("scrap")

		if (ownedAmount > 0) then
			inventory:RemoveStackedItem("scrap", self:AddScrap(ownedAmount))

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
	elseif (option == L("oilPumpDisable", client)) then
		self:SetIsDisabled(true)
		client:Notify("Oil pump disabled.")
	elseif (option == L("oilPumpEnable", client)) then
		self.nextCycle = CurTime() + PLUGIN.pumpCycleTime
		self:SetIsDisabled(false)
		client:Notify("Oil pump enabled.")
	end
end
