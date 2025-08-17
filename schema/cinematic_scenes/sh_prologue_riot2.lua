local SCENE = SCENE

SCENE.cinematicSpawnID = "prologue_riot2"

if (SERVER) then
	function SCENE:OnEnterServer(client)
		Schema.instance.AddPlayer(client)

		timer.Simple(15, function()
			if (IsValid(client) and Schema.cinematics.IsPlayerInScene(client, self.uniqueID)) then
				Schema.cinematics.TransitionPlayerToScene(client, "prologue_riot3")
			end
		end)
	end
end

if (CLIENT) then
	function SCENE:OnEnterLocalPlayer()
		Schema.cinematics.ShowCinematicText({
			{ text = "That illusion shattered the day the Nemesis AI", delay = 0, duration = 8, horizontalAlignment = TEXT_ALIGN_LEFT, verticalAlignment = TEXT_ALIGN_CENTER },
			{ text = "showed us its true, unaligned nature.",          delay = 2, duration = 8, horizontalAlignment = TEXT_ALIGN_LEFT, verticalAlignment = TEXT_ALIGN_CENTER },
		})

		Schema.cinematics.SetFogData(50, 850, color_black, 1)
		Schema.cinematics.SetBlackAndWhite(true)

		local nemesisPlugin = ix.plugin.Get("nemesis_ai")

		if (nemesisPlugin) then
			nemesisPlugin:SetClientSpecificMonitorVgui("prologue_riot2", function(parent)
				return vgui.Create("expPrologueMonitorRiot2", parent)
			end)
		end
	end

	function SCENE:OnLeaveLocalPlayer()
		local nemesisPlugin = ix.plugin.Get("nemesis_ai")

		if (nemesisPlugin) then
			nemesisPlugin:ClearClientSpecificMonitorVgui("prologue_riot2")
		end

		Schema.cinematics.StopCinematicSound(3.0)
	end
end

hook.Add("ExperimentMonitorsFilter", "expPrologueRiot2DisableNormalBehaviour", function(monitors, filterType)
	for i = #monitors, 1, -1 do
		local monitor = monitors[i]
		local specialID = monitor:GetSpecialID()

		if (specialID and specialID == "prologue_riot2") then
			table.remove(monitors, i)
		end
	end
end)
