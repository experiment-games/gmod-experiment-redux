include("shared.lua")

DEFINE_BASECLASS("base_ai")

ENT.PopulateEntityInfo = true

ENT.MarkerPosZ = 78

function ENT:Draw()
	self:DrawModel()

	if (not self:GetNpcId()) then
		return
	end

	if (IsValid(ix.menu.panel)) then
		return
	end

	local icon = ix.util.GetMaterial("experiment-redux/mission_available.png")
	local alphaRange, alphaBase = 100, 55

	self.cachedNpcData = self.cachedNpcData or Schema.npc.Get(self:GetNpcId())

	if (not self.cachedNpcData or (self.cachedNpcData.ClientGetAvailable and not self.cachedNpcData:ClientGetAvailable(self))) then
		icon = ix.util.GetMaterial("experiment-redux/mission_unavailable.png")
		alphaRange, alphaBase = 0, 5
	end

	local positionOverNpc = self:GetPos()
		+ (self:GetUp() * self.MarkerPosZ)
		+ (self:GetForward() * 2)
	positionOverNpc = positionOverNpc + Vector(0, 0, math.cos(CurTime() * .5))

	local angleFacingPlayer = (positionOverNpc - EyePos()):GetNormalized():Angle()

	angleFacingPlayer = Angle(0, angleFacingPlayer.y, 0)
	angleFacingPlayer.y = angleFacingPlayer.y + math.sin(CurTime()) * 10

	-- Correct the angle so it points at the camera
	angleFacingPlayer:RotateAroundAxis(angleFacingPlayer:Up(), -90)
	angleFacingPlayer:RotateAroundAxis(angleFacingPlayer:Forward(), 90)

	cam.Start3D2D(positionOverNpc, angleFacingPlayer, .4)
	surface.SetMaterial(icon)
	surface.SetDrawColor(255, 255, 255, math.abs(math.sin(CurTime() * 2) * alphaRange) + alphaBase)
	surface.DrawTexturedRect(-16, -16, 32, 32)
	cam.End3D2D()
end

function ENT:Think()
	if ((self.nextAnimCheck or 0) < CurTime()) then
		self:SetAnim()
		self.nextAnimCheck = CurTime() + 2
	end

	self:SetNextClientThink(CurTime() + 0.25)

	return true
end

function ENT:OnPopulateEntityInfo(container)
	local name = container:AddRow("name")
	name:SetImportant()
	name:SetText(self:GetDisplayName())
	name:SizeToContents()

	local descriptionText = self:GetDescription()

	if (descriptionText ~= "") then
		local description = container:AddRow("description")
		description:SetText(self:GetDescription())
		description:SizeToContents()
	end
end
