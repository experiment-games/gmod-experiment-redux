--- Server library to manage (dynamic) progressions and progression trackers. As
--- well as to manage them for players.
Schema.progression = ix.util.GetOrCreateLibrary("progression")

util.AddNetworkString("expProgressionItemHeader")
util.AddNetworkString("expProgressionItem")
util.AddNetworkString("expProgressionRemove")
util.AddNetworkString("expProgressionAbandonTracker")

--- @alias ProgressionValue string|number|table|boolean|nil

--- Gets the progressions for a player
--- where progressions that need to be saved are referenced.
--- @param player Player
--- @return table # The progressions
function Schema.progression.GetProgressions(player)
	local character = player:GetCharacter()
	local progressions = character:GetData("progressions")

	if (not progressions) then
		progressions = {}
		character:SetData("progressions", progressions)
	end

	return progressions
end

--- Gets the dynamic progressions for a player.
--- @param player Player
--- @return table<string, table<string, ProgressionValue>> # The dynamic progressions
function Schema.progression.GetDynamicProgressions(player)
	local character = player:GetCharacter()
	local progressions = character:GetData("progressions", {})
	local dynamicProgressions = {}

	for scope, keys in pairs(progressions) do
		local dynamicProgression = Schema.progression.GetDynamicByScope(scope)

		if (dynamicProgression) then
			dynamicProgressions[scope] = keys
		end
	end

	return dynamicProgressions
end

--- Gets the directory where dynamically created progressions are saved.
--- @return string
function Schema.progression.GetSaveFileDirectory()
	return "progressions/dynamic"
end

--- Gets the file path where dynamically created progressions are saved.
--- @param uniqueID string The unique identifier for the progression
--- @return string
function Schema.progression.GetSaveFile(uniqueID)
	return ("%s/%s.json"):format(Schema.progression.GetSaveFileDirectory(), uniqueID)
end

--- Saves dynamically created progression data so it can be loaded again
--- after a map change or server restart.
--- @param data table
function Schema.progression.Save(data)
	local file = Schema.progression.GetSaveFile(data.uniqueID)

	Schema.util.SaveSchemaData(file, data)
end

--- Destroys the dynamically created progression data with the given uniqueID.
--- @param uniqueID string
function Schema.progression.Destroy(uniqueID)
	local file = Schema.progression.GetSaveFile(uniqueID)

	Schema.util.DeleteSchemaData(file)
end

--- Initialize dynamically created progression data.
--- @param trackerInfo ProgressionTrackerInfo
function Schema.progression.RegisterDynamic(trackerInfo)
	--- @cast trackerInfo ProgressionTracker
	local goals = trackerInfo.goals

	-- Don't confuse RegisterTracker with this data
	trackerInfo.goals = nil
	trackerInfo.isDynamic = true

	trackerInfo.isInProgress = function(player, progression)
		-- TODO: Use isInProgressInfo.type and isInProgressInfo.value to return a value
		return false
	end

	trackerInfo = Schema.progression.RegisterTracker(trackerInfo)

	Schema.progression.dynamicTrackers[trackerInfo.uniqueID] = trackerInfo

	if (goals) then
		for _, goalInfo in ipairs(goals) do
			local goal = trackerInfo:RegisterGoal({
				key = goalInfo.key,
				name = goalInfo.name,
				getProgressScript = goalInfo.getProgressScript,
				getProgress = Schema.progression.CreateGetProgressScript(trackerInfo, goalInfo.getProgressScript),

				-- Needed to cast later
				type = goalInfo.type,
			})
		end
	end

	return trackerInfo
end

--- Get a dynamically created progression tracker.
--- @param uniqueID string
--- @return ProgressionTrackerInfo?
--- @nodiscard
function Schema.progression.GetDynamic(uniqueID)
	return Schema.progression.dynamicTrackers[uniqueID]
end

--- Get all dynamically created progression trackers.
--- @return table<string, ProgressionTrackerInfo>
--- @nodiscard
function Schema.progression.GetAllDynamic()
	return Schema.progression.dynamicTrackers
end

--- Get a dynamically created progression tracker.
--- @param scope string
--- @return ProgressionTrackerInfo?
--- @nodiscard
function Schema.progression.GetDynamicByScope(scope)
	for _, tracker in pairs(Schema.progression.dynamicTrackers) do
		if (tracker.scope == scope) then
			return tracker
		end
	end
end

--- Loads dynamically created progression data.
--- @param uniqueID string
--- @return table?
function Schema.progression.Load(uniqueID)
	local file = Schema.progression.GetSaveFile(uniqueID)
	local data = Schema.util.RestoreSchemaData(file, false)

	if (not data) then
		return
	end

	return data
end

--- Loads all dynamically created progression data.
--- @return table<string, ProgressionTracker>
--- @nodiscard
function Schema.progression.LoadAll()
	local saveDirectory = Schema.progression.GetSaveFileDirectory()
	local allData = {}

	-- Load all files in the directory
	for _, file in ipairs(Schema.util.FindSchemaData(saveDirectory .. "/*.json")) do
		local uniqueID = file:match("^(.*)%.json$")
		local progressionData = Schema.progression.Load(uniqueID)

		if (progressionData) then
			progressionData = Schema.progression.RegisterDynamic(progressionData)
			allData[uniqueID] = progressionData
		end
	end

	return allData
end

--- Changes a progression for a player, within a scope (e.g: belonging to a quest/npc)
--- to the specified value.
--- @param player Player
--- @param scope string
--- @param key string
--- @param value ProgressionValue|fun(ProgressionValue):(ProgressionValue) The value, or a function that takes the current value and returns the new value
--- @param noNetwork? boolean Whether to not send the change to the client
--- @return any # The new value
function Schema.progression.Change(player, scope, key, value, noNetwork)
	local progressions = Schema.progression.GetProgressions(player)

	progressions[scope] = progressions[scope] or {}

	if (isfunction(value)) then
		value = value(progressions[scope][key])
	end

	progressions[scope][key] = value

	if (noNetwork) then
		return value
	end

	local dynamicProgression = Schema.progression.GetDynamicByScope(scope)

	if (dynamicProgression) then
		Schema.progression.NetworkDynamicChanges(player, {
			[scope] = progressions[scope]
		})

		return
	end

	Schema.progression.NetworkChanges(player, {
		{
			scope = scope,
			key = key,
			value = value
		}
	})

	hook.Run("PlayerProgressionChange", player, scope, key, value)

	return value
end

--- Checks if a player's progression matches the specified value
--- @param player Player
--- @param scope string
--- @param key string
--- @param value ProgressionValue|fun(ProgressionValue):(boolean) The value, or a function that takes the current value and returns whether it matches
--- @return boolean
function Schema.progression.Check(player, scope, key, value)
	local progressions = Schema.progression.GetProgressions(player)

	local currentValue = progressions[scope] and progressions[scope][key]

	if (isfunction(value)) then
		return value(currentValue)
	end

	if (currentValue == nil) then
		return not value
	end

	return currentValue == value
end

--- Checks if a player's progression for many keys of a scope match the specified value
--- @param player Player
--- @param scope string
--- @param keys string[]
--- @param value ProgressionValue|fun(ProgressionValue):(boolean) The value, or a function that takes the current value and returns whether it matches
--- @return boolean
function Schema.progression.CheckMany(player, scope, keys, value)
	for _, key in ipairs(keys) do
		if (not Schema.progression.Check(player, scope, key, value)) then
			return false
		end
	end

	return true
end

--- Gets the type converter for a progression key
--- @param scope string
--- @param key string
--- @return fun(ProgressionValue): any
function Schema.progression.GetTypeConverter(scope, key)
	local tracker = Schema.progression.GetDynamicByScope(scope)

	-- TODO: We should stop juggling uniqueID and scope if they can be the same for a tracker
	assert(tracker, "The progression should exist - TODO: Non dynamic progressions: " .. key .. " in " .. scope)

	local goalOrKey = tracker:FindGoal(key)
		or tracker:FindProgressionKey(key)
	assert(goalOrKey, "The goal or Key should exist: " .. key .. " in " .. scope)

	local type = goalOrKey.type

	if (type == "number") then
		return tonumber
	elseif (type == "boolean") then
		return tobool
	elseif (type == "string") then
		return tostring
	end

	assert(false, "Unknown progression type: " .. type)
end

--- Gets the progression value for a player
--- @param player Player
--- @param scope string
--- @param key string
--- @return ProgressionValue?
function Schema.progression.Get(player, scope, key)
	local progressions = Schema.progression.GetProgressions(player)

	if (not progressions[scope]) then
		return nil
	end

	return progressions[scope][key]
end

--- Networks the given progression changes to the player.
--- @param player Player
--- @param changedItems ProgressionNetworkTable[] Sequential table of progressions
--- @param isFullReset? boolean Whether to reset all progressions
--- @return number # The delay in seconds before all progressions are sent
function Schema.progression.NetworkChanges(player, changedItems, isFullReset)
	-- Ensure that the changedItems are sequential, so we don't get stuck networking
	changedItems = Schema.CompactTable(changedItems)
	local messageAmount = #changedItems

	if (messageAmount > Schema.MaxMessageIndex) then
		ErrorNoHaltWithStack(
			"Too many items in a single progression operation for player "
			.. player:Name() .. "! (" .. messageAmount .. ")\n"
		)

		return 0
	end

	local delayInSeconds = 0

	if (messageAmount > 0) then
		-- If we send everything at once, we will get kicked with 'overflowed reliable channel', so let's chunk it up with a 0.05s delay
		-- The header will let the client know how many messages to expect
		delayInSeconds = Schema.ScopedChunkData(
			player,
			"Progression",
			changedItems,
			Schema.ChunkMaxSizeProgressionItem,
			Schema.ChunkDelayProgressionItem,
			function(chunk, chunkIndex, chunkAmount)
				if (chunkIndex == 1) then
					net.Start("expProgressionItemHeader")
					net.WriteBool(isFullReset or false)
					net.WriteUInt(messageAmount, Schema.MessageIDBitCount)
					net.Send(player)
				end

				for _, progressionInfo in ipairs(chunk) do
					net.Start("expProgressionItem")
					net.WriteString(progressionInfo.scope)
					net.WriteString(progressionInfo.key)
					net.WriteType(progressionInfo.value)
					net.Send(player)
				end
			end
		)
	else
		-- Even if there are no progressions, reset it to make sure the client knows to reset
		net.Start("expProgressionItemHeader")
		net.WriteBool(isFullReset or false)
		net.WriteUInt(0, Schema.MessageIDBitCount)
		net.Send(player)
	end

	return delayInSeconds
end

--- Sends the player's completed interactions to the client
--- @param player Player
--- @return number # The delay in seconds before all completions are sent
function Schema.progression.NetworkAll(player)
	local progressions = Schema.progression.GetProgressions(player)
	local changedItems = {}

	for scope, keys in pairs(progressions) do
		for key, value in pairs(keys) do
			table.insert(changedItems, {
				scope = scope,
				key = key,
				value = value
			})
		end
	end

	-- Also send dynamic progressions
	Schema.progression.NetworkDynamicChanges(player)

	return Schema.progression.NetworkChanges(player, changedItems, true)
end

--- Networks the given dynamic progression changes to the player. Since clients
--- don't know about dynamic progressions, we need to send them all tracker, goal
--- and progressionKey data.
--- TODO: Only send data that has changed
--- @param client Player
--- @param progressions? table<string, table<string, ProgressionValue>>
function Schema.progression.NetworkDynamicChanges(client, progressions)
	if (not progressions) then
		progressions = Schema.progression.GetDynamicProgressions(client)
	end

	local networkTables = {}

	for scope, keys in pairs(progressions) do
		local progression = Schema.progression.GetDynamicByScope(scope)
		assert(progression, "The progression should exist")

		table.insert(networkTables, {
			progressionTracker = Schema.util.CopyOmitCyclicReference(progression),
			keys = keys
		})
	end

	Schema.chunkedNetwork.Send("ProgressionDynamicAll", client, networkTables)
end

--- Opens the progression editor for a player.
--- @param client Player
function Schema.progression.OpenEditor(client)
	local progressions = Schema.util.CopyOmitCyclicReference(Schema.progression.GetAllDynamic())

	Schema.chunkedNetwork.Send("ProgressionsEdit", client, progressions)
end

--- Abandons a progression tracker.
--- @param client Player
--- @param uniqueID string
function Schema.progression.AbandonTracker(client, uniqueID)
	local tracker = Schema.progression.GetTracker(uniqueID)

	if (not tracker or not tracker:CanAbandon()) then
		return
	end

	-- Remove the isInProgress key and completedKey for the tracker
	local progressions = Schema.progression.GetProgressions(client)
	local scope = tracker:GetScope()

	if (progressions[scope]) then
		progressions[scope][tracker:GetIsInProgressKey()] = nil
		progressions[scope][tracker:GetCompletedKey()] = nil

		-- Empty out all keys for the tracker goals
		for _, goal in ipairs(tracker:GetGoals()) do
			progressions[scope][goal:GetKey()] = nil
		end
	end

	if (tracker.serverOnAbandon) then
		tracker.serverOnAbandon(tracker, client)
	end

	-- Network the removal to the client by resetting progressions fully
	Schema.progression.NetworkAll(client)
end

--[[
	Hooks
--]]

hook.Add("InitializedSchema", "Schema.progression.LoadAllDynamic", function()
	Schema.progression.dynamicTrackers = Schema.progression.LoadAll()
end)

--[[
	Net Messages
--]]

net.Receive("expProgressionRemove", function(length, client)
	local uniqueID = net.ReadString()

	if (not Schema.progression.HasManagePermission(client)) then
		client:Notify("You do not have permission to manage progression trackers!")
		return
	end

	Schema.progression.Destroy(uniqueID)

	local progression = Schema.progression.GetDynamic(uniqueID)
	assert(progression, "The progression should exist")
	Schema.progression.UnRegisterTracker(progression)

	Schema.progression.dynamicTrackers[uniqueID] = nil
end)

net.Receive("expProgressionAbandonTracker", function(length, client)
	local uniqueID = net.ReadString()

	Schema.progression.AbandonTracker(client, uniqueID)
end)
