local PLUGIN = PLUGIN

function PLUGIN:DatabaseConnected()
	local query

	-- One row per player with aggregated data
	query = mysql:Create("exp_player_hit_stats")
	query:Create("character_id", "INT(11) UNSIGNED NOT NULL")
	query:Create("steam_id", "VARCHAR(20) NOT NULL")

	query:Create("total_shots", "INT(11) UNSIGNED DEFAULT 0")

	query:Create("hits_generic", "INT(11) UNSIGNED DEFAULT 0")
	query:Create("hits_head", "INT(11) UNSIGNED DEFAULT 0")
	query:Create("hits_chest", "INT(11) UNSIGNED DEFAULT 0")
	query:Create("hits_stomach", "INT(11) UNSIGNED DEFAULT 0")
	query:Create("hits_leftarm", "INT(11) UNSIGNED DEFAULT 0")
	query:Create("hits_rightarm", "INT(11) UNSIGNED DEFAULT 0")
	query:Create("hits_leftleg", "INT(11) UNSIGNED DEFAULT 0")
	query:Create("hits_rightleg", "INT(11) UNSIGNED DEFAULT 0")
	query:Create("hits_gear", "INT(11) UNSIGNED DEFAULT 0")

	query:Create("kills", "INT(11) UNSIGNED DEFAULT 0")
	query:Create("deaths", "INT(11) UNSIGNED DEFAULT 0")
	query:Create("headshot_kills", "INT(11) UNSIGNED DEFAULT 0")

	query:Create("last_updated", "INT(11) UNSIGNED NOT NULL")

	query:PrimaryKey("character_id")
	query:Execute()
end

function PLUGIN:OnWipeTables()
	local query
	query = mysql:Drop("exp_player_hit_stats")
	query:Execute()
end

function PLUGIN:PostEntityFireBullets(entity, bulletInfo)
	if (not entity:IsPlayer()) then
		return
	end

	local weapon = entity:GetActiveWeapon()

	if (not IsValid(weapon)) then
		return
	end

	-- Commented since TacRP only fired multiple bullets with penetration, which we disabled.
	-- -- Some TacRP weapons fire multiple bullets over multiple frames. This delay
	-- -- will ensure we count only once for each bullet fired, hopefully not missing
	-- -- any when automatic firing.
	-- if (Schema.util.Throttle("shotFiredTracker", 0.001, entity)) then
	-- 	return
	-- end

	self:IncrementPendingStat(entity, "shots_fired", 1)
end

-- Track damage dealt to other players with body part information
function PLUGIN:ScalePlayerDamage(target, hitgroup, damageInfo)
	local attacker = damageInfo:GetAttacker()

	if (not IsValid(attacker) or not attacker:IsPlayer()) then
		return
	end

	-- Don't track self-damage
	if (attacker == target) then
		return
	end

	self:IncrementPendingHit(attacker, hitgroup)
end

-- Track when players are killed (for kill/death ratios)
function PLUGIN:PlayerDeath(victim, inflictor, attacker)
	if (not IsValid(attacker) or not attacker:IsPlayer()) then
		return
	end

	if (not IsValid(victim) or not victim:IsPlayer()) then
		return
	end

	-- Don't track suicide
	if (attacker == victim) then
		return
	end

	self:IncrementPendingStat(attacker, "kills", 1)
	self:IncrementPendingStat(victim, "deaths", 1)

	-- Check if it was a headshot kill
	local hitgroup = victim:LastHitGroup() or HITGROUP_GENERIC

	if (hitgroup == HITGROUP_HEAD) then
		self:IncrementPendingStat(attacker, "headshot_kills", 1)
	end
end

-- Save all pending stats to database
function PLUGIN:SaveData()
	if (table.IsEmpty(self.pendingStats)) then
		return
	end

	for characterID, stats in pairs(self.pendingStats) do
		local character = ix.char.loaded[characterID]

		if (not character) then
			continue
		end

		local steamID = character.steamID

		-- Build the update expressions for ON DUPLICATE KEY UPDATE
		local updates = {}
		local insertColumns = { "character_id", "steam_id" }
		local insertValues = { characterID, "'" .. steamID .. "'" }

		if (stats.shots_fired) then
			table.insert(updates, "total_shots = total_shots + " .. stats.shots_fired)
			table.insert(insertColumns, "total_shots")
			table.insert(insertValues, stats.shots_fired)
		end

		if (stats.kills) then
			table.insert(updates, "kills = kills + " .. stats.kills)
			table.insert(insertColumns, "kills")
			table.insert(insertValues, stats.kills)
		end

		if (stats.deaths) then
			table.insert(updates, "deaths = deaths + " .. stats.deaths)
			table.insert(insertColumns, "deaths")
			table.insert(insertValues, stats.deaths)
		end

		if (stats.headshot_kills) then
			table.insert(updates, "headshot_kills = headshot_kills + " .. stats.headshot_kills)
			table.insert(insertColumns, "headshot_kills")
			table.insert(insertValues, stats.headshot_kills)
		end

		-- Add hitgroup updates
		for hitgroupID, count in pairs(stats.hits or {}) do
			local hitgroupName = self.hitgroupNames[hitgroupID]

			if (hitgroupName) then
				local columnName = "hits_" .. string.lower(string.gsub(hitgroupName, " ", ""))
				table.insert(updates, columnName .. " = " .. columnName .. " + " .. count)
				table.insert(insertColumns, columnName)
				table.insert(insertValues, count)
			end
		end

		if (#updates > 0) then
			-- Add last_updated to both insert and update
			table.insert(updates, "last_updated = " .. os.time())
			table.insert(insertColumns, "last_updated")
			table.insert(insertValues, os.time())

			if (mysql.module == "mysqloo") then
				local query = [[
					INSERT INTO exp_player_hit_stats (]] .. table.concat(insertColumns, ", ") .. [[)
					VALUES (]] .. table.concat(insertValues, ", ") .. [[)
					ON DUPLICATE KEY UPDATE ]] .. table.concat(updates, ", ")

				mysql:RawQuery(query)
			elseif (mysql.module == "sqlite") then
				local query = [[
					INSERT INTO exp_player_hit_stats (]] .. table.concat(insertColumns, ", ") .. [[)
					VALUES (]] .. table.concat(insertValues, ", ") .. [[)
					ON CONFLICT(character_id) DO UPDATE SET ]] .. table.concat(updates, ", ")

				mysql:RawQuery(query)
			else
				ix.util.SchemaError("hit_statistics: Unsupported MySQL module: " .. mysql.module)
			end
		end
	end

	-- Clear pending stats after saving
	self.pendingStats = {}
end
