local SCENE = SCENE

SCENE.cinematicSpawnID = "prologue_gateway"

function SCENE:OnEnterServer(client)
	Schema.instance.AddPlayer(client)

	timer.Simple(10, function()
		if (IsValid(client) and Schema.cinematics.IsPlayerInScene(client, self.uniqueID)) then
			Schema.cinematics.TransitionPlayerToScene(client, "prologue_riot1")
		end
	end)
end

function SCENE:OnLeaveServer(client)
	local instanceID = Schema.instance.GetPlayerInstance(client)
	Schema.instance.DestroyInstance(instanceID, "end_of_scene")
end

if (CLIENT) then
	function SCENE:OnEnterLocalPlayer()
		Schema.cinematics.ShowCinematicText({
			{ text = "The Guardian Testing Facility.", delay = 0, duration = 5, horizontalAlignment = TEXT_ALIGN_CENTER, verticalAlignment = TEXT_ALIGN_CENTER },
			{ text = "A place they told us was safe.", delay = 2, duration = 5, horizontalAlignment = TEXT_ALIGN_CENTER, verticalAlignment = TEXT_ALIGN_CENTER },
		})

		Schema.cinematics.SetFogData(50, 750, color_black, 1)
		Schema.cinematics.SetBlackAndWhite(true)

		Schema.cinematics.PlayCinematicSound("music/HL2_song6.mp3", 0.2, 2.0)

		-- Show only to this client some welcome information on the nemesis monitors
		local nemesisPlugin = ix.plugin.Get("nemesis_ai")

		if (nemesisPlugin) then
			nemesisPlugin:SetClientSpecificMonitorVgui("prologue_gateway", function(parent)
				return vgui.Create("expPrologueMonitorGateway", parent)
			end)
		end
	end

	function SCENE:OnLeaveLocalPlayer()
		local nemesisPlugin = ix.plugin.Get("nemesis_ai")

		if (nemesisPlugin) then
			nemesisPlugin:ClearClientSpecificMonitorVgui("prologue_gateway")
		end
	end
end

hook.Add("ExperimentMonitorsFilter", "expPrologueGatewayDisableNormalBehaviour", function(monitors, filterType)
	for i = #monitors, 1, -1 do
		local monitor = monitors[i]
		local specialID = monitor:GetSpecialID()

		if (specialID and specialID == "prologue_gateway") then
			table.remove(monitors, i)
		end
	end
end)
