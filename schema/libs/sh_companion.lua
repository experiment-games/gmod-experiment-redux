--- Shared library to handle common companion functions.
--- @realm shared
Schema.companion = ix.util.GetOrCreateLibrary("companion")

-- Normally these are only available on the server, so we need to define them on the client if
-- we want to network them.
if (CLIENT) then
	-- https://wiki.facepunch.com/gmod/Enums/D
	D_ER = 0
	D_HT = 1
	D_FR = 2
	D_LI = 3
	D_NU = 4
end

--- @realm shared
--- @class TrainDisposition
--- @field disposition number
--- @field message string
--- @field value? number
--- @field icon string
--- @field order? number
--- @field key? string

--- Available trainable dispositions
--- @type table<string, TrainDisposition>
Schema.companion.TRAINING_MAP = {
	["like"] = {
		disposition = D_LI,
		message = "like",
		value = 99,
		icon = "icon16/heart_add.png",
		order = 1,
	},
	["neutral"] = {
		disposition = D_NU,
		message = "be neutral towards",
		icon = "icon16/bin.png",
		order = 2,
	},
	["hate"] = {
		disposition = D_HT,
		message = "hate",
		icon = "icon16/heart_delete.png",
		order = 3,
	},
}

Schema.companion.DEFAULT_DISPOSITION = Schema.companion.TRAINING_MAP["neutral"]

-- Stores the key for each disposition in the training map.
for key, value in pairs(Schema.companion.TRAINING_MAP) do
	Schema.companion.TRAINING_MAP[key].key = key
end

--- Checks if the player is close enough to command a companion entity.
--- @param player Player The player to check.
--- @param companion Entity The companion entity to check.
--- @return boolean, string? # Whether the player is close enough to command the companion, and an optional failure message.
--- @realm shared
function Schema.companion.PlayerIsCloseEnoughToCommand(player, companion)
	local distance = player:GetPos():DistToSqr(companion:GetPos())

	if (distance <= (1024 * 1024)) then
		return true
	end

	return false, "You aren't close enough to command this companion!"
end
