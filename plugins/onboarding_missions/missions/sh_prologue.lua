local PLUGIN = PLUGIN
local SCENE = SCENE

PLUGIN.SCENE_TRACKER_ID = "prologue#main"

-- Progression Keys for the introduction tutorial
PLUGIN.PROGRESSION_INTRO_STARTED = "intro_tutorial_started"
PLUGIN.PROGRESSION_INTRO_COMPLETED = "intro_tutorial_completed"
PLUGIN.PROGRESSION_GLOCK_PICKED_UP = "glock_picked_up"
PLUGIN.PROGRESSION_AMMO_PICKED_UP = "ammo_picked_up"
PLUGIN.PROGRESSION_GLOCK_EQUIPPED = "glock_equipped"
PLUGIN.PROGRESSION_GLOCK_ACTIVE = "glock_active"
PLUGIN.PROGRESSION_GLOCK_RAISED = "glock_raised"
PLUGIN.PROGRESSION_AMMO_LOADED = "ammo_loaded"
PLUGIN.PROGRESSION_MANHACKS_DEFEATED = "manhacks_defeated"
PLUGIN.PROGRESSION_MANHACKS_KILLED_COUNT = "manhacks_killed_count"

-- Tutorial Configuration
PLUGIN.REQUIRED_MANHACKS = 2

--[[
	Introduction Tutorial Tracker - Main tracker for the entire tutorial sequence
--]]

PLUGIN.INTRO_TUTORIAL_TRACKER = Schema.progression.RegisterTracker({
	--- Scope for the tutorial progression (could be global or player-specific)
	scope = "prologue",

	--- Unique identifier for this tracker
	uniqueID = PLUGIN.SCENE_TRACKER_ID,

	--- Name shown in the UI for this tracker
	name = "Prologue Weapon Tutorial",

	--- The key that marks this tutorial as completed
	completedKey = PLUGIN.PROGRESSION_INTRO_COMPLETED,

	--- The key that marks this tutorial as in-progress
	isInProgress = PLUGIN.PROGRESSION_INTRO_STARTED,

	--- Show the tracker on HUD by default
	showOnHUD = true,

	cannotAbandon = true
})

--[[
	Goal 1: Pick up the Glock 17 from the ground
--]]

PLUGIN.GOAL_PICKUP_GLOCK = PLUGIN.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	--- The key of the progression this goal tracks
	key = PLUGIN.PROGRESSION_GLOCK_PICKED_UP,

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

PLUGIN.GOAL_PICKUP_AMMO = PLUGIN.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_AMMO_PICKED_UP,
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

PLUGIN.GOAL_EQUIP_GLOCK = PLUGIN.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_GLOCK_EQUIPPED,
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

PLUGIN.GOAL_LOAD_AMMO = PLUGIN.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_AMMO_LOADED,
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

PLUGIN.GOAL_SWITCH_TO_GLOCK = PLUGIN.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_GLOCK_ACTIVE,
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

PLUGIN.GOAL_RAISE_GLOCK = PLUGIN.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_GLOCK_RAISED,
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

PLUGIN.GOAL_DEFEAT_MANHACKS = PLUGIN.INTRO_TUTORIAL_TRACKER:RegisterGoal({
	key = PLUGIN.PROGRESSION_MANHACKS_KILLED_COUNT,
	name = "Defeat the Manhacks",
	type = "number",

	getProgress = function(goal, player, progression)
		local killed = progression or 0
		local progress = math.min(killed / PLUGIN.REQUIRED_MANHACKS, 1)
		return progress, PLUGIN.REQUIRED_MANHACKS, killed
	end,
})
