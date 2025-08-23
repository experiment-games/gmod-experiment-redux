local function assertGoal(goal, expression, message)
	if (not expression) then
		error("Goal " .. goal.key .. ": " .. message)
	end
end

--- @realm shared
--- @alias ProgressionKey { key: string, type: string }

--- @realm shared
--- @alias ProgressionTrackerCheck fun(tracker: ProgressionTracker, player: Player): boolean

--- @realm shared
--- @class ProgressionTrackerInfo
---
--- @field scope string The scope of the progression values
--- @field uniqueID string The unique identifier for this tracker
--- @field name string|fun(tracker: ProgressionTracker):(string) The name shown in the UI for this tracker (e.g: the mission name)
---
--- @field completedKey string|boolean The key (string) of the progression that marks this tracker as completed, or false if it never completes
--- @field isInProgress string|ProgressionTrackerCheck The key (string) of the progression that marks this tracker as in-progress, or a function that checks if the tracker is in-progress
--- @field showOnHUD? boolean Whether the tracker should be shown on the HUD by default
--- @field cannotAbandon? boolean Whether the tracker cannot be abandoned by the player
--- @field serverOnAbandon? fun(tracker: ProgressionTracker, player: Player) A function that is called when the tracker is abandoned by the player

--- Wrapper over the progression system to handle easily tracking progression values.
--- This is useful for creating missions, quests, achievements, etc. without having
--- to deal with individual progression values.
--- @realm shared
--- @class ProgressionTracker : ProgressionTrackerInfo
---
--- @field isDynamic? boolean Whether the tracker is dynamically created
--- @field goals? ProgressionTrackerGoal[] The goals that are being tracked
--- @field progressionKeys? ProgressionKey[] The progression keys that are being tracked
local META = Schema.meta.progressionTracker or {}
Schema.meta.progressionTracker = META

META.__index = META

--- Gets the scope that identifies progression values for this tracker.
--- ProgressionTrackerGoal's that belong to this tracker will use this scope
--- and supplement it with their own key.
--- This way you can track multiple values in a tracker (e.g: quest/mission)
--- grouped together under the same scope.
--- @return string
--- @realm shared
function META:GetScope()
	return self.scope
end

--- Gets the unique identifier for this tracker. This can be used to
--- find the tracker in the progression system.
--- @return string
--- @realm shared
function META:GetUniqueID()
	return self.uniqueID
end

--- Gets the name of the tracker. Displayed in the UI.
--- @return string
--- @realm shared
function META:GetName()
	if (isfunction(self.name)) then
		return self.name(self)
	end

	return self.name
end

--- Gets the key of the progression that marks this tracker as completed. This
--- is used by the `CheckCompleted` function to determine if the tracker is completed.
--- @return string|boolean # The key of the progression that marks this tracker as completed, or false if it never completes
--- @realm shared
function META:GetCompletedKey()
	return self.completedKey
end

--- Gets the goals that belong to this tracker.
--- @return ProgressionTrackerGoal[]
--- @realm shared
function META:GetGoals()
	return self.goals
end

--- Finds a goal that belongs to this tracker by its key.
--- @param key string
--- @return ProgressionTrackerGoal?
--- @realm shared
function META:FindGoal(key)
	for _, goal in ipairs(self.goals) do
		if (goal.key == key) then
			return goal
		end
	end
end

--- Gets the progression keys that are being tracked by this tracker. This
--- is only used by the Progression Editor and NPC Editor to display the
--- progressions keys related to a tracker (mission/quest).
--- @realm shared
function META:GetProgressionKeys()
	return self.progressionKeys
end

--- @realm shared
function META:GetIsInProgressKey()
	return self.isInProgress
end

--- Finds a progression key belonging to this tracker by its key.
--- @param key string
--- @return any?
--- @realm shared
function META:FindProgressionKey(key)
	for _, progressionKey in ipairs(self.progressionKeys) do
		if (progressionKey.key == key) then
			return progressionKey
		end
	end
end

--- Gets whether a tracker can be abandoned by the player.
--- @return boolean
--- @realm shared
function META:CanAbandon()
	return self.cannotAbandon ~= true
end

--- Initializes/resets the goals table. Only used internally.
--- @realm shared
function META:InitGoals()
	self.goals = {}
end

--- Registers a goal to the tracker so it can be displayed in the UI. Unlike
--- progression keys, goals are visible to the player and can be seen as
--- objectives that need to be completed to complete the tracker (mission/quest).
--- @param goalInfo ProgressionTrackerGoalInfo
--- @return ProgressionTrackerGoal
--- @realm shared
function META:RegisterGoal(goalInfo)
	assertGoal(goalInfo.key, "Goal must have a key")
	assertGoal(goalInfo.getProgress, "Goal must have a getProgress function")
	assertGoal(goalInfo.type, "Goal must have a type parameter")
	assertGoal(
		goalInfo.type == "boolean"
		or goalInfo.type == "number",
		"Goal must have a type parameter of 'boolean' or 'number'"
	)

	--- @cast goalInfo ProgressionTrackerGoal
	local goal = setmetatable(goalInfo, Schema.meta.progressionTrackerGoal)
	goal:SetTracker(self)
	table.insert(self.goals, goal)

	return goal
end

if (SERVER) then
	--- Checks whether the tracker is completed by checking all goals.
	--- @param player Player
	--- @return boolean
	--- @realm server
	function META:CheckCompleted(player)
		for _, goal in ipairs(self.goals) do
			if (not goal:CheckProgress(player)) then
				return false
			end
		end

		return true
	end

	--- Marks the tracker as completed. Should be used if all goals are completed.
	--- @param player Player
	--- @realm server
	function META:Complete(player)
		if (not self.completedKey) then
			return
		end

		Schema.progression.Change(player, self.scope, self.completedKey, true)
	end

	--- Checks if the tracker is marked as completed.
	--- @param player Player
	--- @return boolean
	--- @realm server
	function META:IsCompleted(player)
		if (not self.completedKey) then
			return false
		end

		return Schema.progression.Check(player, self.scope, self.completedKey, true)
	end

	--- Checks if the tracker is in-progress.
	--- @param player Player
	--- @return boolean
	--- @realm server
	function META:IsInProgress(player)
		if (isfunction(self.isInProgress)) then
			return self.isInProgress(self, player)
		end

		--- @type string
		--- @diagnostic disable-next-line: assign-type-mismatch
		local isInProgressKey = self.isInProgress

		return Schema.progression.Check(player, self.scope, isInProgressKey, true)
	end

	--- Sets the tracker to be in-progress.
	--- @param player Player
	--- @realm server
	function META:Start(player)
		if (not self.isInProgress) then
			return
		end

		--- @type string
		--- @diagnostic disable-next-line: assign-type-mismatch
		local isInProgressKey = self.isInProgress

		Schema.progression.Change(player, self.scope, isInProgressKey, true)
	end
elseif (CLIENT) then
	--- Checks whether the tracker is completed by checking all goals.
	--- @return boolean
	--- @realm client
	function META:CheckCompleted()
		for _, goal in ipairs(self.goals) do
			if (not goal:CheckProgress()) then
				return false
			end
		end

		return true
	end

	--- Checks if the tracker is marked as completed.
	--- @return boolean
	--- @realm client
	function META:IsCompleted()
		return Schema.progression.Check(self.scope, self.completedKey, true)
	end

	--- Checks if the tracker is in-progress.
	--- @return boolean
	--- @realm client
	function META:IsInProgress()
		if (isfunction(self.isInProgress)) then
			return self.isInProgress(self, LocalPlayer())
		end

		--- @type string
		--- @diagnostic disable-next-line: assign-type-mismatch
		local isInProgressKey = self.isInProgress

		return Schema.progression.Check(self.scope, isInProgressKey, true)
	end
end
