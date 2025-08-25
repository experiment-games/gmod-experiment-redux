--[[
	This is copied from the Helix Ammo Base so we can set the base of this to be stackable.
	That way single bullets can be stacked together.

	We also don't draw the ammo count, since that equals the stack count.
--]]

ITEM.base = "base_stackable"
ITEM.name = "Ammo Stackable Base"
ITEM.model = "models/Items/BoxSRounds.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.ammo = "pistol" -- type of the ammo
ITEM.description = "A pile that contains %s of Pistol Ammo"
ITEM.category = "Ammunition"
ITEM.useSound = "items/ammo_pickup.wav"

-- We shouldn't allow too large piles, or they would become too powerful compared to ammo containers.
ITEM.maxStacks = 20

function ITEM:GetDescription()
	local ammoAmount = self:GetData("stacks", 1)
	return Format(self.description, ammoAmount)
end

function ITEM:GetName()
	if (self:GetData("poisoned")) then
		return "Poisoned " .. self.name
	elseif (self:GetData("explosive")) then
		return "Explosive " .. self.name
	end

	return self.name
end

-- On player uneqipped the item, Removes a weapon from the player and keep the ammo in the item.
ITEM.functions.use = {
	name = "Load",
	tip = "useTip",
	icon = "icon16/add.png",
	OnRun = function(item)
		local ammoAmount = item:GetData("stacks", 1)

		local callback

		if (item:GetData("poisoned")) then
			local poisonDamage = item:GetData("poisonDamage") or 5
			local poisonDuration = item:GetData("poisonDuration") or 10

			callback = function(client, weapon, ammoType, bulletData)
				local target = bulletData.Trace.Entity

				if (IsValid(target)) then
					-- TODO: Apply poison nano debuff instead of this manual application
					local timerName = "PoisonDamage_" .. target:EntIndex() .. "#" .. client:EntIndex()

					timer.Create(timerName, 1, poisonDuration, function()
						if (IsValid(target) and target:Health() > 0) then
							local dmgInfo = DamageInfo()
							dmgInfo:SetDamage(poisonDamage)
							dmgInfo:SetAttacker(client)

							if (IsValid(weapon)) then
								dmgInfo:SetInflictor(weapon)
							end

							dmgInfo:SetDamageType(DMG_NERVEGAS)

							target:TakeDamageInfo(dmgInfo)
						else
							timer.Remove(timerName)
						end
					end)
				end
			end
		elseif (item:GetData("explosive")) then
			local blastRadius = item:GetData("blastRadius") or 200
			local blastDamage = item:GetData("blastDamage") or 50

			callback = function(client, weapon, ammoType, bulletData)
				local trace = bulletData.Trace

				local explode = ents.Create("env_explosion")
				explode:SetPos(trace.HitPos)
				explode:SetOwner(client)
				explode:Spawn()
				explode:SetKeyValue("iMagnitude", blastDamage)
				explode:Fire("Explode")

				util.BlastDamage(explode, client, trace.HitPos, blastRadius, blastDamage)
			end
		end

		item.player:GiveAmmo(ammoAmount, item.ammo, callback)
		item.player:EmitSound(item.useSound, 110)

		return true
	end,
}

-- Called after the item is registered into the item tables.
function ITEM:OnRegistered()
	if (ix.ammo) then
		ix.ammo.Register(self.ammo)
	end
end
