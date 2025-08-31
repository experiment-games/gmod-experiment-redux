include("shared.lua")

ENT.PopulateEntityInfo = true

local workbenchIcon = ix.util.GetMaterial("experiment-redux/icons/workbench.png")

function ENT:OnPopulateEntityInfo(tooltip)
	local name = tooltip:AddRow("name")
	name:SetImportant()
	name:SetText(L("workbench"))
	name:SizeToContents()

	if (self:GetInUse()) then
		local startTime = self:GetProcessStartTime()
		local duration = self:GetProcessDuration()
		local elapsed = CurTime() - startTime
		local remaining = math.max(0, duration - elapsed)

		local statusRow = tooltip:AddRow("status")
		if (remaining > 0) then
			statusRow:SetText("Crafting...")
			statusRow:SetTextColor(Color(255, 200, 100))
		else
			statusRow:SetText("Crafting Complete")
			statusRow:SetTextColor(Color(100, 255, 100))
		end
		statusRow:SizeToContents()

		local progressBar = tooltip:Add("expProgressBar")
		progressBar:SetValue(function()
			return CurTime() - startTime
		end)
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
		local pos = self:GetPos() + self:GetUp() * 30
		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)

		cam.Start3D2D(pos, ang, 0.1)
		surface.SetMaterial(workbenchIcon)
		surface.SetDrawColor(255, 255, 255, 200)
		surface.DrawTexturedRect(-16, -16, 32, 32)
		cam.End3D2D()
	end
end

function ENT:GetEntityMenu()
	local options = {}

	-- Check if station has completed process
	if (self:GetInUse()) then
		local startTime = self:GetProcessStartTime()
		local duration = self:GetProcessDuration()
		local elapsed = CurTime() - startTime

		if (elapsed >= duration) then
			options["Retrieve Items"] = function() end
			return options
		else
			-- Process still running
			return {}
		end
	end

	options["Combine Items"] = function() end

	return options
end
