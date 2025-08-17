local SCENE = SCENE

SCENE.SCENE_TRACKER_ID = "prologue#main"

-- Progression Keys for the introduction tutorial
SCENE.PROGRESSION_INTRO_STARTED = "intro_tutorial_started"
SCENE.PROGRESSION_INTRO_COMPLETED = "intro_tutorial_completed"
SCENE.PROGRESSION_GLOCK_PICKED_UP = "glock_picked_up"
SCENE.PROGRESSION_AMMO_PICKED_UP = "ammo_picked_up"
SCENE.PROGRESSION_GLOCK_EQUIPPED = "glock_equipped"
SCENE.PROGRESSION_GLOCK_ACTIVE = "glock_active"
SCENE.PROGRESSION_GLOCK_RAISED = "glock_raised"
SCENE.PROGRESSION_AMMO_LOADED = "ammo_loaded"
SCENE.PROGRESSION_MANHACKS_DEFEATED = "manhacks_defeated"
SCENE.PROGRESSION_MANHACKS_KILLED_COUNT = "manhacks_killed_count"

-- Tutorial Configuration
SCENE.REQUIRED_MANHACKS = 2

--[[
	Introduction Tutorial Tracker - Main tracker for the entire tutorial sequence
--]]

SCENE.INTRO_TUTORIAL_TRACKER = Schema.progression.RegisterTracker({
	--- Scope for the tutorial progression (could be global or player-specific)
	scope = "prologue",

	--- Unique identifier for this tracker
	uniqueID = SCENE.SCENE_TRACKER_ID,

	--- Name shown in the UI for this tracker
	name = "Introduction Tutorial",

	--- The key that marks this tutorial as completed
	completedKey = SCENE.PROGRESSION_INTRO_COMPLETED,

	--- The key that marks this tutorial as in-progress
	isInProgress = SCENE.PROGRESSION_INTRO_STARTED,
})

--[[
	Goal 1: Pick up the Glock 17 from the ground
--]]

SCENE.GOAL_PICKUP_GLOCK = SCENE.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	--- The key of the progression this goal tracks
	key = SCENE.PROGRESSION_GLOCK_PICKED_UP,

	--- The name of the goal shown in the UI
	name = "Pick up the Glock 17 from the ground",

	--- The type of this progression (boolean for completion)
	type = "boolean",

	--- Progress function for this goal
	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,
})

--[[
	Goal 2: Pick up the ammo from the ground
--]]

SCENE.GOAL_PICKUP_AMMO = SCENE.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	key = SCENE.PROGRESSION_AMMO_PICKED_UP,
	name = "Pick up the ammunition from the ground",
	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,
})

--[[
	Goal 3: Equip the Glock 17
--]]

SCENE.GOAL_EQUIP_GLOCK = SCENE.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	key = SCENE.PROGRESSION_GLOCK_EQUIPPED,
	name = "Equip the Glock 17",
	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,
})

--[[
	Goal 4: Load the ammo into the Glock
--]]

SCENE.GOAL_LOAD_AMMO = SCENE.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	key = SCENE.PROGRESSION_AMMO_LOADED,
	name = "Load ammunition into the Glock",
	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,
})

--[[
	Goal 5: Switch to the Glock
--]]

SCENE.GOAL_SWITCH_TO_GLOCK = SCENE.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	key = SCENE.PROGRESSION_GLOCK_ACTIVE,
	name = "Switch to the Glock",
	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,
})

--[[
	Goal 6: Raise the Glock
--]]

SCENE.GOAL_RAISE_GLOCK = SCENE.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	key = SCENE.PROGRESSION_GLOCK_RAISED,
	name = "Raise the Glock",
	type = "boolean",

	getProgress = function(goal, player, progression)
		local isCompleted = progression or false
		return isCompleted, "1", isCompleted and "1" or "0"
	end,
})

--[[
	Goal 6: Defend against the manhacks
--]]

SCENE.GOAL_DEFEAT_MANHACKS = SCENE.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	key = SCENE.PROGRESSION_MANHACKS_KILLED_COUNT,
	name = "Defeat the Manhacks",
	type = "number",

	getProgress = function(goal, player, progression)
		local killed = progression or 0
		local progress = math.min(killed / SCENE.REQUIRED_MANHACKS, 1)
		return progress, SCENE.REQUIRED_MANHACKS, killed
	end,
})

--[[
	Example Progression
--]]

--[[

-- Call this when player kills a manhack
function OnManhackKilled(player)
	if Schema.progression.Check(player, "prologue", SCENE.PROGRESSION_INTRO_STARTED, true) then
		-- Increment manhack kill count
		Schema.progression.Change(player, "prologue", SCENE.PROGRESSION_MANHACKS_KILLED_COUNT, function(value)
			return (value or 0) + 1
		end)

		-- Check if all manhacks are defeated
		local killedCount = Schema.progression.Get(player, "prologue", SCENE.PROGRESSION_MANHACKS_KILLED_COUNT) or 0

		if killedCount >= SCENE.REQUIRED_MANHACKS then
			Schema.progression.Change(player, "prologue", SCENE.PROGRESSION_MANHACKS_DEFEATED, true)
			Schema.progression.Change(player, "prologue", SCENE.PROGRESSION_INTRO_COMPLETED, true)
			player:Notify("Tutorial Complete! Well done, survivor!")
		else
			player:Notify("Tutorial: Manhack defeated! (" .. killedCount .. "/" .. SCENE.REQUIRED_MANHACKS .. ")")
		end
	end
end
]]
