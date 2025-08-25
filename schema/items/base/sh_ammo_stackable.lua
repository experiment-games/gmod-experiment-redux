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

-- On player uneqipped the item, Removes a weapon from the player and keep the ammo in the item.
ITEM.functions.use = {
	name = "Load",
	tip = "useTip",
	icon = "icon16/add.png",
	OnRun = function(item)
		local ammoAmount = item:GetData("stacks", 1)

		local callback

		if (item:GetData("poisoned")) then
			callback = function(client, weapon, ammoType, bulletData)
				local target = bulletData.Trace.Entity

				if (IsValid(target)) then
					-- TODO: Poison instead
					target:Ignite(4)
				end
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
