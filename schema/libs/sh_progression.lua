--- Shared library to handle progression tracking. Allows creating missions/quests,
--- achievements, faction relationships, interaction progression and more.
--- @realm shared
Schema.progression = ix.util.GetOrCreateLibrary("progression", {
	-- Where trackers are stored
	trackers = {},

	-- Map of trackers by their unique ID and scope for quick access
	trackersByID = {},
	trackersByScope = {},

	--- Where dynamic trackers are stored (created on the server and networked to the client in full)
	--- @type table<string, ProgressionTracker>
	dynamicTrackers = {},
})

--- @realm shared
--- @class ProgressionNetworkTable
--- @field scope string
--- @field key string
--- @field value ProgressionValue

--- @realm shared
--- @class DynamicProgressionNetworkTable
--- @field progressionTracker ProgressionTrackerInfo
--- @field keys table<string, ProgressionValue>

--- @realm shared
--- @alias ProgressionGetProgressCallback fun(goal: ProgressionTrackerGoal, player: Player, progression: ProgressionValue):(...)

--- Used internally to register a tracker in the progression library, as well as store it in
--- tables for quick access.
--- @param tracker ProgressionTracker
--- @realm shared
function Schema.progression.StoreTracker(tracker)
	table.insert(Schema.progression.trackers, tracker)
	Schema.progression.trackersByID[tracker.uniqueID] = tracker
	Schema.progression.trackersByScope[tracker.scope] = Schema.progression.trackersByScope[tracker.scope] or {}
	Schema.progression.trackersByScope[tracker.scope][tracker.uniqueID] = tracker
end

--- Creates a new progression tracker.
--- @param trackerInfo ProgressionTrackerInfo
--- @return ProgressionTracker
--- @realm shared
function Schema.progression.RegisterTracker(trackerInfo)
	-- To support Lua refreshing, we first try to see if this progression tracker
	-- already exists. If it does, we update it. If it doesn't, we create it.
	local tracker = Schema.progression.GetTracker(trackerInfo.uniqueID)

	--- @cast trackerInfo ProgressionTracker
	if (tracker) then
		-- Merge, replacing subtables so we don't have to worry about clearing
		-- the goals and progression keys on editing with the npc editor (so
		-- they don't keep already removed keys).
		table.Merge(tracker, trackerInfo, true)
	else
		tracker = setmetatable(trackerInfo, Schema.meta.progressionTracker)

		Schema.progression.StoreTracker(tracker)
	end

	--- When Lua refreshes, we want to ensure the new responses do not
	--- append to the old responses. So we wipe the responses table.
	--- Shortly after this the responses will be re-registered anyway.
	tracker:InitGoals()

	return tracker
end

--- Unregisters a progression tracker from the progression library.
--- @param tracker ProgressionTracker
--- @realm shared
function Schema.progression.UnRegisterTracker(tracker)
	for scope, otherTracker in pairs(Schema.progression.trackers) do
		if (tracker == otherTracker) then
			table.remove(Schema.progression.trackers, scope)
			break
		end
	end

	Schema.progression.trackersByID[tracker.uniqueID] = nil

	for scope, otherTracker in pairs(Schema.progression.trackersByScope[tracker.scope]) do
		if (tracker == otherTracker) then
			Schema.progression.trackersByScope[tracker.scope][scope] = nil
			break
		end
	end
end

--- Gets a progression tracker by its unique ID.
--- @param uniqueID string
--- @return ProgressionTracker?
--- @realm shared
function Schema.progression.GetTracker(uniqueID)
	return Schema.progression.trackersByID[uniqueID]
end

--- Gets a progression trackers by their scope and optionally by their isInProgress key.
--- @param scope string
--- @param isInProgressKey string
--- @return table<string, ProgressionTracker>
--- @realm shared
function Schema.progression.GetTrackersByScope(scope, isInProgressKey)
	local trackers = {}

	for uniqueID, tracker in pairs(Schema.progression.trackersByScope[scope] or {}) do
		if (isInProgressKey == nil or tracker.isInProgress == isInProgressKey) then
			trackers[uniqueID] = tracker
		end
	end

	return trackers
end

--- Gets a debug string listing all active progression trackers for a player.
--- @param player Player
--- @return string
--- @realm shared
function Schema.progression.GetDebugString(player)
	local progressions

	if (SERVER) then
		progressions = Schema.progression.GetProgressions(player)
	else
		progressions = Schema.progression.stored
	end

	local debugString = "Progression for " .. player:Name() .. ":\n"

	-- A progression tracker has a unique id and belongs to a scope.
	-- We want a list of all relevant progression trackers for this player.
	for scope, scopeProgressions in pairs(progressions) do
		local trackers = Schema.progression.GetTrackersByScope(scope)

		for uniqueID, tracker in pairs(trackers) do
			if (tracker:IsCompleted(player)) then
				debugString = debugString .. ("  %s: Completed\n"):format(tracker:GetName())
			elseif (tracker:IsInProgress(player)) then
				local goals = tracker:GetGoals()

				debugString = debugString .. ("  %s:\n"):format(tracker:GetName())

				for _, goal in ipairs(goals) do
					local key = goal:GetKey()
					local currentValue = scopeProgressions[key]
					local progress = goal:GetProgress(player, currentValue)

					debugString = debugString .. ("    - %s: %s\n"):format(key, tostring(progress))
				end
			end
		end
	end

	return debugString
end

--- Sets up a GetProgress callback for the progression tracker. This is used to get the
--- return values from a user defined script.
--- > [!WARNING]
--- > This function exposes a security risk. Ensure that only trusted users have access to
--- > write scripts (e.g. server owners, developers, super admins).
--- > The script is run in the same environment as the rest of the game, so could be used
--- > to run malicious code (e.g. deleting files, granting permissions, giving items and
--- > anything else that Lua can do).
--- @param tracker ProgressionTracker
--- @param script string
--- @return ProgressionGetProgressCallback
--- @realm shared
function Schema.progression.CreateGetProgressScript(tracker, script)
	return function(goal, player, progression)
		if (progression == nil) then
			if (goal.type == "number") then
				progression = 0
			elseif (goal.type == "boolean") then
				progression = false
			else
				Schema.Error("Invalid goal type %s", goal.type)
			end
		end

		local results, resultCount = Schema.RunString(script, {
			goal = goal,
			player = player,
			progression = progression,
			tracker = tracker
		})

		return unpack(results, 1, resultCount)
	end
end

--- Returns whether the player has access to manage progressions.
--- @param client Player
--- @return boolean
--- @realm shared
function Schema.progression.HasManagePermission(client)
	return client:HasFlags("o")
end

if (CLIENT) then
	concommand.Add("exp_progress_debug_cl", function()
		local debug = Schema.progression.GetDebugString(LocalPlayer())

		print(debug)
	end)
else
	concommand.Add("exp_progress_debug_sv", function(player)
		local debug = Schema.progression.GetDebugString(player)

		print(debug)
	end)
end
