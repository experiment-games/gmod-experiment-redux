include("shared.lua")

ENT.PopulateEntityInfo = true

local distillIcon = ix.util.GetMaterial("experiment-redux/icons/distill.png")
local combineIcon = ix.util.GetMaterial("experiment-redux/icons/combine.png")

local distillIconAspectRatio = distillIcon:Width() / distillIcon:Height()
local combineIconAspectRatio = combineIcon:Width() / combineIcon:Height()

function ENT:OnPopulateEntityInfo(tooltip)
	local name = tooltip:AddRow("name")
	name:SetImportant()
	name:SetText(L("chemistryStation"))
	name:SizeToContents()

	if (self:GetInUse()) then
		local processType = self:GetProcessType()
		local startTime = self:GetProcessStartTime()
		local duration = self:GetProcessDuration()
		local elapsed = CurTime() - startTime
		local remaining = math.max(0, duration - elapsed)

		local statusRow = tooltip:AddRow("status")
		if (remaining > 0) then
			statusRow:SetText(processType == "distillation" and L("distilling") or L("combining"))
			statusRow:SetTextColor(Color(255, 200, 100))
		else
			statusRow:SetText("Process Complete")
			statusRow:SetTextColor(Color(100, 255, 100))
		end
		statusRow:SizeToContents()

		local progressBar = tooltip:Add("expProgressBar")
		progressBar:SetValue(function() return CurTime() - startTime end)
		progressBar:SetMaxValue(duration)
		progressBar:SetDrawValueText(false)
		progressBar:Dock(BOTTOM)
	else
		local statusRow = tooltip:AddRow("status")
		statusRow:SetText("Ready for use")
		statusRow:SetTextColor(Color(200, 200, 200))
		statusRow:SizeToContents()
	end
end

function ENT:Draw()
	self:DrawModel()

	if (self:GetInUse()) then
		local pos = self:GetPos() + self:GetUp() * 40
		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)

		cam.Start3D2D(pos, ang, 0.1)
		local processType = self:GetProcessType()
		local icon = processType == "distillation" and distillIcon or combineIcon

		surface.SetMaterial(icon)
		surface.SetDrawColor(255, 255, 255, 200)

		local height = 32
		local width = height * (processType == "distillation" and distillIconAspectRatio or combineIconAspectRatio)

		surface.DrawTexturedRect(-width * .5, -height * .5, width, height)

		cam.End3D2D()
	end
end
