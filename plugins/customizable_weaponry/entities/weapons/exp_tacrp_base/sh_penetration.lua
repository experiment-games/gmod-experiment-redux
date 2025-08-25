local PLUGIN = PLUGIN

local function draw_debug()
	return (CLIENT or game.SinglePlayer()) and GetConVar("developer"):GetInt() >= 2
end

local function IsPenetrating(ptr, ptrent)
	if ptrent:IsWorld() then
		return ptr.Contents ~= CONTENTS_EMPTY
	elseif IsValid(ptrent) then
		local withinbounding = false
		local hboxset = ptrent:GetHitboxSet()
		local hitbone = ptrent:GetHitBoxBone(ptr.HitBox, hboxset)
		if hitbone then
			-- If we hit a hitbox, compare against that hitbox only
			local mins, maxs = ptrent:GetHitBoxBounds(ptr.HitBox, hboxset)
			local bonepos, boneang = ptrent:GetBonePosition(hitbone)
			mins = mins * 1.1
			maxs = maxs * 1.1
			local lpos = WorldToLocal(ptr.HitPos, ptr.HitNormal:Angle(), bonepos, boneang)

			withinbounding = lpos:WithinAABox(mins, maxs)
			if draw_debug() then
				debugoverlay.BoxAngles(bonepos, mins, maxs, boneang, 5, Color(255, 255, 255, 10))
			end
		elseif util.PointContents(ptr.HitPos) ~= CONTENTS_EMPTY then
			-- Otherwise default to rotated OBB
			local mins, maxs = ptrent:OBBMins(), ptrent:OBBMaxs()
			withinbounding = ptrent:WorldToLocal(ptr.HitPos):WithinAABox(mins, maxs)
			if draw_debug() then
				debugoverlay.BoxAngles(ptrent:GetPos(), mins, maxs, ptrent:GetAngles(), 5, Color(255, 255, 255, 10))
			end
		end
		if draw_debug() then
			debugoverlay.Cross(ptr.HitPos, withinbounding and 4 or 6, 5,
				withinbounding and Color(255, 255, 0) or Color(128, 255, 0), true)
		end

		return withinbounding
	end
	return false
end

-- function SWEP:Penetrate(tr, range, penleft, alreadypenned)
-- 	if not PLUGIN.ConVars["penetration"]:GetBool() then return end

-- 	if not IsValid(self:GetOwner()) then return end

-- 	local hitpos, startpos = tr.HitPos, tr.StartPos
-- 	local dir              = (hitpos - startpos):GetNormalized()

-- 	if tr.HitSky then return end

-- 	if penleft <= 0 then return end

-- 	alreadypenned     = alreadypenned or {}

-- 	local skip        = false

-- 	local trent       = tr.Entity

-- 	local penmult     = PLUGIN.PenTable[tr.MatType] or 1

-- 	local pentracelen = math.max(penleft * penmult / 2, 2)
-- 	local curr_ent    = trent

-- 	if not tr.HitWorld then penmult = penmult * 0.5 end
-- 	if trent.Impenetrable then penmult = 100000 end
-- 	if trent.mmRHAe then penmult = trent.mmRHAe end

-- 	-- penmult = penmult * math.Rand(0.9, 1.1) * math.Rand(0.9, 1.1)

-- 	local endpos = hitpos

-- 	local td     = {}
-- 	td.start     = endpos
-- 	td.endpos    = endpos + (dir * pentracelen)
-- 	td.mask      = MASK_SHOT

-- 	local ptr    = util.TraceLine(td)

-- 	local ptrent = ptr.Entity

-- 	while ! skip and penleft > 0 and IsPenetrating(ptr, ptrent) and ptr.Fraction < 1 and ptrent == curr_ent do
-- 		penleft   = penleft - (pentracelen * penmult)

-- 		td.start  = endpos
-- 		td.endpos = endpos + (dir * pentracelen)
-- 		td.mask   = MASK_SHOT

-- 		ptr       = util.TraceLine(td)

-- 		if GetConVar("developer"):GetBool() then
-- 			local pdeltap = penleft / self:GetValue("Penetration")
-- 			local colorlr = Lerp(pdeltap, 0, 255)

-- 			debugoverlay.Line(endpos, endpos + (dir * pentracelen), 10, Color(255, colorlr, colorlr), true)
-- 		end

-- 		endpos = endpos + (dir * pentracelen)
-- 		range = range + pentracelen
-- 	end

-- 	if penleft > 0 then
-- 		if (dir:Length() == 0) then return end

-- 		self:GetOwner():FireBullets({
-- 			Damage = self:GetValue("Damage_Max"),
-- 			Force = 4,
-- 			Tracer = 0,
-- 			Num = 1,
-- 			Dir = dir,
-- 			Src = endpos,
-- 			Callback = function(att, btr, dmg)
-- 				range = range + (btr.HitPos - btr.StartPos):Length()
-- 				self:AfterShotFunction(btr, dmg, range, penleft, alreadypenned)

-- 				if GetConVar("developer"):GetBool() then
-- 					if SERVER then
-- 						debugoverlay.Cross(btr.HitPos, 4, 5, Color(255, 0, 0), false)
-- 					else
-- 						debugoverlay.Cross(btr.HitPos, 4, 5, Color(255, 255, 255), false)
-- 					end
-- 				end
-- 			end
-- 		})

-- 		self:GetOwner():FireBullets({
-- 			Damage = 0,
-- 			Force = 0,
-- 			Tracer = 0,
-- 			Num = 1,
-- 			Distance = 1,
-- 			Dir = -dir,
-- 			Src = endpos,
-- 		})
-- 	end
-- end
