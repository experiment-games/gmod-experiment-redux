Schema.util = ix.util.GetOrCreateLibrary("util", {
	transactions = {},
	throttles = {}
})

local PATH_DATA_DESIGN = SERVER and "helix/experiment-redux/"

function Schema.util.ForceEndPath(path)
	if (not path:EndsWith("/")) then
		return path .. "/"
	end

	return path
end

--- Returns the filename if it has an extension, otherwise returns the filename with the extension appended.
--- @param fileName string The filename
--- @param extension string The extension to append if no extension is found
--- @return string
--- @realm shared
function Schema.util.FileEnsureExtension(fileName, extension)
	local endsWithAnyExtension = fileName:find("%.[^%./\\]+$")

	if (endsWithAnyExtension) then
		return fileName
	end

	return fileName .. "." .. extension
end

--- Safely joins path components with a slash.
--- @param ... string The path components
--- @return string # The joined path
--- @realm shared
function Schema.util.JoinPath(...)
	local path = ""

	for i = 1, select("#", ...) do
		local component = select(i, ...)

		if (component:sub(-1) == "/") then
			component = component:sub(1, -2)
		end

		if (i == 1) then
			path = component
		else
			path = path .. "/" .. component
		end
	end

	return path
end

--- Gets the schema folder.
--- @return string
--- @realm shared
function Schema.util.GetSchemaFolder()
	return engine.ActiveGamemode()
end

--- Saves data to a data folder.
--- @param filePath string The file path relative to a data folder.
--- @param data table The data to save, to be JSON encoded.
--- @param baseFolder string The base folder to save the data in.
--- @realm shared
function Schema.util.SaveData(filePath, data, baseFolder)
	filePath = Schema.util.FileEnsureExtension(filePath, "txt")

	file.Write(
		Schema.util.JoinPath(baseFolder, filePath),
		util.TableToJSON(data)
	)
end

--- Saves data to the schema's data folder.
--- @param filePath string The file path relative to the schema's data folder.
--- @param data table The data to save, to be JSON encoded.
--- @realm shared
function Schema.util.SaveSchemaData(filePath, data)
	Schema.util.SaveData(
		filePath,
		data,
		Schema.util.JoinPath(PATH_DATA_DESIGN, Schema.util.GetSchemaFolder())
	)
end

--- Deletes data from a data folder.
--- @param filePath string The file path relative to a data folder.
--- @param baseFolder string The base folder to save the data in.
--- @realm shared
function Schema.util.DeleteData(filePath, baseFolder)
	filePath = Schema.util.FileEnsureExtension(filePath, "txt")

	file.Delete(
		Schema.util.JoinPath(baseFolder, filePath),
		"DATA"
	)
end

--- Deletes data from the schema's data folder.
--- @param filePath string The file path relative to the schema's data folder.
--- @realm shared
function Schema.util.DeleteSchemaData(filePath)
	Schema.util.DeleteData(
		filePath,
		Schema.util.JoinPath(PATH_DATA_DESIGN, Schema.util.GetSchemaFolder())
	)
end

--- Checks if data exists in a data folder.
--- @param filePath string The file path relative to a data folder.
--- @param baseFolder string The base folder to save the data in.
--- @return boolean # Whether the data exists.
--- @realm shared
function Schema.util.DataExists(filePath, baseFolder)
	filePath = Schema.util.FileEnsureExtension(filePath, "txt")

	return file.Exists(
		Schema.util.JoinPath(baseFolder, filePath),
		"DATA"
	)
end

--- Checks if data exists in the schema's data folder.
--- @param filePath string The file path relative to the schema's data folder.
--- @return boolean # Whether the data exists.
--- @realm shared
function Schema.util.SchemaDataExists(filePath)
	return Schema.util.DataExists(
		filePath,
		Schema.util.JoinPath(PATH_DATA_DESIGN, Schema.util.GetSchemaFolder())
	)
end

--- Restores data from a data folder.
--- @param filePath string The file path relative to a data folder.
--- @param default? any The default value to return if the data does not exist. Default is an empty table.
--- @param baseFolder string The base folder to save the data in.
--- @return any # The restored data, or the default value.
--- @realm shared
function Schema.util.RestoreData(filePath, default, baseFolder)
	filePath = Schema.util.FileEnsureExtension(filePath, "txt")

	if (Schema.util.SchemaDataExists(filePath)) then
		local data = file.Read(
			Schema.util.JoinPath(baseFolder, filePath),
			"DATA"
		)

		if (data) then
			local success, value = pcall(util.JSONToTable, data)

			if (success and value ~= nil) then
				return value
			else
				local success, value = pcall(util.JSONToTable, data)

				if (success and value ~= nil) then
					return value
				end
			end
		end
	end

	if (default ~= nil) then
		return default
	else
		return {}
	end
end

--- Restores data from the schema's data folder.
--- @param filePath string The file path relative to the schema's data folder.
--- @param default? any The default value to return if the data does not exist. Default is an empty table.
--- @return any # The restored data, or the default value.
--- @realm shared
function Schema.util.RestoreSchemaData(filePath, default)
	return Schema.util.RestoreData(
		filePath,
		default,
		Schema.util.JoinPath(PATH_DATA_DESIGN, Schema.util.GetSchemaFolder())
	)
end

--- Finds all files in a data folder.
--- @param filePath string The file path relative to a data folder. Can contain a wildcard.
--- @param baseFolder string The base folder to save the data in.
--- @return table, table # The files found, and the directories found.
--- @realm shared
function Schema.util.FindData(filePath, baseFolder)
	filePath = Schema.util.FileEnsureExtension(filePath, "txt")

	return file.Find(
		Schema.util.JoinPath(baseFolder, filePath),
		"DATA"
	)
end

--- Finds all files in the schema's data folder.
--- @param filePath string The file path relative to the schema's data folder. Can contain a wildcard.
--- @return table, table # The files found, and the directories found.
--- @realm shared
function Schema.util.FindSchemaData(filePath)
	return Schema.util.FindData(
		filePath,
		Schema.util.JoinPath(PATH_DATA_DESIGN, Schema.util.GetSchemaFolder())
	)
end

function Schema.util.GetUniqueID()
	return tostring({})
end

--- Converts Source Engine units (1 unit = 1 inch) to centimeters (1 unit = 2.54 cm)
--- @param unit any
--- @return unknown
function Schema.util.UnitToCentimeters(unit)
	return unit * 2.54
end

--- Converts a time in seconds to a short nice time format (e.g: 2s, 1m, 1h)
--- @param time number The time in seconds.
--- @return string
function Schema.util.GetNiceShortTime(time)
	local text = string.NiceTime(time)

	local parts = text:Split(" ")
	local last = parts[#parts]

	return parts[1] .. last:sub(1, 1):lower()
end

--- Encodes a string for use in an URL.
--- @param inputString string The string to encode.
--- @return string # The encoded string.
function Schema.util.UrlEncode(inputString)
	local result, _ = string.gsub(inputString, "([^%w%.%- ])", function(c)
		return string.format("%%%02X", string.byte(c))
	end):gsub(" ", "+")

	return result
end

--- Quickly perform English pluralization.
--- @deprecated You should use `L` and language localization instead for better support for other languages.
--- @param singular string The singular form of the word
--- @param amount number The value to determine the pluralization
--- @return string
--- @realm shared
function Schema.util.Pluralize(singular, amount)
	if (amount == 1) then
		return singular
	end

	return singular .. "s"
end

--- Returns whether the given value is safe to use as a file name.
--- @param value string
--- @return boolean
--- @realm shared
function Schema.util.IsSafeFileName(value)
	-- Check for any character that is not a letter (%w), digit (%d), space (%s), period (.), hyphen (-), or underscore (_).
	return string.match(value, "^[%w%d%s%.%-%_]+$") ~= nil
end

--- Copies a table, but ignores cyclic references. This is useful for
--- copying tables needed to be JSON encoded.
--- @param target table The table to copy
--- @param copied? table Already copied tables
--- @return table # The new table copy
--- @realm shared
function Schema.util.CopyOmitCyclicReference(target, copied)
	copied = copied or {}
	local newTable = {}

	copied[target] = newTable

	for k, v in pairs(target) do
		if (istable(v)) then
			-- Skip already copied tables to avoid cyclic references
			if (not copied[v]) then
				newTable[k] = Schema.util.CopyOmitCyclicReference(v, copied)
			end
		else
			newTable[k] = v
		end
	end

	return newTable
end

--- Creates a scope that allows only a single transaction to be active at a time.
--- @param scope string
--- @param callback fun(release: fun())
--- @param client? any If provided, the scope will be unique to the client.
--- @return boolean
function Schema.util.RunSingleWithinScope(scope, callback, client)
	if (client) then
		scope = scope .. "_" .. client:SteamID64()
	end

	if (Schema.util.transactions[scope] ~= nil) then
		return false
	end

	Schema.util.transactions[scope] = true

	local release = function()
		Schema.util.transactions[scope] = nil
	end

	local success, err = pcall(callback, release)

	if (not success) then
		ix.util.SchemaErrorNoHalt("Schema.util.RunSingleWithinScope: " .. err .. "\n")
		release()
	end

	return true
end

--- Returns true if the throttle is active, otherwise false.
--- @param scope string
--- @param delay number
--- @param entity Entity? If provided, the throttle will be unique to the entity.
--- @return boolean, number?
function Schema.util.Throttle(scope, delay, entity)
	local scopeTable = Schema.util.throttles

	if (entity) then
		scopeTable = entity.expThrottles or {}
		entity.expThrottles = scopeTable
	end

	if (scopeTable[scope] == nil) then
		scopeTable[scope] = CurTime() + delay

		return false
	end

	local throttled = scopeTable[scope] > CurTime()

	if (not throttled) then
		scopeTable[scope] = CurTime() + delay

		return false
	end

	return throttled, math.ceil(scopeTable[scope] - CurTime())
end

--- Expands the bounds of a cube to a list of points.
--- @param boundsMin Vector
--- @param boundsMax Vector
--- @param relativePosition Vector
--- @param relativeAngles Angle
function Schema.util.ExpandBoundsToCube(boundsMin, boundsMax, relativePosition, relativeAngles)
	local corners = {
		Vector(boundsMin.x, boundsMin.y, boundsMin.z),
		Vector(boundsMin.x, boundsMin.y, boundsMax.z),
		Vector(boundsMin.x, boundsMax.y, boundsMin.z),
		Vector(boundsMin.x, boundsMax.y, boundsMax.z),
		Vector(boundsMax.x, boundsMin.y, boundsMin.z),
		Vector(boundsMax.x, boundsMin.y, boundsMax.z),
		Vector(boundsMax.x, boundsMax.y, boundsMin.z),
		Vector(boundsMax.x, boundsMax.y, boundsMax.z),
	}

	local cube = {}

	for _, corner in ipairs(corners) do
		local relativeCornerPosition, relativeCornerAngles = LocalToWorld(corner, Angle(0, 0, 0), relativePosition,
			relativeAngles)

		table.insert(cube, relativeCornerPosition)
	end

	return cube
end

--- Traces from each corner of a cube to the first corner to see if it's colliding with anything
function Schema.util.TracePointsHit(points, filter, drawDebug)
	for k, corner in ipairs(points) do
		local trace = util.TraceLine({
			start = corner,
			endpos = points[1],
			filter = filter
		})

		if (drawDebug) then
			debugoverlay.Line(corner, trace.HitPos, 5, trace.Hit and Color(255, 0, 0) or Color(0, 255, 0), true)
		end

		if (trace.Hit) then
			return trace
		end
	end
end

--- Converts a .env file to a table.
--- @param envFileContents string
function Schema.util.EnvToTable(envFileContents)
	local variables = {}

	for line in envFileContents:gmatch("[^\r\n]+") do
		local key, value = line:match("([^=]+)=(.+)")

		if (key and value) then
			-- Trim whitespace and quotes from the start and end of the value.
			variables[key] = value:match("^%s*(.-)%s*$"):match("^\"(.-)\"$") or value
		end
	end

	return variables
end

--- Gets the player's IP address and port as a table.
--- @param clientOrAddress Player|string
--- @return table
function Schema.util.GetPlayerAddress(clientOrAddress)
	local address = isstring(clientOrAddress) and clientOrAddress or clientOrAddress:IPAddress()

	if (address == "loopback") then
		-- Helpful for testing locally
		address = "127.0.0.1:27005"
	end

	local ip, port = address:match("([^:]+):(%d+)")

	return {
		ip = ip,
		port = tonumber(port)
	}
end

function Schema.util.AllPlayersExcept(excludedClients)
	excludedClients = istable(excludedClients) and excludedClients or { excludedClients }

	local players = {}

	for _, client in ipairs(player.GetAll()) do
		if (not table.HasValue(excludedClients, client)) then
			table.insert(players, client)
		end
	end

	return players
end

function Schema.util.ReloadMap()
	local currentLevel = game.GetMap()

	RunConsoleCommand("changelevel", currentLevel)
end

function Schema.util.ForceConVars(conVarsToSet)
	for conVarName, value in pairs(conVarsToSet) do
		if (value.isServer and not SERVER) then
			continue
		elseif (! value.isServer and not CLIENT) then
			continue
		end

		local conVar = GetConVar(conVarName)
		value = value.value

		if (! conVar) then
			ix.util.SchemaErrorNoHalt("ConVar " .. conVarName .. " does not exist in conVarsToSet.")
			continue
		end

		if (isbool(value)) then
			conVar:SetBool(value)
		elseif (isnumber(value)) then
			conVar:SetInt(value)
		elseif (isstring(value)) then
			conVar:SetString(value)
		else
			ix.util.SchemaErrorNoHalt("Invalid value type for conVar " .. conVarName .. " in conVarsToSet.")
		end
	end
end

if (CLIENT) then
	function Schema.util.RunInventoryAction(itemID, inventoryID, action, data)
		net.Start("ixInventoryAction")
		net.WriteString(action)
		net.WriteUInt(itemID, 32)
		net.WriteUInt(inventoryID, 32)
		net.WriteTable(data or {})
		net.SendToServer()
	end

	function Schema.util.LookupBinding(bind, forceUpper)
		local binding = input.LookupBinding(bind)

		if (not binding) then
			return forceUpper and bind:upper() or bind
		end

		local translationKey = "bind_" .. binding:lower()
		local name = L(translationKey)

		local key = name ~= translationKey and name or binding:upper()

		if (forceUpper) then
			key = key:upper()
		end

		return key
	end

	--- Finds bindings surrounded by curly braces and replaces them with their actual key.
	--- @param text string
	--- @return string
	function Schema.util.ReplaceBindings(text)
		local replacement = text:gsub("{(.-)}", function(bind)
			return Schema.util.LookupBinding(bind) or ("{" .. bind .. "}")
		end)

		return replacement
	end

	--- Replaces all bindings in SWEP.Instructions
	function Schema.util.FillWeaponBindings()
		local allWeapons = weapons.GetList()

		for _, weapon in ipairs(allWeapons) do
			if (not weapon.Instructions) then
				continue
			end

			-- For weapons inside Helix, we replace them ourselves
			local instructions = weapon.Instructions
				:Replace("Primary Fire", "{+attack}")
				:Replace("Secondary Fire + Mouse", "{+attack2} + Move Mouse")
				:Replace("Secondary Fire", "{+attack2}")
				:Replace("Reload", "{+reload}")

			instructions = Schema.util.ReplaceBindings(instructions)
			weapons.GetStored(weapon.ClassName).Instructions = instructions

			-- If the player has the weapon equipped, we update the weapon's instructions
			local weaponEntity = LocalPlayer():GetWeapon(weapon.ClassName)

			if (IsValid(weaponEntity)) then
				weaponEntity.Instructions = instructions
			end
		end
	end

	hook.Add("InitPostEntity", "expFillWeaponBindingsOnInitialize", Schema.util.FillWeaponBindings)
	hook.Add("OnReloaded", "expFillWeaponBindingsOnReloaded", Schema.util.FillWeaponBindings)

	--- Replaces a material texture with another texture for all models/ui that use it.
	--- @param material IMaterial
	--- @param replacement IMaterial
	--- @param keyValues? table|number
	function Schema.util.ReplaceMaterialTexture(material, replacement, keyValues)
		local replacementTexture = replacement:GetTexture("$basetexture")

		material:SetTexture("$basetexture", replacementTexture)

		-- Since 'Material' also returns a number as the second return value, we want to make sure it's a table.
		if (istable(keyValues)) then
			for key, value in pairs(keyValues) do
				local valueType = type(value)
				if (valueType == "number") then
					material:SetFloat(key, value)
				elseif (valueType == "VMatrix") then
					material:SetMatrix(key, value)
				elseif (valueType == "string") then
					material:SetString(key, value)
				elseif (valueType == "ITexture") then
					material:SetTexture(key, value)
				elseif (valueType == "Vector") then
					material:SetVector(key, value)
				else
					error("Invalid value type for keyValues: " .. valueType)
				end
			end
		end
	end

	--- Returns the HTML of the requested HTML file.
	--- Use tools/generate-html.sh to convert the HTML files in html/ to the cl_html.generated.lua file.
	--- We do this so development of the HTML files is easier, because we get proper syntax highlighting.
	--- @param path string
	--- @return string
	function Schema.util.GetHtml(path)
		-- Only include the file inside the function, so the HTML isn't kept in memory for the entire game session.
		local allHtml = include(Schema.folder .. "/schema/content/cl_html.generated.lua")
		local html = allHtml[path]

		if (not html) then
			error("HTML file not found: " .. path)
		end

		return html
	end
end
