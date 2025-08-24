local PLUGIN = PLUGIN
local SCENE = SCENE

SCENE.cinematicSpawnID = "prologue_riot1"

function SCENE:OnEnterServer(client)
	Schema.instance.AddPlayer(client)

	-- Randomize the NPCs a bit so even if they have the same animation they don't look identical
	for _, entity in ipairs(ents.FindInSphere(client:GetPos(), 1024)) do
		if (entity:GetClass() == "prop_dynamic" and not entity.expRandomizedCycle) then
			entity:SetCycle(math.random())
			entity.expRandomizedCycle = true
		end
	end

	timer.Simple(15, function()
		if (IsValid(client) and Schema.cinematics.IsPlayerInScene(client, self.uniqueID)) then
			Schema.cinematics.TransitionPlayerToScene(client, "prologue_riot2")
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
			{ text = "A place where even rioting was part of the schedule.",                   delay = 0,  duration = 9,  horizontalAlignment = TEXT_ALIGN_LEFT,  verticalAlignment = TEXT_ALIGN_CENTER },
			{ text = "A supposedly harmless experiment to test their crowd controlling AI...", delay = 2,  duration = 10, horizontalAlignment = TEXT_ALIGN_LEFT,  verticalAlignment = TEXT_ALIGN_CENTER },
			{ text = "Nemesis AI...",                                                          delay = 10, duration = 10, horizontalAlignment = TEXT_ALIGN_RIGHT, verticalAlignment = TEXT_ALIGN_CENTER },
		})

		Schema.cinematics.SetFogData(50, 850, color_black, 1)
		Schema.cinematics.SetBlackAndWhite(true)

		local nemesisPlugin = ix.plugin.Get("nemesis_ai")

		if (nemesisPlugin) then
			nemesisPlugin:SetClientSpecificMonitorVgui("prologue_riot1", function(parent)
				return vgui.Create("expPrologueMonitorRiot1", parent)
			end)
		end
	end

	function SCENE:OnLeaveLocalPlayer()
		local nemesisPlugin = ix.plugin.Get("nemesis_ai")

		if (nemesisPlugin) then
			nemesisPlugin:ClearClientSpecificMonitorVgui("prologue_riot1")
		end
	end
end

hook.Add("ExperimentMonitorsFilter", "expPrologueRiot1DisableNormalBehaviour", function(monitors, filterType)
	for i = #monitors, 1, -1 do
		local monitor = monitors[i]
		local specialID = monitor:GetSpecialID()

		if (specialID and specialID == "prologue_riot1") then
			table.remove(monitors, i)
		end
	end
end)
