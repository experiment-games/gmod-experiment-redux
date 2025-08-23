ENT.PrintName = "Monitor"
ENT.Author = ""
ENT.Information = "A monitor with tools to make them permanent"

ENT.Editable = true
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.MinScale = 0
ENT.MaxScale = 5

function ENT:SetupDataTables()
	self:NetworkVar("Float", "MonitorScale", {
		KeyName = "monitor_scale",
		Edit = {
			type = "Float",
			min = self.MinScale,
			max = self.MaxScale,
			order = 1
		}
	})
	self:NetworkVar("Float", "MonitorWidth", {
		KeyName = "monitor_width",
		Edit = {
			type = "Float",
			min = 640,
			max = 7680,
			order = 2
		}
	})
	self:NetworkVar("Float", "MonitorHeight", {
		KeyName = "monitor_height",
		Edit = {
			type = "Float",
			min = 420,
			max = 4320,
			order = 3
		}
	})
	self:NetworkVar("Bool", "IsHelper", {
		KeyName = "monitor_helper"
	})
	self:NetworkVar("Bool", "PoweredOn", {
		KeyName = "monitor_powered_on"
	})

	self:NetworkVar("String", "SpecialID")
end
