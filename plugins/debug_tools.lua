local PLUGIN = PLUGIN

PLUGIN.name = "Debug Tools"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Adds various tools for debugging."
PLUGIN.alphaTestMessageInterval = 60 * 15

ix.config.Add(
	"alphaTestMessage",
	"Welcome to Experiment Redux! You are part of the Beta Test. "
	.. "Please report bugs by sending /ReportBug in chat."
	.. "\nThanks for your help and patience.",
	"Message to display at an interval to signal that the server is being tested.",
	nil,
	{
		category = "Server"
	}
)

_G["PT"] = PrintTable

if (SERVER) then
	function PLUGIN:PlayerSpawn(client)
		for k, otherClient in ipairs(player.GetAll()) do
			-- P1, P2, etc... to get a player by index
			_G["P" .. k] = otherClient

			-- P1T(), P2T(), etc... to get an eye trace from a player by index
			_G["P" .. k .. "T"] = function()
				return otherClient:GetEyeTraceNoCursor()
			end

			-- P1C(), P2C(), etc... to get a player's character by index
			_G["P" .. k .. "C"] = function()
				return otherClient:GetCharacter()
			end

			-- P1CI(), P2CI(), etc... to get a player's character's inventory by index
			_G["P" .. k .. "CI"] = function()
				return otherClient:GetCharacter():GetInventory()
			end

			-- P1K() to kill a player by index
			_G["P" .. k .. "K"] = function()
				otherClient:Kill()
			end
		end
	end

	function PLUGIN:Think()
		local alphaTestMessage = ix.config.Get("alphaTestMessage", "")

		if (alphaTestMessage == "") then
			return
		end

		if (not Schema.util.Throttle("alphaTestMessage", self.alphaTestMessageInterval)) then
			ix.chat.Send(nil, "notice", alphaTestMessage)
		end
	end
else
	function PLUGIN:InitPostEntity()
		_G["LP"] = LocalPlayer()
		_G["LPT"] = function()
			return LocalPlayer():GetEyeTraceNoCursor()
		end
	end
end

do
	local COMMAND = {}

	COMMAND.description = "Give yourself every item which has an uniqueID that matches the provided pattern."
	COMMAND.arguments = {
		ix.type.string,
	}

	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, pattern)
		local items = ix.item.list
		local count = 0

		for _, item in pairs(items) do
			if (item.uniqueID:match(pattern)) then
				client:GetCharacter():GetInventory():Add(item.uniqueID)
				count = count + 1
			end
		end

		client:Notify("You have been given " .. count .. " items that match the pattern '" .. pattern .. "'.")
	end

	ix.command.Add("CharGiveAllItems", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Query the database for the item with the specified ID."
	COMMAND.arguments = {
		ix.type.number,
	}

	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, itemID)
		-- Display the item as it exists in ix.item.instances,
		-- Also query the database to show what item information exists on it
		-- Also list the inventories it is a part of.
		-- Take into account that any can be nil (this is for debugging)
		local item = ix.item.instances[itemID]

		if (item) then
			client:Notify("ix.item.instances found!")
			PrintTable(item)
		end

		local query = mysql:Select("ix_items")
		query:Select("item_id")
		query:Select("unique_id")
		query:Select("data")
		query:Select("inventory_id")
		query:Select("character_id")
		query:Select("player_id")
		query:Select("x")
		query:Select("y")
		query:Select("data")
		query:Where("item_id", itemID)
		query:Callback(function(result, status)
			if (istable(result)) then
				if (#result > 0) then
					client:Notify("Query result:")
					PrintTable(result)
				else
					client:Notify("No results found.")
				end
			else
				client:Notify("Query failed.")
			end
		end)

		query:Execute()
	end

	ix.command.Add("DebugItemInfo", COMMAND)
end
