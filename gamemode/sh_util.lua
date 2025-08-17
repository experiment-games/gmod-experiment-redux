ix.util._existingLibraries = ix.util._existingLibraries or {}

--- Can be used to re-enable resource.AddFile's functionality.
--- @param path string
function ix.util.AddResourceFile(path)
	-- Not necessary since we moved to publishing content through a workshop addon.
	-- resource.AddFile(path)
end

--- @param path string
function ix.util.AddResourceSingleFile(path)
	-- Not necessary since we moved to publishing content through a workshop addon.
	-- resource.AddSingleFile(path)
end

--- Creates a new table with a metatable.
--- @param metaTable table The base table to use.
--- @return table # The object with the metatable applied.
--- @realm shared
function ix.util.NewMetaObject(metaTable)
	return ix.util.InitMetaObject({}, metaTable)
end

--- Applies a metatable to a table.
--- @param object table The table to apply the metatable to.
--- @param metaTable table The metatable to apply.
--- @return table # The object with the metatable applied.
--- @realm shared
function ix.util.InitMetaObject(object, metaTable)
	setmetatable(object, metaTable)

	if (metaTable.__index == nil) then
		metaTable.__index = metaTable
	end

	return object
end

--- Safely merges a table, keeping track of tables we already
--- merged to prevent stack overflows.
--- @param target table The table to merge into
--- @param source table The table to merge from
--- @param alreadyMerged? table The tables we already merged
--- @return table # The target table
--- @realm shared
function ix.util.SafeMergeTable(target, source, alreadyMerged)
	alreadyMerged = alreadyMerged or {}

	for key, value in pairs(source) do
		if (istable(value) and not alreadyMerged[value]) then
			alreadyMerged[value] = true

			if (not target[key]) then
				target[key] = {}
			end

			ix.util.SafeMergeTable(target[key], value, alreadyMerged)
		else
			target[key] = value
		end
	end

	return target
end

--- Creates a library, or gets an existing one if it already exists.
--- @param libraryName string The name of the library.
--- @param data? table The data to set for the library.
--- @return table The library.
--- @realm shared
function ix.util.GetOrCreateLibrary(libraryName, data)
	if (ix.util._existingLibraries[libraryName]) then
		-- Since client and server files may be loaded before shared files, we
		-- want to check if data contains any new keys so none are missing from
		-- the library.
		if (data) then
			for key, value in pairs(data) do
				if (ix.util._existingLibraries[libraryName][key] == nil) then
					ix.util._existingLibraries[libraryName][key] = value
				end
			end
		end

		return ix.util._existingLibraries[libraryName]
	end

	-- Ensure we can register the library inside the Schema table with Schema.{libraryName} = ix.util.GetOrCreateLibrary
	assert(Schema[libraryName] == nil, "Failed to create Library! Name " .. libraryName .. " is already in use!")

	ix.util._existingLibraries[libraryName] = data or {}

	return ix.util._existingLibraries[libraryName]
end

--- @realm shared
--- @class CommonLibrary
--- @field Get fun(identifierOrItem: string|number|table, allowPartialMatch?: boolean):(table) deprecated, use Find instead
--- @field Find fun(identifierOrItem: string|number|table, allowPartialMatch?: boolean):(table?) Finds an object by index/uniqueID/name, or if a table is passed, that is checked to exist in the buffer and returned.
--- @field GetAll fun():(table) Gets all objects in the.
--- @field GetBuffer fun():(table) Gets all objects in a table where the key is the objects index.
--- @field UnRegister fun(libraryObject: table):(table) Unregisters an object.
--- @field Exists fun(name: string):(boolean) Checks if an object exists.
--- @field FindByProperty fun(key: string, value: any, handleLibraryValueAsPattern?: boolean):(table) Finds objects by a property value, optionally treating the value as a pattern.
--- @field GetProperty fun(name: string, key: string):(any) Gets a property of an object.
--- @field IncludeDirectory fun(directory: string, libraryGlobalNameOverride?: string) Includes all files in a directory and registers them as objects.
--- @field OnPreRegister fun(libraryObject: table)? Called before an object is registered. (You are expected override this)
--- @field OnPostRegister fun(libraryObject: table)? Called after an object is registered. (You are expected override this)
--- @field OnGetNotFound fun(name: string, allowPartialMatch?: boolean):(table)? Called when an object is not found. (You are expected override this)

--- Gets an existing or creates a library that loads object types from a directory.
--- For example: Schema.buff, Schema.achievement, Schema.perk
--- which would then be loaded from the buffs, achievements, and perks directories.
---
--- Example usage:
--- `Schema.achievement = ix.util.GetOrCreateCommonLibrary("achievement")`
--- @param libraryName string The unique name of the library.
--- @param constructor? fun(): table The constructor function for an object.
--- @param data? table The data to set for the library.
--- @return CommonLibrary # The library object.
--- @realm shared
function ix.util.GetOrCreateCommonLibrary(libraryName, constructor, data)
	local defaultLibraryGlobalName = libraryName:gsub("%s+", "_"):upper()

	data = data or {}
	data.stored = data.stored or {}
	data.buffer = data.buffer or {}

	local library = ix.util.GetOrCreateLibrary(libraryName, data)

	library.GetBuffer = function()
		return library.buffer
	end

	library.GetAll = function()
		return library.stored
	end

	-- Private, because otherwise the user would have to manually call the constructor when creating their
	-- own table to register, which could easily be forgotten.
	local libraryRegister = function(libraryObject)
		if (library.OnPreRegister) then
			library.OnPreRegister(libraryObject)
		end

		if (libraryObject.hooks) then
			-- Let library objects react to hooks
			for hookName, hookCallback in pairs(libraryObject.hooks) do
				if (isfunction(hookCallback)) then
					HOOKS_CACHE[hookName] = HOOKS_CACHE[hookName] or {}
					HOOKS_CACHE[hookName][libraryObject] = hookCallback
				end
			end
		end

		if (library.stored[libraryObject.uniqueID]) then
			libraryObject = ix.util.SafeMergeTable(library.stored[libraryObject.uniqueID], libraryObject)
		else
			library.stored[libraryObject.uniqueID] = libraryObject
		end

		library.buffer[libraryObject.index] = libraryObject

		if (library.OnPostRegister) then
			library.OnPostRegister(libraryObject)
		end

		return libraryObject
	end

	library.IncludeDirectory = function(directory, libraryGlobalNameOverride)
		local libraryGlobalName = libraryGlobalNameOverride or defaultLibraryGlobalName
		local oldGlobal = _G[libraryGlobalName]

		if (directory:sub(-1) ~= "/") then
			directory = directory .. "/"
		end

		for _, fileName in ipairs(file.Find(directory .. "*.lua", "LUA")) do
			local uniqueID = string.lower(fileName:sub(4, -5))
			local LIBRARY_OBJECT

			if (constructor) then
				LIBRARY_OBJECT = library.stored[uniqueID] or constructor()
			else
				LIBRARY_OBJECT = library.stored[uniqueID] or {}
			end

			LIBRARY_OBJECT.hooks = LIBRARY_OBJECT.hooks or {}
			LIBRARY_OBJECT.uniqueID = uniqueID
			LIBRARY_OBJECT.index = tonumber(util.CRC(uniqueID))

			_G[libraryGlobalName] = LIBRARY_OBJECT

			local realm = "shared"

			if (fileName:StartsWith("sv_")) then
				realm = "server"
			elseif (fileName:StartsWith("cl_")) then
				realm = "client"
			end

			ix.util.Include(directory .. fileName, realm)

			if (SERVER) then
				if (LIBRARY_OBJECT.backgroundImage) then
					resource.AddFile("materials/" .. LIBRARY_OBJECT.backgroundImage .. ".vmt")
				end

				if (isstring(LIBRARY_OBJECT.foregroundImage)) then
					resource.AddFile("materials/" .. LIBRARY_OBJECT.foregroundImage .. ".vmt")
				elseif (istable(LIBRARY_OBJECT.foregroundImage)) then
					local spritesheetData = LIBRARY_OBJECT.foregroundImage

					if (spritesheetData.spritesheet:EndsWith(".png")) then
						resource.AddFile("materials/" .. spritesheetData.spritesheet)
					else
						resource.AddFile("materials/" .. spritesheetData.spritesheet .. ".vmt")
					end
				end
			else
				if (istable(LIBRARY_OBJECT.foregroundImage)) then
					local spritesheetData = LIBRARY_OBJECT.foregroundImage

					spritesheetData.spritesheet = Material(spritesheetData.spritesheet)
				end
			end

			libraryRegister(LIBRARY_OBJECT)
		end

		_G[libraryGlobalName] = oldGlobal
	end

	library.UnRegister = function(libraryObject)
		library.stored[libraryObject.uniqueID] = nil
		library.buffer[libraryObject.index] = nil
	end

	--- @param identifierOrItem string|number|table The name of the item or the item itself
	--- @param allowPartialMatch? boolean Whether to allow partial matches. Default is true.
	--- @return table? # The item registration
	library.Find = function(identifierOrItem, allowPartialMatch)
		if (allowPartialMatch == nil) then
			allowPartialMatch = true
		end

		if (istable(identifierOrItem)) then
			assert(identifierOrItem.index, "Library object does not have an index.")
			assert(library.buffer[identifierOrItem.index], "Library object does not exist in the buffer.")

			return library.buffer[identifierOrItem.index]
		end

		if (library.buffer[identifierOrItem]) then
			return library.buffer[identifierOrItem]
		elseif (library.stored[identifierOrItem]) then
			return library.stored[identifierOrItem]
		elseif (allowPartialMatch) then
			local foundObject

			for _, libraryObject in pairs(library.stored) do
				if (string.find(string.lower(libraryObject.name), string.lower(identifierOrItem))) then
					if (foundObject) then
						if (string.len(libraryObject.name) < string.len(foundObject.name)) then
							foundObject = libraryObject
						end
					else
						foundObject = libraryObject
					end
				end
			end

			if (foundObject) then
				return foundObject
			end
		end

		if (library.OnGetNotFound) then
			return library.OnGetNotFound(identifierOrItem, allowPartialMatch)
		end
	end

	--- @return table? # The item registration
	--- @deprecated Use library.Find instead
	library.Get = library.Find

	library.Exists = function(name)
		return library.Find(name) ~= nil
	end

	library.FindByProperty = function(key, value, handleLibraryValueAsPattern)
		local results = {}

		for _, libraryObject in pairs(library.stored) do
			local libraryValues = libraryObject[key]

			if (not libraryValues) then
				continue
			end

			if (not istable(libraryValues)) then
				libraryValues = { libraryValues }
			end

			for _, libraryValue in ipairs(libraryValues) do
				local matched = handleLibraryValueAsPattern
					and string.find(value, libraryValue)
					or libraryValue == value

				if (matched) then
					results[#results + 1] = libraryObject
					break
				end
			end
		end

		return results
	end

	library.GetProperty = function(name, key)
		local libraryObject = library.Find(name)

		if (not libraryObject or not libraryObject[key]) then
			error(libraryName .. " '" .. name .. "' does not have property '" .. key .. "'.")
		end

		return libraryObject[key]
	end

	return library
end

--- print, but with Experiment Redux prefix.
--- @vararg any
function ix.util.SchemaPrint(...)
	print("[Experiment Redux] " .. string.format(...))
end

--- ErrorNoHalt, but with Experiment Redux prefix.
--- @vararg any
function ix.util.SchemaErrorNoHalt(...)
	ErrorNoHalt("[Experiment Redux] ")

	for i = 1, select("#", ...) do
		local value = select(i, ...)

		ErrorNoHalt(tostring(value))
		ErrorNoHalt(" ")
	end

	ErrorNoHalt("\n")
end

--- ErrorNoHalt, but with Experiment Redux prefix.
--- @vararg any
function ix.util.SchemaErrorNoHaltFormatted(format, ...)
	ErrorNoHalt("[Experiment Redux] " .. string.format(format, ...))
	ErrorNoHalt("\n")
	ErrorNoHalt(debug.traceback("", 2))
end

--- ErrorNoHaltWithStack, but with Experiment Redux prefix.
--- @vararg any
function ix.util.SchemaErrorNoHaltWithStack(...)
	ErrorNoHalt("[Experiment Redux] ")

	for i = 1, select("#", ...) do
		local value = select(i, ...)

		ErrorNoHalt(tostring(value))
		ErrorNoHalt(" ")
	end

	ErrorNoHalt("\n")
	ErrorNoHalt(debug.traceback("", 2))
	ErrorNoHalt("\n")
end

--- error, but with Experiment Redux prefix.
--- @vararg any
function ix.util.SchemaError(...)
	error("[Experiment Redux] " .. string.format(...), 2)
end

--- Checks if the server or client has the given addon mounted.
--- @param workshopID string The workshop ID of the addon.
--- @return boolean # True if the addon is mounted, false otherwise.
function ix.util.IsAddonMounted(workshopID)
	local addons = engine.GetAddons()

	for _, addon in ipairs(addons) do
		if (addon.wsid == workshopID) then
			return addon.mounted
		end
	end

	return false
end
