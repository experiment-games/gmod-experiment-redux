local BUFF = BUFF

BUFF.name = "Quantum Buffer"
BUFF.foregroundImage = {
	spritesheet = "experiment-redux/flatmsicons32.png",
	x = 23,
	y = 9,
	size = 32,
}
BUFF.durationInSeconds = 15 * 60
BUFF.description =
"You are invulnerable to damage from other players for a short duration, unless you attack, speak or take other damage."

if (not SERVER) then
	return
end

local function bufferEffect(client)
	if (not Schema.util.Throttle("QuantumBufferDamageSound", 0.5, client)) then
		client:EmitSound("ambient/energy/zap7.wav", 75, 100 + math.random(0, 100))
	end

	local flickerDuration = 1
	if (not Schema.util.Throttle("QuantumBufferDamageEffect", flickerDuration, client) and not client.expQuantumBufferFlickering) then
		client.expQuantumBufferFlickering = true
		client:RemoveAllClientDecals()

		local oldMaterial = client:GetMaterial()
		local flickerAmount = 5
		local flickerCount = 0
		local flickerInterval = flickerDuration / flickerAmount

		timer.Create("QuantumBufferDamageEffect" .. client:EntIndex(), flickerInterval, flickerAmount, function()
			if (IsValid(client)) then
				client:SetMaterial("models/effects/vol_light001")
			end

			timer.Simple(flickerInterval * .5, function()
				if (IsValid(client)) then
					client:SetMaterial(oldMaterial)

					flickerCount = flickerCount + 1

					if (flickerCount >= flickerAmount) then
						client.expQuantumBufferFlickering = false
					end
				end
			end)
		end)
	end
end

function BUFF:OnShouldExpire(client, buff)
	if (client.expQuantumBufferShouldExpire) then
		client.expQuantumBufferShouldExpire = nil
		client:EmitSound("ambient/energy/whiteflash.wav", 35, 250)
		return true
	end
end

function BUFF.hooks:PostPlayerLoadout(client)
	if (Schema.buff.GetActive(client, self.index)) then
		return
	end

	-- Not if the player is being resurrected.
	if (client.expIsResurrecting) then
		return
	end

	Schema.buff.SetActive(client, self.index)
end

function BUFF.hooks:EntityTakeDamage(entity, damageInfo)
	if (not entity:IsPlayer()) then
		return
	end

	if (Schema.buff.GetActive(entity, self.index)) then
		local attacker = damageInfo:GetAttacker()

		if ((IsValid(attacker) and not attacker:IsPlayer()) or damageInfo:IsFallDamage()) then
			entity.expQuantumBufferShouldExpire = true
			return
		end

		bufferEffect(entity)

		return true
	end
end

function BUFF.hooks:PlayerSay(client, text)
	if (Schema.buff.GetActive(client, self.index)) then
		client.expQuantumBufferShouldExpire = true
	end
end

function BUFF.hooks:PlayerWeaponChanged(client, weapon)
	if (weapon:GetClass() == "ix_hands"
			or weapon:GetClass() == "ix_keys"
			or weapon:GetClass() == "exp_keys"
			or weapon:GetClass() == "gmod_tool"
			or weapon:GetClass() == "weapon_physgun") then
		return
	end

	if (Schema.buff.GetActive(client, self.index)) then
		client.expQuantumBufferShouldExpire = true
	end
end

function BUFF.hooks:PlayerOpenedBelongings(client, belongings, inventory)
	if (Schema.buff.GetActive(client, self.index)) then
		client.expQuantumBufferShouldExpire = true
	end
end

function BUFF.hooks:PlayerSecondElapsed(client)
	local weapon = client:GetActiveWeapon()

	if (not IsValid(weapon) or weapon:GetClass() ~= "ix_hands") then
		return
	end

	if (client:IsWepRaised() and Schema.buff.GetActive(client, self.index)) then
		client.expQuantumBufferShouldExpire = true
	end
end

function BUFF.hooks:CanPlayerInteractItem(client, action, item)
	local instance = ix.item.instances[item]

	if (not instance or instance.uniqueID == "tutorial") then
		return
	end

	if (Schema.buff.GetActive(client, self.index)) then
		client.expQuantumBufferShouldExpire = true
	end
end
