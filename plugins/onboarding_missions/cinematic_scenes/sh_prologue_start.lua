local PLUGIN = PLUGIN
local SCENE = SCENE

SCENE.cinematicSpawnID = "prologue_gateway"

function SCENE:OnEnterServer(client)
	Schema.instance.AddPlayer(client)

	timer.Simple(8, function()
		if (IsValid(client) and Schema.cinematics.IsPlayerInScene(client, self.uniqueID)) then
			Schema.cinematics.TransitionPlayerToScene(client, "prologue_gateway")
		end
	end)
end

function SCENE:OnLeaveServer(client)
	local instanceID = Schema.instance.GetPlayerInstance(client)
	Schema.instance.DestroyInstance(instanceID, "end_of_scene")
end

if (CLIENT) then
	function SCENE:OnDraw(width, height)
		surface.SetDrawColor(color_black)
		surface.DrawRect(0, 0, width, height)
	end

	function SCENE:OnEnterLocalPlayer()
		Schema.cinematics.ShowCinematicText({
			{ text = "Prologue",          delay = 0, duration = 6, horizontalAlignment = TEXT_ALIGN_LEFT,  verticalAlignment = TEXT_ALIGN_TOP },
			{ text = "Some years ago...", delay = 2, duration = 6, horizontalAlignment = TEXT_ALIGN_RIGHT, verticalAlignment = TEXT_ALIGN_BOTTOM },
		})
	end

	-- Hide the buff hud panel until we finish the entire prologue
	hook.Add("ShouldShowBuffsHUD", "expPrologueGatewayShouldShowBuffsHUD", function()
		local client = LocalPlayer()
		local character = client:GetCharacter()

		if (character and not character:GetData("prologue_finished")) then
			return false
		end
	end)
end

if (SERVER) then
	-- Note: If we every remove this, be sure to call `hook.Run("PlayerFillDefaultInventory", client, character, inventory)` for newly created
	-- characters, or change all occurrences of PlayerFillDefaultInventory to work with OnCharacterCreated.
	-- Show the prologue instead of the normal spawn point selection.
	hook.Add("ShouldShowSpawnSelection", "expPrologueGatewayShouldShowSpawnSelection", function(client)
		local character = client:GetCharacter()

		if (not character:GetData("prologue_finished")) then
			-- We must delay a frame, otherwise the player's hands wont have been parented to their predicted viewmodel yet, causing issues with those
			-- being in a different instance
			timer.Simple(0, function()
				if (IsValid(client)) then
					local scene = "prologue_start"

					if (PLUGIN.INTRO_TUTORIAL_TRACKER:IsInProgress(client)) then
						scene = "prologue_riot3"
					end

					-- ShouldShowSpawnSelection might be called twice from PostPlayerLoadout
					if (not Schema.cinematics.IsPlayerInScene(client, scene)) then
						Schema.cinematics.PutPlayerInScene(client, scene)
					end
				end
			end)

			return false
		end
	end)
end
