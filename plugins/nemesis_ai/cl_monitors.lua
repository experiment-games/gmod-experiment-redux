local PLUGIN = PLUGIN

local scanLinesMaterial = Material("experiment-redux/combinescanline")

-- Client-specific monitor overrides (by specialID)
PLUGIN.clientSpecificMonitors = PLUGIN.clientSpecificMonitors or {}

net.Receive("expSetMonitorTarget", function(length)
	local entity = net.ReadEntity()

	PLUGIN.targetedEntity = IsValid(entity) and entity or nil
	PLUGIN.monitorVgui = "expMonitorTarget"

	local monitors = ents.FindByClass("exp_monitor")

	hook.Run("ExperimentMonitorsFilter", monitors, "target")

	for _, monitor in pairs(monitors) do
		if (IsValid(entity)) then
			PLUGIN:SetMonitorTargetVgui(monitor, function(parent)
				return vgui.Create("expMonitorTarget", parent)
			end)
		end
	end
end)

net.Receive("expSetMonitorVgui", function(length)
	local vguiClass = net.ReadString()

	local monitors = ents.FindByClass("exp_monitor")
	PLUGIN.monitorVgui = vguiClass

	hook.Run("ExperimentMonitorsFilter", monitors, "vgui")

	for _, monitor in pairs(monitors) do
		PLUGIN:SetMonitorTargetVgui(monitor, function(parent)
			return vgui.Create(vguiClass, parent)
		end)
	end
end)

net.Receive("expMonitorsPrintPresets", function(length)
	local presets = PLUGIN.presets

	print("Presets:")
	for key, preset in pairs(presets) do
		print("\t" .. key .. ": " .. preset.description)
	end
end)

-- Set a client-specific VGUI for monitors with a specific specialID
function PLUGIN:SetClientSpecificMonitorVgui(specialID, vguiFunction)
	self.clientSpecificMonitors[specialID] = vguiFunction

	-- Apply to existing monitors
	local monitors = ents.FindByClass("exp_monitor")
	for _, monitor in pairs(monitors) do
		if (monitor:GetSpecialID() == specialID) then
			self:SetMonitorTargetVgui(monitor, vguiFunction)
		end
	end
end

-- Clear client-specific VGUI for monitors with a specific specialID
function PLUGIN:ClearClientSpecificMonitorVgui(specialID)
	self.clientSpecificMonitors[specialID] = nil

	-- Revert to global settings for existing monitors
	local monitors = ents.FindByClass("exp_monitor")
	for _, monitor in pairs(monitors) do
		if (monitor:GetSpecialID() == specialID) then
			-- Clear the current target and let the normal system take over
			monitor.expMonitorTargetVgui = nil
			monitor.expMonitorTargetHtml = nil

			-- Re-apply global settings if they exist
			if (self.monitorVgui and self.monitorVgui == "expMonitorTarget" and IsValid(self.targetedEntity)) then
				self:SetMonitorTargetVgui(monitor, function(parent)
					return vgui.Create("expMonitorTarget", parent)
				end)
			elseif (self.monitorVgui) then
				self:SetMonitorTargetVgui(monitor, function(parent)
					return vgui.Create(self.monitorVgui, parent)
				end)
			end
		end
	end
end

-- Check if a monitor should use client-specific content
function PLUGIN:GetClientSpecificMonitorContent(monitor)
	local specialID = monitor:GetSpecialID()

	if (specialID and specialID ~= "") then
		return self.clientSpecificMonitors[specialID]
	end

	return nil
end

-- When a monitor comes into PVS, set it up with the correct vgui
function PLUGIN:HandleMonitorEntityEnteringPVS(entity)
	-- Check for client-specific content first
	local clientSpecificVgui = self:GetClientSpecificMonitorContent(entity)

	if (clientSpecificVgui) then
		self:SetMonitorTargetVgui(entity, clientSpecificVgui)
		return
	end

	-- Fall back to global settings
	if (not self.monitorVgui) then
		return
	end

	local monitors = { entity }

	hook.Run("ExperimentMonitorsFilter", monitors, self.monitorVgui == "expMonitorTarget" and "target" or "vgui")

	for _, monitor in ipairs(monitors) do
		self:SetMonitorTargetVgui(monitor, function(parent)
			return vgui.Create(self.monitorVgui, parent)
		end)
	end
end

function PLUGIN:GetDirectionToTarget(monitor)
	if not IsValid(self.targetedEntity) then return end

	local centerOfMonitorPos = monitor:GetPos()
		- monitor:GetAngles():Right() * (monitor:GetMonitorWidth() * .5 * monitor:GetMonitorScale())
		- monitor:GetAngles():Up() * (monitor:GetMonitorHeight() * .5 * monitor:GetMonitorScale())

	local heading = (PLUGIN.targetedEntity:GetPos() + Vector(0, 0, 70)) - centerOfMonitorPos
	local distance = heading:Length()
	local direction = heading / distance

	return direction, distance
end

function PLUGIN:ShouldDrawMonitor(monitor)
	local clientSpecificVgui = self:GetClientSpecificMonitorContent(monitor)

	if (clientSpecificVgui) then
		return true
	end

	-- Use normal power state for global content
	return monitor:GetPoweredOn()
end

function PLUGIN:SetupMonitorDrawing(monitor)
	local customRenderTarget, renderTargetMaterial, renderTargetMaterialMirrored = self:GetMonitorRenderTarget(monitor)
	local wave = 25 * math.sin(CurTime()) * monitor.random
	monitor.drawAlphaBackground = 55 + wave
	monitor.drawAlphaForeground = 90 + wave
	monitor.drawStutterX = math.random() > 0.01 and 0 or math.sin(CurTime() * 40) * 2
	monitor.drawStutterY = math.random() > 0.01 and 0 or math.sin(CurTime() * 20) * 4

	-- Draw the monitor contents to the render target so we can easily mirror the whole thing
	render.PushRenderTarget(customRenderTarget)
	self:DrawMonitorContents(monitor, renderTargetMaterial)
	render.PopRenderTarget()

	self:RenderMonitorToPlayerView(monitor, renderTargetMaterial)
	self:RenderMonitorToPlayerView(monitor, renderTargetMaterial, renderTargetMaterialMirrored)
end

function PLUGIN:GetMonitorRenderTarget(monitor)
	local width, height = monitor:GetMonitorWidth(), monitor:GetMonitorHeight()
	local renderTarget = GetRenderTarget("monitor_rendertarget_" .. monitor:EntIndex(), width, height)

	monitor.expRenderTargetMaterial = monitor.expRenderTargetMaterial or
		CreateMaterial("monitor_material_" .. monitor:EntIndex(), "UnlitGeneric", {
			["$basetexture"] = renderTarget:GetName(),
			["$translucent"] = 1,
			["$vertexalpha"] = 1,
		})
	monitor.expRenderTargetMaterialMirrored = monitor.expRenderTargetMaterialMirrored or
		CreateMaterial("monitor_material_mirrored_" .. monitor:EntIndex(), "UnlitGeneric", {
			["$basetexture"] = renderTarget:GetName(),
			["$translucent"] = 1,
			["$vertexalpha"] = 1,
			["$basetexturetransform"] = "center .5 .5 scale -1 1 rotate 0 translate 0 0",
		})

	return renderTarget, monitor.expRenderTargetMaterial, monitor.expRenderTargetMaterialMirrored
end

function PLUGIN:DrawMonitorContents(monitor, renderTargetMaterial)
	cam.Start2D()
	render.Clear(0, 0, 0, 0, true, true)

	if (monitor.expMonitorTargetHtml) then
		self:SetupAndOrDrawHtml(monitor, renderTargetMaterial)
	elseif (monitor.expMonitorTargetVgui) then
		self:SetupAndOrDrawVgui(monitor, renderTargetMaterial)
	end

	self:DrawMonitorOverlay(monitor)
	cam.End2D()
end

function PLUGIN:SetupAndOrDrawHtml(monitor, renderTargetMaterial)
	if (IsValid(monitor.expVguiPanel)) then
		monitor.expVguiPanel:Remove()
	end

	if (not IsValid(monitor.expHtmlPanel)) then
		monitor.expHtmlPanelWidth = 64
		monitor.expHtmlPanelHeight = 64

		-- Find the nearest width and height to GetMonitorWidth and GetMonitorHeight that is a power of 2
		while (monitor.expHtmlPanelWidth < monitor:GetMonitorWidth()) do
			monitor.expHtmlPanelWidth = monitor.expHtmlPanelWidth * 2
		end

		while (monitor.expHtmlPanelHeight < monitor:GetMonitorHeight()) do
			monitor.expHtmlPanelHeight = monitor.expHtmlPanelHeight * 2
		end

		monitor.expHtmlPanel = vgui.Create("DHTML")
		monitor.expHtmlPanel:SetSize(monitor.expHtmlPanelWidth, monitor.expHtmlPanelHeight)
		-- monitor.expHtmlPanel:SetSize(renderTargetMaterial:Width(), renderTargetMaterial:Height())

		-- Hide the panel, we will only use the HTML material
		monitor.expHtmlPanel:SetAlpha(0)
		monitor.expHtmlPanel:SetMouseInputEnabled(false)
		monitor.expHtmlPanel:SetKeyboardInputEnabled(false)

		function monitor.expHtmlPanel:ConsoleMessage(msg) end

		monitor:CallOnRemove("expMonitorHtmlPanelRemove", function()
			if (IsValid(monitor.expHtmlPanel)) then
				monitor.expHtmlPanel:Remove()
			end
		end)
	end

	if (monitor.expMonitorTargetHtml ~= monitor.expHtmlPanelHtml) then
		if (monitor.expMonitorTargetHtml:StartsWith("http")) then
			monitor.expHtmlPanel:OpenURL(monitor.expMonitorTargetHtml)
		else
			monitor.expHtmlPanel:SetHTML(monitor.expMonitorTargetHtml)
		end
		monitor.expHtmlPanelHtml = monitor.expMonitorTargetHtml
	end

	monitor.expHtmlPanel:UpdateHTMLTexture()
	local htmlMaterial = monitor.expHtmlPanel:GetHTMLMaterial()

	if (htmlMaterial) then
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(htmlMaterial)
		surface.DrawTexturedRect(0, 0, monitor:GetMonitorWidth(), monitor:GetMonitorHeight())
	end
end

function PLUGIN:SetMonitorTargetHtml(monitor, html)
	monitor.expMonitorTargetHtml = html
	monitor.expMonitorTargetVgui = nil
end

function PLUGIN:SetupAndOrDrawVgui(monitor, renderTargetMaterial)
	if (IsValid(monitor.expHtmlPanel)) then
		monitor.expHtmlPanel:Remove()
	end

	if (not IsValid(monitor.expVguiPanel)) then
		monitor.expVguiPanel = vgui.Create("EditablePanel")
		monitor.expVguiPanel:SetSize(renderTargetMaterial:Width(), renderTargetMaterial:Height())
		monitor.expVguiPanel:SetPaintedManually(true)

		monitor:CallOnRemove("expMonitorVguiPanelRemove", function()
			if (IsValid(monitor.expVguiPanelVguiInstance)) then
				monitor.expVguiPanelVguiInstance:Remove()
			end
		end)
	end

	if (monitor.expMonitorTargetVgui ~= monitor.expVguiPanelVgui) then
		monitor.expVguiPanel:Clear()
		monitor.expVguiPanelVgui = monitor.expMonitorTargetVgui
		monitor.expVguiPanelVguiInstance = monitor.expMonitorTargetVgui(monitor.expVguiPanel)

		if (not IsValid(monitor.expVguiPanelVguiInstance)) then
			ix.util.SchemaErrorNoHalt("Invalid monitor target vgui function return value. Return a VGUI Panel!\n")
			return
		end

		-- Ensure it's parented to the monitor panel, otherwise it may not be removed when the panel is removed
		if (monitor.expVguiPanelVguiInstance:GetParent() ~= monitor.expVguiPanel) then
			monitor.expVguiPanelVguiInstance:SetParent(monitor.expVguiPanel)
		end

		if (monitor.expVguiPanelVguiInstance.SetMonitor) then
			monitor.expVguiPanelVguiInstance:SetMonitor(monitor)
		end
	end

	monitor.expVguiPanel:PaintManual()
end

function PLUGIN:SetMonitorTargetVgui(monitor, vguiFunction)
	monitor.expMonitorTargetVgui = vguiFunction
	monitor.expMonitorTargetHtml = nil
end

-- Handy for debugging:
GLOBAL_SetMonitorTarget = function(monitor, htmlOrVguiFunction)
	if (type(htmlOrVguiFunction) == "string") then
		-- lua_run_cl GLOBAL_SetMonitorTarget(ents.FindByClass("exp_monitor")[1], "<p style='color: white;'>hello world</p>")
		-- lua_run_cl GLOBAL_SetMonitorTarget(ents.FindByClass("exp_monitor")[1], "http://neverssl.com")
		PLUGIN:SetMonitorTargetHtml(monitor, htmlOrVguiFunction)
	elseif (type(htmlOrVguiFunction) == "function") then
		-- lua_run_cl GLOBAL_SetMonitorTarget(ents.FindByClass("exp_monitor")[1], function(parent) return vgui.Create("expMonitorTarget", parent) end)
		PLUGIN:SetMonitorTargetVgui(monitor, htmlOrVguiFunction)
	else
		print("Invalid monitor target type: " .. type(htmlOrVguiFunction))
	end
end

function PLUGIN:DrawMonitorOverlay(monitor)
	local width, height = monitor:GetMonitorWidth(), monitor:GetMonitorHeight()

	local texW, texH = 512, 512
	surface.SetDrawColor(200, 200, 200, 200)
	surface.SetMaterial(scanLinesMaterial)
	surface.DrawTexturedRectUV(0, 0, width, height, 0, 0, width / texW, height / texH)
end

function PLUGIN:RenderMonitorToPlayerView(monitor, renderTargetMaterial, renderTargetMaterialMirrored)
	local scale = monitor:GetMonitorScale() or 1
	local width, height = monitor:GetMonitorWidth() * scale, monitor:GetMonitorHeight() * scale
	local halfWidth = width * .5
	local halfHeight = height * .5
	local monitorPos = monitor:GetPos()
	local monitorRight = monitor:GetRight()
	local monitorUp = monitor:GetUp()

	monitorPos = monitorPos + monitorRight * -halfWidth
	monitorPos = monitorPos + monitorUp * -halfHeight

	local quadPoints = {}

	-- TODO: With DrawQuad we can use 4 points to draw the monitor, instead of trying to set it up with scaling and width/height conversions and whatnot.
	-- TODO: Change the config UI to let users set the 4 points (using their physgun or something) and then we can draw the monitor based on those points.
	quadPoints[1] = monitorPos + monitorRight * halfWidth + monitorUp * halfHeight
	quadPoints[2] = monitorPos - monitorRight * halfWidth + monitorUp * halfHeight
	quadPoints[3] = monitorPos - monitorRight * halfWidth - monitorUp * halfHeight
	quadPoints[4] = monitorPos + monitorRight * halfWidth - monitorUp * halfHeight

	render.SetMaterial(renderTargetMaterial)
	render.DrawQuad(
		quadPoints[1],
		quadPoints[2],
		quadPoints[3],
		quadPoints[4],
		Color(255, 255, 255, monitor.drawAlphaForeground)
	)

	if (renderTargetMaterialMirrored) then
		render.SetMaterial(renderTargetMaterialMirrored)
		render.DrawQuad(
			quadPoints[2],
			quadPoints[1],
			quadPoints[4],
			quadPoints[3],
			Color(255, 255, 255, monitor.drawAlphaBackground)
		)
	end
end
