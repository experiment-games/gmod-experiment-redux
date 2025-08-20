--- @realm shared
--- @class ProgressionTrackerGoalInfo
--- @field key string The key of the progression this goal tracks
--- @field name string|fun(tracker: ProgressionTracker, goal: ProgressionTrackerGoal):(string) The name of the goal shown in the UI
--- @field type "number"|"boolean" The type of the progression value
--- @field getProgress fun(goal: ProgressionTrackerGoal, player: Player, progression: ProgressionValue): (number|boolean, any, any)
--- @field isVisible fun(goal: ProgressionTrackerGoal): (boolean) Whether the goal should be visible in the UI

--- @realm shared
--- @class ProgressionTrackerGoal : ProgressionTrackerGoalInfo
--- @field private tracker? ProgressionTracker The tracker this goal belongs to
local META = Schema.meta.progressionTrackerGoal or {}
Schema.meta.progressionTrackerGoal = META

META.__index = META

--- Gets the scope of the parent tracker, which is used to identify the progression.
--- @return string
--- @realm shared
function META:GetScope()
	return self.tracker:GetScope()
end

--- Gets the key of the goal which identifies it within a scope.
--- @return string
--- @realm shared
function META:GetKey()
	return self.key
end

--- Gets the parent tracker this goal belongs to.
--- @return ProgressionTracker
--- @realm shared
function META:GetTracker()
	return self.tracker
end

--- Sets the parent tracker this goal belongs to. This is automatically set
--- when adding a goal to a tracker and should not need to be set manually.
--- @param tracker ProgressionTracker
--- @realm shared
function META:SetTracker(tracker)
	self.tracker = tracker
end

--- Gets the name of the goal.
--- @return string
--- @realm shared
function META:GetName()
	if (isfunction(self.name)) then
		return self.name(self.tracker, self)
	end

	return self.name
end

--- Gets progress information for the player by calling the goal's getProgress function.
--- @param player Player
--- @param progression ProgressionValue
--- @return number|boolean, any, any # The progress (fraction or bool), maximum and current value
--- @realm shared
function META:GetProgress(player, progression)
	return self:getProgress(player, progression)
end

--- Gets whether this goal should be visible in the UI.
--- @return boolean
--- @realm shared
function META:IsVisible()
	if (isfunction(self.isVisible)) then
		return self:isVisible()
	end

	return true
end

if (SERVER) then
	--- Checks the player's progress
	--- @param player Player
	--- @return boolean
	--- @realm server
	function META:CheckProgress(player)
		local scope = self:GetScope()
		local key = self:GetKey()
		local currentValue = Schema.progression.Get(player, scope, key)
		local progress = self:GetProgress(player, currentValue)

		-- If the progress is a number, we assume it's a fraction of completion
		if (isnumber(progress)) then
			return progress >= 1
		end

		-- If the progress is a boolean, we assume it's a completion state
		--- @type boolean
		return progress
	end

	--- Changes the goal value
	--- @param player Player
	--- @param value ProgressionValue|fun(ProgressionValue):(ProgressionValue)
	--- @return any # The new value
	--- @realm server
	function META:Change(player, value)
		return Schema.progression.Change(player, self:GetScope(), self.key, value)
	end
elseif (CLIENT) then
	--- Checks the local player's progress
	--- @return boolean
	--- @realm client
	function META:CheckProgress()
		local scope = self:GetScope()
		local key = self:GetKey()
		local currentValue = Schema.progression.Get(scope, key)
		local progress = self:GetProgress(LocalPlayer(), currentValue)

		-- If the progress is a number, we assume it's a fraction of completion
		if (isnumber(progress)) then
			return progress >= 1
		end

		-- If the progress is a boolean, we assume it's a completion state
		--- @type boolean
		return progress
	end
end
