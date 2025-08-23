Schema.spawnPoints = ix.util.GetOrCreateLibrary("spawnPoints", {
	spawns = {},

	spawnStatus = {
		SAFE = 0,
		DANGER = 1,
		LOCKED = 2,
		CHAOS = 3,
	},

	spawnResult = {
		OK = 0,
		FAIL = 1,
	},
})

function Schema.spawnPoints.GetMapDetails()
	local maps = Schema.map.FindByProperty("mapName", game.GetMap(), true)

	if (#maps == 0) then
		return nil
	end

	if (#maps > 1) then
		ix.util.SchemaError("Duplicate map details found for '" .. game.GetMap() .. "'!\n")
	end

	return maps[1]
end
