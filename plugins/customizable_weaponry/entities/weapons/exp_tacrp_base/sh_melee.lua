local PLUGIN = PLUGIN

SWEP.Sound_MeleeHit = nil
SWEP.Sound_MeleeHitBody = nil

-- Don't you love lua table inheritance??
SWEP._Sound_MeleeHit = {
	"TacRP/weapons/melee_hit-1.wav",
	"TacRP/weapons/melee_hit-2.wav"
}
SWEP._Sound_MeleeHitBody = {
	"TacRP/weapons/melee_body_hit-1.wav",
	"TacRP/weapons/melee_body_hit-2.wav",
	"TacRP/weapons/melee_body_hit-3.wav",
	"TacRP/weapons/melee_body_hit-4.wav",
	"TacRP/weapons/melee_body_hit-5.wav",
}

function SWEP:Melee(alt)
	if not self:GetValue("CanMeleeAttack") then return end
	if self:StillWaiting(false, true) then return end
	-- if self:SprintLock() then return end

	self.Primary.Automatic = true
	self.Secondary.Automatic = true

	self:CancelReload()

	self:ToggleBlindFire(PLUGIN.BLINDFIRE_NONE)
	self:ScopeToggle(0)


	local dmg = self:GetValue("MeleeDamage")
	local range = self:GetValue("MeleeRange")
	local delay = self:GetValue("MeleeDelay")
	if alt then
		self:PlayAnimation("melee2", 1, false, true)
		self:GetOwner():DoAnimationEvent(self:GetValue("GestureBash2") or self:GetValue("GestureBash"))
		-- range = self:GetValue("Melee2Range") or range
		dmg = self:GetHeavyAttackDamage()
	else
		self:PlayAnimation("melee", 1, false, true)
		self:GetOwner():DoAnimationEvent(self:GetValue("GestureBash"))
	end

	local t = alt and self:GetHeavyAttackTime() or self:GetValue("MeleeAttackTime")

	if delay > 0 then
		self:EmitSound(self:ChooseSound(self:GetValue("Sound_MeleeSwing")), 75, 100, 1)
	end

	self:SetTimer(delay, function()
		self:GetOwner():LagCompensation(true)

		local filter = { self:GetOwner() }

		table.Add(filter, self.Shields)

		local start = self:GetOwner():GetShootPos()
		local dir = self:GetOwner():GetAimVector()
		local tr = util.TraceLine({
			start = start,
			endpos = start + dir * range,
			filter = filter,
			mask = MASK_SHOT_HULL,
		})

		-- weapon_hl2mpbasebasebludgeon.cpp: do a hull trace if not hit
		if tr.Fraction == 1 or not IsValid(tr.Entity) then
			local dim = 32
			local pos2 = tr.HitPos - dir * (dim * 1.732)
			local tr2 = util.TraceHull({
				start = start,
				endpos = pos2,
				filter = filter,
				mask = MASK_SHOT_HULL,
				mins = Vector(-dim, -dim, -dim),
				maxs = Vector(dim, dim, dim)
			})

			if tr2.Fraction < 1 and IsValid(tr2.Entity) then
				local dot = (tr2.Entity:GetPos() - start):GetNormalized():Dot(dir)
				if dot >= 0.5 then
					tr = tr2
				end
			end
		end

		local dmginfo = DamageInfo()
		dmginfo:SetDamage(dmg)
		dmginfo:SetDamageForce(dir * dmg * 500)
		dmginfo:SetDamagePosition(tr.HitPos)
		dmginfo:SetDamageType(self:GetValue("MeleeDamageType"))
		if dmginfo:GetDamageType() == DMG_GENERIC and engine.ActiveGamemode() == "terrortown" then
			dmginfo:SetDamageType(DMG_CLUB) -- use CLUB so TTT can assign DNA (it does not leave DNA on generic damage)
		end

		dmginfo:SetAttacker(self:GetOwner())
		dmginfo:SetInflictor(self)

		if tr.Fraction < 1 then
			PLUGIN.CancelBodyDamage(tr.Entity, dmginfo, tr.HitGroup)

			if (
					IsValid(tr.Entity)
					and (tr.Entity:IsNPC() or tr.Entity:IsPlayer() or tr.Entity:IsNextBot())
					and (tr.Entity:GetClass() ~= "npc_turret_floor" and tr.Entity:GetClass() ~= "npc_turret_ceiling")
				) then
				self:EmitSound(
					self:ChooseSound(self:GetValue("Sound_MeleeHitBody") or self:GetValue("_Sound_MeleeHitBody")), 75,
					100, 1,
					CHAN_ITEM)

				if self:GetValue("MeleeBackstab") then
					local ang = math.NormalizeAngle(self:GetOwner():GetAngles().y - tr.Entity:GetAngles().y)
					if ang <= 60 and ang >= -60 then
						dmginfo:ScaleDamage(self:GetValue("MeleeBackstabMult"))
						self:EmitSound("tacrp/riki_backstab.wav", 70, 100, 0.4)
					end
				end
			else
				self:EmitSound(self:ChooseSound(self:GetValue("Sound_MeleeHit") or self:GetValue("_Sound_MeleeHit")), 75,
					100, 1, CHAN_ITEM)
			end

			if IsValid(tr.Entity) and self:GetValue("MeleeSlow") then
				tr.Entity.TacRPBashSlow = true
			end

			if tr.HitGroup == HITGROUP_HEAD then
				dmginfo:ScaleDamage(1.25)
			end

			if IsValid(tr.Entity) then
				--tr.Entity:TakeDamageInfo(dmginfo)
				tr.Entity:DispatchTraceAttack(dmginfo, tr)
			end

			self:FireBullets({
				Attacker = self:GetOwner(),
				Damage = 0,
				Force = 0,
				Distance = range + 8,
				HullSize = 0,
				Tracer = 0,
				Dir = (tr.HitPos - start):GetNormalized(),
				Src = start,
			})
		else
			local tmiss
			if not alt and self:GetValue("MeleeAttackMissTime") then
				tmiss = self:GetValue("MeleeAttackMissTime")
			elseif alt then
				tmiss = self:GetHeavyAttackTime(true, false)
			end
			if tmiss then
				self:SetNextSecondaryFire(CurTime() + (tmiss - delay))
			end
			if delay == 0 then
				self:EmitSound(self:ChooseSound(self:GetValue("Sound_MeleeSwing")), 75, 100, 1)
			end
		end

		self:GetOwner():LagCompensation(false)
	end, "Melee")

	self:SetLastMeleeTime(CurTime())
	self:SetNextSecondaryFire(CurTime() + t)
end

function SWEP:GetHeavyAttackDamage(base)
	local valfunc = base and self.GetBaseValue or self.GetValue
	return valfunc(self, "Melee2Damage") or valfunc(self, "MeleeDamage") * self:GetMeleePerkDamage(base) * 1.5
end

function SWEP:GetHeavyAttackTime(miss, base)
	local valfunc = base and self.GetBaseValue or self.GetValue
	if miss then
		return (valfunc(self, "Melee2AttackMissTime") or (valfunc(self, "MeleeAttackMissTime") * 1.6))
			* self:GetMeleePerkCooldown(base)
	else
		return (valfunc(self, "Melee2AttackTime") or (valfunc(self, "MeleeAttackTime") * 1.6))
			* self:GetMeleePerkCooldown(base)
	end
end

function SWEP:GetMeleePerkDamage(base)
	local valfunc = base and self.GetBaseValue or self.GetValue
	local stat = valfunc(self, "MeleePerkStr")
	if stat >= 0.5 then
		return Lerp((stat - 0.5) * 2, 1, 2)
	else
		return Lerp(stat * 2, 0.7, 1)
	end
end

function SWEP:GetMeleePerkCooldown(base)
	local valfunc = base and self.GetBaseValue or self.GetValue
	local stat = valfunc(self, "MeleePerkAgi")
	if stat >= 0.5 then
		return Lerp((stat - 0.5) * 2, 1, 0.7)
	else
		return Lerp(stat * 2, 1.3, 1)
	end
end

function SWEP:GetMeleePerkSpeed(base)
	local valfunc = base and self.GetBaseValue or self.GetValue
	local stat = valfunc(self, "MeleePerkAgi")
	if stat >= 0.5 then
		return Lerp((stat - 0.5) * 2, 1, 1.5)
	else
		return Lerp(stat * 2, 0.5, 1)
	end
end

function SWEP:GetMeleePerkVelocity(base)
	local valfunc = base and self.GetBaseValue or self.GetValue
	local stat = valfunc(self, "MeleePerkInt")
	if stat >= 0.5 then
		return Lerp((stat - 0.5) * 2, 1, 3) * valfunc(self, "MeleeThrowForce")
	else
		return Lerp(stat * 2, 0.5, 1) * valfunc(self, "MeleeThrowForce")
	end
end

hook.Add("PostEntityTakeDamage", "tacrp_melee", function(ent, dmg, took)
	if ent.TacRPBashSlow then
		if took and (not ent:IsPlayer() or (ent:IsPlayer() and not (IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon().ArcticTacRP and ent:GetActiveWeapon():GetValue("StunResist")))) then
			ent:SetNWFloat("TacRPLastBashed", CurTime())
		end
		ent.TacRPBashSlow = false
	end

	local wep = dmg:GetInflictor()
	if (not IsValid(wep) or not wep:IsWeapon()) and IsValid(dmg:GetAttacker()) and dmg:GetAttacker():IsPlayer() then
		wep =
			dmg:GetAttacker():GetActiveWeapon()
	end
	if took and (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) and IsValid(wep) and wep.ArcticTacRP then
		if (wep:GetValue("Lifesteal") or 0) > 0 then
			wep:GetOwner():SetHealth(math.min(math.max(wep:GetOwner():GetMaxHealth(), wep:GetOwner():Health()),
				wep:GetOwner():Health() + dmg:GetDamage() * wep:GetValue("Lifesteal")))
		end
		if (wep:GetValue("DamageCharge") or 0) > 0 then
			wep:SetBreath(math.min(1, wep:GetBreath() + dmg:GetDamage() * wep:GetValue("DamageCharge")))
		end
	end
end)
