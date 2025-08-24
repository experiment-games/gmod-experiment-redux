local PLUGIN = PLUGIN
local SCENE = SCENE

SCENE.cinematicSpawnID = "prologue_riot2"

function SCENE:OnEnterServer(client)
	Schema.instance.AddPlayer(client)

	timer.Simple(8, function()
		if (IsValid(client) and Schema.cinematics.IsPlayerInScene(client, self.uniqueID)) then
			-- Remove them from the prologue
			Schema.cinematics.RemovePlayerFromSceneFadeOut(client)
		end
	end)
end

function SCENE:OnLeaveServer(client)
	local instanceID = Schema.instance.GetPlayerInstance(client)
	Schema.instance.DestroyInstance(instanceID, "end_of_scene")

	Schema.progression.Change(client, "prologue", PLUGIN.PROGRESSION_INTRO_COMPLETED, true)

	client:GetCharacter():SetData("prologue_finished", true)

	client.expPrologueRiot3Items = nil
	client.expPrologueRiot3ManhacksSpawned = nil

	client:KillSilent()
	client:Spawn()

	-- Strip all items from the player in this flashback
	local character = client:GetCharacter()
	local inventory = character:GetInventory()

	for item, _ in inventory:Iter() do
		item:Remove()
	end

	hook.Run("PlayerFillDefaultInventory", client, character, inventory)
end

if (CLIENT) then
	function SCENE:OnDraw(width, height)
		surface.SetDrawColor(color_black)
		surface.DrawRect(0, 0, width, height)
	end

	function SCENE:OnEnterLocalPlayer()
		Schema.cinematics.ShowCinematicText({
			{ text = "Present Day",           delay = 0, duration = 5, horizontalAlignment = TEXT_ALIGN_LEFT,   verticalAlignment = TEXT_ALIGN_TOP },
			{ text = "Now it's up to you...", delay = 2, duration = 5, horizontalAlignment = TEXT_ALIGN_CENTER, verticalAlignment = TEXT_ALIGN_CENTER },
			{ text = "Will you fight back?",  delay = 4, duration = 5, horizontalAlignment = TEXT_ALIGN_RIGHT,  verticalAlignment = TEXT_ALIGN_BOTTOM },
		})
	end
end
