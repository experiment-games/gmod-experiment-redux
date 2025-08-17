--- Client library to work with the progression panel and information.
Schema.progression = ix.util.GetOrCreateLibrary("progression", {
	-- Where the local player stored are tracked
	stored = {},

	trackedOnHud = {},

	hudPanel = nil,
})

--- Gets all the progression values for the local player
--- @return table<string, table<string, ProgressionValue>> # A key-value pair of keys to progression values, with the scope as the outer key
function Schema.progression.GetProgressions()
	return Schema.progression.stored
end

--- Checks if the local player's progression matches the specified value
--- @param scope string
--- @param key string
--- @param value ProgressionValue|fun(ProgressionValue):(boolean) The value, or a function that takes the current value and returns whether it matches
--- @return boolean
function Schema.progression.Check(scope, key, value)
	local progressions = Schema.progression.stored

	local currentValue = progressions[scope] and progressions[scope][key]

	if (isfunction(value)) then
		return value(currentValue)
	end

	if (currentValue == nil) then
		return value == nil
	end

	return currentValue == value
end

--- Gets the progression value for the local player
--- @param scope string
--- @param key string
--- @return ProgressionValue?
function Schema.progression.Get(scope, key)
	local progressions = Schema.progression.stored

	if (not progressions[scope]) then
		return nil
	end

	return progressions[scope][key]
end

--- Checks if the local player's progression for many keys of a scope match the specified value
--- @param scope string
--- @param keys string[]
--- @param value ProgressionValue|fun(ProgressionValue):(boolean) The value, or a function that takes the current value and returns whether it matches
--- @return boolean
function Schema.progression.CheckMany(scope, keys, value)
	for _, key in ipairs(keys) do
		if (not Schema.progression.Check(scope, key, value)) then
			return false
		end
	end

	return true
end

--- Sets a progression tracker to draw on the HUD panel
--- @param tracker ProgressionTracker
function Schema.progression.SetTrackerOnHUD(tracker, shouldTrack)
	if (shouldTrack) then
		local newIndex = #Schema.progression.trackedOnHud + 1
		Schema.progression.trackedOnHud[newIndex] = tracker:GetUniqueID()
	else
		table.RemoveByValue(Schema.progression.trackedOnHud, tracker:GetUniqueID())
	end

	hook.Run("ProgressionTrackerOnHUDChanged", tracker, shouldTrack)
end

--- Gets if a progression tracker is set to draw on the HUD panel
--- @param tracker ProgressionTracker
function Schema.progression.IsTrackerOnHUD(tracker)
	return table.HasValue(Schema.progression.trackedOnHud, tracker:GetUniqueID())
end

--[[
	Hooks
--]]

-- Draws the current amount of operations happening, so the player knows the progression is being updated
hook.Add("PostDrawHUD", "Schema.progression.ShowManySyncOperations", function()
	local currentOperation = Schema.progression.currentOperation

	if (not currentOperation) then
		return
	end

	-- Only if there's more than 10 messages we'll show the message, as it's not really needed
	-- to communicate for a few messages.
	if (currentOperation.remainingMessages < 10) then
		return
	end

	local remainingMessages = currentOperation.remainingMessages

	local text = "Progression: updating " .. remainingMessages .. " items"

	local yOffset = 0

	if (Schema.inventory.currentOperation and currentOperation.remainingMessages >= 10) then
		-- If the inventory is also updating, we'll move the text up a bit
		yOffset = 20
	end

	draw.SimpleText(text, "expDebugBold", ScrW() - 10, ScrH() - yOffset - 10, color_white, TEXT_ALIGN_RIGHT,
		TEXT_ALIGN_BOTTOM)
end)

--[[
	Network Messages
--]]

-- The header lets the client know how many messages to expect
-- If we're told 0 message are to arrive and the operation is reset, we can assume the progressions are empty
-- and reset it (for switching characters)
net.Receive("expProgressionItemHeader", function(length)
	local isFullReset = net.ReadBool()
	local messageAmount = net.ReadUInt(Schema.MessageIDBitCount)
	local currentOperation = Schema.progression.currentOperation

	assert(not currentOperation or currentOperation.remainingMessages == 0,
		"Received an progression header while another operation is still in progress!")

	if (messageAmount == 0 or isFullReset) then
		-- Reset the progressions
		Schema.progression.stored = {}

		if (messageAmount == 0) then
			return
		end
	end

	Schema.progression.currentOperation = {
		remainingMessages = messageAmount,
	}
end)

net.Receive("expProgressionItem", function(length)
	local currentOperation = Schema.progression.currentOperation
	local scope = net.ReadString()
	local key = net.ReadString()
	local value = net.ReadType()

	assert(currentOperation, "Received a progression item without a header telling us how many messages to expect!")

	local remainingMessages = currentOperation.remainingMessages

	assert(remainingMessages > 0, "Received a progression item while no messages are expected!")

	Schema.progression.stored[scope] = Schema.progression.stored[scope] or {}
	Schema.progression.stored[scope][key] = value

	hook.Run("PlayerProgressionChange", LocalPlayer(), scope, key, value)

	remainingMessages = remainingMessages - 1

	if (remainingMessages == 0) then
		Schema.progression.currentOperation = nil

		hook.Run("ProgressionNetworkFinished", operationID)
	else
		currentOperation.remainingMessages = remainingMessages
	end
end)
