local PLUGIN = PLUGIN

function SWEP:SanityCheck()
	if not IsValid(self) then return false end
	if not IsValid(self:GetOwner()) then return false end
	if not IsValid(self:GetVM()) then return false end
end

function SWEP:GetVM()
	if not IsValid(self:GetOwner()) or (self:GetOwner():IsNPC() or self:GetOwner():IsNextBot()) then return end
	return self:GetOwner():GetViewModel()
end

function SWEP:Curve(x)
	return 0.5 * math.cos((x + 1) * math.pi) + 0.5
end

SWEP.LastSysTime = SysTime()
function SWEP:DeltaSysTime()
	local ret = (SysTime() - (self.LastSysTime or SysTime())) * GetConVar("host_timescale"):GetFloat()
	return ret
end

function SWEP:IsAnimLocked()
	return self:GetAnimLockTime() > CurTime()
end

function SWEP:ChooseSound(tbl)
	if not istable(tbl) then return tbl end
	tbl.BaseClass = nil -- lua tables lel
	return tbl[math.random(1, #tbl)]
end

function SWEP:OnReloaded()
	self:InvalidateCache()
	self:SetBaseSettings()

	hook.Run("TacRP_WeaponReloaded", self)
end

function SWEP:DoLowerIrons()
	if self:GetValue("Holosight") or self:GetValue("ScopeOverlay") then return false end
	local i = PLUGIN.ConVars["irons_lower"]:GetInt()
	return i == 2 or (i == 1 and engine.ActiveGamemode() == "terrortown")
end

function SWEP:DoProceduralIrons()
	local i = PLUGIN.ConVars["irons_procedural"]:GetInt()
	return self.ProceduralIronFire and
		(i == 2 or (i == 1 and self:GetValue("Holosight"))) --and (!self.LastShot or self:Clip1() > 1)
end

function SWEP:CountAttachments()
	local count = 0
	for k, v in ipairs(self.Attachments) do
		if v.Installed then count = count + 1 end
	end
	return count
end

function SWEP:GetMaxClip1()
	return self:GetCapacity()
end

function SWEP:IsDamageConstant(base)
	local valfunc = base and self.GetBaseValue or self.GetValue
	return valfunc(self, "Damage_Min") == valfunc(self, "Damage_Max")
end

function SWEP:GetPingOffsetScale()
	if game.SinglePlayer() then return 0 end

	return (self:GetOwner():Ping() - 5) / 1000
end
