Schema.registeredWeaponAttachments = Schema.registeredWeaponAttachments or {}
Schema.meta = Schema.meta or {}

Schema.name = "Experiment Redux"
Schema.author = "Experiment Redux"
Schema.description = "It's a dog-eat-dog world out there, and these dogs have guns."
Schema.version = {
	major = 6,
	minor = 0,
	revision = 1,
	suffix = "alpha"
}

Schema.disabledPlugins = {
	-- We use our own stamina system, that doesn't train by running
	"stamina",

	-- We use our own strength system, that doesn't train by throwing punches
	"strength",

	-- We don't want player positions to be saved, they can only spawn at the spawn points
	"spawnsaver",

	-- We disable the default spawn point system, because we want players to select one from a list
	"spawns",

	-- We do doors differently with our own plugin.
	"doors",
}

Schema.chunkedNetwork.RegisterFireAndForget("NpcEdit", 50, 0.03)
Schema.chunkedNetwork.RegisterFireAndForget("NpcEditOpen", 50, 0.03)
Schema.chunkedNetwork.RegisterFireAndForget("NpcInteractEdit", 50, 0.03)
Schema.chunkedNetwork.RegisterFireAndForget("NpcInteractShowDynamic", 50, 0.03)

Schema.chunkedNetwork.Register("Progressions", 50, 0.03)
Schema.chunkedNetwork.RegisterFireAndForget("ProgressionEdit", 50, 0.03)
Schema.chunkedNetwork.RegisterFireAndForget("ProgressionsEdit", 50, 0.03)
Schema.chunkedNetwork.RegisterFireAndForget("ProgressionDynamicAll", 50, 0.03)

--- Delay between sending progression chunks (to prevent reliable buffer overflow)
Schema.ChunkDelayProgressionItem = 0.05

--- Maximum number of progression items to send at once to the client
Schema.ChunkMaxSizeProgressionItem = 500

Schema.MessageIDBitCount = 16

-- Maximum message index given the bitcount
Schema.MaxMessageIndex = math.pow(2, Schema.MessageIDBitCount) - 1

ix.util.Include("sh_commands.lua")

ix.util.Include("cl_schema.lua")
ix.util.Include("cl_hooks.lua")

ix.util.Include("sh_configs.lua")
ix.util.Include("sh_hooks.lua")

ix.util.Include("sv_schema.lua")
ix.util.Include("sv_hooks.lua")

-- Rarity enumerations
Schema.RARITY_LEGENDARY = 0.001
Schema.RARITY_GIGA_RARE = 0.5
Schema.RARITY_SUPER_RARE = 2
Schema.RARITY_RARE = 5
Schema.RARITY_UNCOMMON = 15
Schema.RARITY_COMMON = 45
Schema.RARITY_VERY_COMMON = 60

RANK_RECRUIT = 0
RANK_PRIVATE = 1
RANK_SERGEANT = 2
RANK_LIEUTENANT = 3
RANK_CAPTAIN = 4
RANK_MAJOR = 5
RANK_COLONEL = 6
RANK_GENERAL = 7

RANKS = {
	[RANK_RECRUIT] = "Recruit",
	[RANK_PRIVATE] = "Private",
	[RANK_SERGEANT] = "Sergeant",
	[RANK_LIEUTENANT] = "Lieutenant",
	[RANK_CAPTAIN] = "Captain",
	[RANK_MAJOR] = "Major",
	[RANK_COLONEL] = "Colonel",
	[RANK_GENERAL] = "General",
}

ix.util.IncludeDir("meta")

Schema.cinematics.IncludeDirectory(Schema.folder .. "/schema/cinematic_scenes", "SCENE")
Schema.achievement.IncludeDirectory(Schema.folder .. "/schema/achievements")
Schema.buff.IncludeDirectory(Schema.folder .. "/schema/buffs")
Schema.perk.IncludeDirectory(Schema.folder .. "/schema/perks")
Schema.npc.IncludeDirectory(Schema.folder .. "/schema/npcs")
Schema.map.IncludeDirectory(Schema.folder .. "/schema/maps")
Schema.tutorial.IncludeDirectory(Schema.folder .. "/schema/tutorials")

ix.chat.Register("achievement", {
	OnChatAdd = function(self, speaker, text)
		local icon = ix.util.GetMaterial("icon16/star.png")

		chat.AddText(icon, Color(139, 174, 179, 255), speaker, " has achieved the ", Color(139, 174, 179, 255), text,
			" achievement!")
	end,
	deadCanChat = true,
})

ix.chat.Register("broadcast", {
	OnChatAdd = function(self, speaker, text)
		chat.AddText("(Broadcast) ", Color(150, 125, 175, 255), speaker .. ": " .. text)
	end,
})

ix.chat.Register("shipment", {
	OnChatAdd = function(self, speaker, text)
		local icon = ix.util.GetMaterial("icon16/box.png")

		chat.AddText(icon, "You've ordered ", Color(139, 174, 179, 255), text, "!")
		ix.util.Notify("You've ordered " .. text .. "!")
	end,
})

--- Returns the players attribute as a fraction of the maximum value.
--- @param character Player
--- @param attributeKey string
--- @return number
function Schema.GetAttributeFraction(character, attributeKey)
	local attributeTable = ix.attributes.list[attributeKey]
	local maximum = attributeTable.maxValue or ix.config.Get("maxAttributes", 100)
	local amount = character:GetAttribute(attributeKey, 0)

	return amount / maximum
end

function Schema.GetPlayer(entity)
	if (IsValid(entity) and entity:IsPlayer()) then
		return entity
	end
end

function Schema.RegisterWeaponAttachment(itemTable)
	if (not itemTable.class) then
		error("Weapon item must have a class property!")
	end

	if (not itemTable.isAttachment) then
		error("Weapon item must be attachment!")
	end

	Schema.registeredWeaponAttachments[itemTable.class] = itemTable
end

function Schema.GetWeaponAttachment(class)
	return Schema.registeredWeaponAttachments[class]
end

function Schema.RegisterMaterialSources()
	local helperMetaTable = {}
	helperMetaTable.__index = helperMetaTable
	local toBeRemoved = {}

	function helperMetaTable:Add(data)
		table.insert(self, data)
	end

	function helperMetaTable:Remove(uniqueID)
		table.insert(toBeRemoved, uniqueID)
	end

	function helperMetaTable:RemoveQueued()
		for _, uniqueID in ipairs(toBeRemoved) do
			for i, data in ipairs(self) do
				if (data.uniqueID == uniqueID) then
					table.remove(self, i)
				end
			end
		end

		toBeRemoved = {}
	end

	local materialSources = setmetatable({}, helperMetaTable)

	hook.Run("AdjustMaterialSources", materialSources)

	materialSources:RemoveQueued()

	-- Register the allowed props as blueprint items
	for _, data in ipairs(materialSources) do
		local uniqueID = string.lower(data.uniqueID)
		local ITEM = ix.item.Register(
			uniqueID,
			"base_material_sources",
			false,
			nil,
			true
		)

		table.Merge(ITEM, data, true)
		ITEM.uniqueID = uniqueID
	end
end

local function randomElement(table)
	return table[math.random(1, #table)]
end

function Schema.GetRandomName()
	local NAMES_FIRST,
	NAMES_LAST = include(Schema.folder .. "/schema/content/sh_names.lua")

	return randomElement(NAMES_FIRST) .. " " .. randomElement(NAMES_LAST)
end

function Schema.GetRandomDescription()
	local DESCRIPTION_AGE_INDICATOR,
	DESCRIPTION_BODY_TYPE_HEIGHT,
	DESCRIPTION_BODY_TYPE_FRAME,
	DESCRIPTION_FACIAL_FEATURES,
	DESCRIPTION_TRAITS,
	DESCRIPTION_BEHAVIOR = include(Schema.folder .. "/schema/content/sh_descriptions.lua")

	return randomElement(DESCRIPTION_AGE_INDICATOR)
		.. " "
		.. randomElement(DESCRIPTION_BODY_TYPE_HEIGHT):format("person")
		.. " "
		.. randomElement(DESCRIPTION_BODY_TYPE_FRAME)
		.. ". They've got "
		.. randomElement(DESCRIPTION_FACIAL_FEATURES)
		.. ". " .. randomElement(DESCRIPTION_TRAITS)
		.. "."
end

--- Creates a queue from a table which provides enqueue and dequeue operations.
--- @generic T: any
--- @param source? T[]
--- @param fixedSize? number If set, the queue will be limited to this size and will dequeue the oldest value when full
--- @return Queue<T> # The queue
--- @realm shared
function Schema.NewQueue(source, fixedSize)
	source = source or {}

	--- @realm shared
	--- @class Queue<T>
	local queue = {}

	--- Enqueues a value to the end of the queue.
	--- @param value any
	function queue:enqueue(value)
		table.insert(source, value)

		if (fixedSize and #source > fixedSize) then
			table.remove(source, 1)
		end
	end

	--- Dequeues a value from the front of the queue.
	--- @return any # The dequeued value
	function queue:dequeue()
		return table.remove(source, 1)
	end

	--- Peeks at the given index or front value of the queue.
	--- @param index? number
	--- @return any # The front value
	function queue:peek(index)
		return source[index or 1]
	end

	--- Returns the size of the queue.
	--- @return number # The size
	function queue:size()
		return #source
	end

	--- Checks if the queue is empty.
	--- @return boolean # Whether the queue is empty
	function queue:isEmpty()
		return #source == 0
	end

	--- Checks if the queue contains a value.
	--- @param value any
	--- @return boolean # Whether the queue contains the value
	function queue:contains(value)
		for _, v in pairs(source) do
			if (v == value) then
				return true
			end
		end

		return false
	end

	--- Gets all the values in the queue.
	--- @return table
	function queue:getAll()
		return table.Copy(source)
	end

	--- Clears the queue, removing all values.
	function queue:clear()
		table.Empty(source)
	end

	return queue
end

--- Chunks data, returning the total delay in seconds.
--- @param data table
--- @param chunkSize number
--- @param delayInChunks number
--- @param callback function
--- @param finishCallback? fun(data: table)
--- @return number, fun()? # The total delay in seconds, and the start function
--- @realm shared
function Schema.ChunkData(data, chunkSize, delayInChunks, callback, finishCallback)
	local dataAmount = #data
	local chunkAmount = math.ceil(dataAmount / chunkSize)

	for i = 1, chunkAmount do
		local start = (i - 1) * chunkSize + 1
		local finish = math.min(i * chunkSize, dataAmount)

		timer.Simple(delayInChunks * (i - 1), function()
			local chunk = { unpack(data, start, finish) }

			-- callback(chunk, i, chunkAmount)
			-- Ensure that the callback is run in a protected environment, so finish callbacks are still called
			-- and the queue doesn't get stuck.
			xpcall(callback, function(error)
				ix.util.SchemaErrorNoHaltFormatted(
					"The ChunkData callback for chunk %i/%i has failed to run with error:\n\t%s",
					i,
					chunkAmount,
					error
				)
			end, chunk, i, chunkAmount)

			if (i == chunkAmount and finishCallback) then
				finishCallback(data)
			end
		end)
	end

	return delayInChunks * chunkAmount
end

--- Chunks data using Schema.ChunkData, but with a scoped queue, such
--- that no active chunks are interrupted.
--- The total delay in seconds is returned.
--- @param queueScope Entity|Player|table The scope where the queue will be stored
--- @param queueName string The name of the queue
--- @param data table
--- @param chunkSize number
--- @param delay number
--- @param callback function
--- @param finishCallback? fun(data: table)
--- @return number
--- @realm shared
function Schema.ScopedChunkData(queueScope, queueName, data, chunkSize, delay, callback, finishCallback)
	queueName = "expQueue" .. queueName
	queueScope[queueName] = queueScope[queueName] or Schema.NewQueue()
	local queue = queueScope[queueName]

	if (queue:size() > 1000) then
		ix.util.SchemaErrorNoHaltFormatted(
			"Queue size is too large for '%s'.'%s'! (%i) - Not processing data",
			tostring(queueScope),
			queueName,
			queue:size()
		)

		if (isentity(queueScope) and queueScope:IsPlayer()) then
			queueScope:Kick("ScopedChunkData Data Queue Overflowed!")
		end

		return 0
	end

	if (not Schema.IsArrayLike(data)) then
		ix.util.SchemaErrorNoHalt(
			"Schema.ScopedChunkData: Data must be an array with only sequential numeric keys!"
		)

		return 0
	end

	-- Create a task to be queued
	local task = {
		data = data,
		chunkSize = chunkSize,
		delay = delay,
		callback = callback,
		finishCallback = finishCallback
	}

	-- Enqueue the task
	queue:enqueue(task)

	-- If this is the only task in the queue, start processing immediately
	if (queue:size() == 1) then
		Schema.ProcessScopedChunkDataQueue(queueScope, queueName)
	end

	-- Return the total processing time
	return math.ceil(#data / chunkSize) * delay
end

--- Process the queue for a specific scope and queue name
--- @param queueScope Entity|Player|table
--- @param queueName string
--- @realm shared
function Schema.ProcessScopedChunkDataQueue(queueScope, queueName)
	local queue = queueScope[queueName]

	if (queue:isEmpty()) then
		return
	end

	-- Get the current task, without removing it from the queue
	local task = queue:peek()

	-- Process the task using ChunkData
	Schema.ChunkData(
		task.data,
		task.chunkSize,
		task.delay,
		task.callback,
		function(fullData)
			-- When done, remove this task from the queue
			queue:dequeue()

			if (task.finishCallback) then
				task.finishCallback(fullData)
			end

			-- Process the next task in the queue
			Schema.ProcessScopedChunkDataQueue(queueScope, queueName)
		end
	)
end

--- Debugs all queues for players, printing them
--- @realm shared
function Schema.DebugQueues()
	for _, player in ipairs(player.GetAll()) do
		local playerTable = player:GetTable()

		for key, queue in pairs(playerTable) do
			if (string.find(key, "expQueue")) then
				print("Queue for " .. player:Name() .. " - " .. key .. " - " .. queue:size())
				PrintTable(queue:getAll())
			end
		end
	end
end

--- Compacts a table where some values may be nil, such that it becomes sequential again and can be looped with ipairs again.
--- @param target table The table to compact
--- @return table # The compacted table
--- @realm shared
function Schema.CompactTable(target)
	local newTable = {}
	local i = 1

	for k, v in pairs(target) do
		if (v ~= nil) then
			newTable[i] = v
			i = i + 1
		end
	end

	return newTable
end

--- Checks if a table is array-like, with only sequential numberic keys
--- @param target table
--- @return boolean # Whether the table is array-like
--- @realm shared
function Schema.IsArrayLike(target)
	local length = #target
	local count = 0

	for k, _ in pairs(target) do
		if (type(k) ~= "number" or k ~= math.floor(k) or k < 1 or k > length) then
			return false
		end

		count = count + 1
	end

	return count == length
end
