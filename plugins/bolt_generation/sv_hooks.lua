local PLUGIN = PLUGIN

function PLUGIN:PlayerFillDefaultInventory(client, character, inventory)
	inventory:Add("bolt_control_unit", 1)
end

function PLUGIN:GeneratorAdjustDamage(generator, damageInfo)
	local protectorHandled = false
	local informerHandled = false

	for _, entity in ipairs(ents.FindInSphere(generator:GetPos(), self.boltProtectorRange)) do
		if (entity:GetClass() == "exp_bolt_protector" and not protectorHandled) then
			protectorHandled = true

			local damageScale = 0.5

			if (Schema.perk.GetOwned("intervention", generator:GetItemOwner())) then
				local damageMultiplier = Schema.perk.GetProperty("intervention", "damageMultiplier")

				damageScale = damageScale * damageMultiplier
			end

			damageInfo:ScaleDamage(damageScale)
		elseif (entity:GetClass() == "exp_bolt_informer" and not informerHandled) then
			informerHandled = true

			local boltInformerOwner = entity.expClient

			if (IsValid(boltInformerOwner) and boltInformerOwner == generator.expClient) then
				if (not boltInformerOwner.expNextBoltInformerWarn or CurTime() >= boltInformerOwner.expNextBoltInformerWarn) then
					ix.chat.Send(boltInformerOwner, "bolt_informer",
						"We have detected that your bolt generator is under attack!")

					boltInformerOwner.expNextBoltInformerWarn = CurTime() + self.boltInformerWarnInterval
				end

				break
			end
		end
	end
end
