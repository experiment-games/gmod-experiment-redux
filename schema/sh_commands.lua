--[[
	Alliance Commands
--]]

do
	local COMMAND = {}

	COMMAND.description = "Create a new alliance."
	COMMAND.arguments = { ix.type.string }

	function COMMAND:OnRun(client, allianceName)
		Schema.alliance.RequestCreate(client, allianceName)
	end

	ix.command.Add("AllianceCreate", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Invite the character you are looking at to your alliance."

	function COMMAND:OnRun(client, target)
		local target = Schema.GetPlayer(client:GetEyeTraceNoCursor().Entity)

		if (not target) then
			client:Notify("Invalid target, or not looking at a character!")
			return
		end

		Schema.alliance.RequestInviteMember(client, target)
	end

	ix.command.Add("AllianceInvite", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Invite the specified character to your alliance."
	COMMAND.arguments = {
		ix.type.player
	}

	function COMMAND:OnRun(client, target)
		Schema.alliance.RequestInviteMember(client, target)
	end

	ix.command.Add("AllianceInviteByName", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Kick a character out of your alliance."
	COMMAND.arguments = { ix.type.character }

	function COMMAND:OnRun(client, target)
		Schema.alliance.RequestKick(client, target)
	end

	ix.command.Add("AllianceKick", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Set the rank of a member in your alliance."
	COMMAND.arguments = {
		ix.type.player,
		ix.type.number
	}

	function COMMAND:OnRun(client, member, rank)
		Schema.alliance.RequestSetRank(client, member, rank)
	end

	ix.command.Add("AllianceSetRank", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Kick a member from your alliance."
	COMMAND.arguments = { ix.type.player }

	function COMMAND:OnRun(client, member)
		Schema.alliance.RequestKick(client, member)
	end

	ix.command.Add("AllianceKick", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Leave your alliance."

	function COMMAND:OnRun(client)
		Schema.alliance.RequestLeave(client)
	end

	ix.command.Add("AllianceLeave", COMMAND)
end

--[[
	Entity commands
--]]

do
	local COMMAND = {}

	COMMAND.description = "Bump the entity position you are looking at towards where you are looking."
	COMMAND.arguments = {
		bit.bor(ix.type.number, ix.type.optional)
	}
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, amount)
		local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 1000
		data.filter = client
		local target = util.TraceLine(data).Entity

		if (not IsValid(target)) then
			client:Notify("You must look at a valid entity!")
			return
		end

		target:SetPos(target:GetPos() + client:GetAimVector() * (amount or 10))
	end

	ix.command.Add("EntityBump", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Remove entities of a certain class within a radius around you."
	COMMAND.arguments = {
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional)
	}
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, class, radius)
		local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 96
		data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target)) then
			if (target:IsPlayer()) then
				client:Notify("You must look at an entity, not a player!")
				return
			end

			class = target:GetClass()
		end

		local entities = ents.FindInSphere(client:GetPos(), radius or 256)
		local count = 0

		for _, entity in ipairs(entities) do
			if (entity:GetClass() == class) then
				count = count + 1
				entity:Remove()
			end
		end

		client:Notify("Removed " .. count .. " entities of class '" .. class .. "'.")
	end

	ix.command.Add("EntityRemove", COMMAND)
end

--[[
	NPC commands
--]]

do
	local COMMAND = {}

	COMMAND.description = "Spawn an NPC with the NPC config based on the id you provide."
	COMMAND.arguments = {
		ix.type.string,
	}
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, npcId)
		local npc = Schema.npc.Get(npcId)

		if (not npc) then
			client:Notify("Invalid NPC ID!")
			return
		end

		Schema.npc.SpawnForPlayer(npc, client)

		client:Notify("NPC spawned successfully.")
	end

	ix.command.Add("NpcSpawn", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Remove the NPC you are looking at."
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client)
		local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 96
		data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target) and target:GetClass() == "exp_npc") then
			target:Remove()
			client:Notify("NPC removed successfully.")
		else
			client:Notify("You must look at an NPC!")
		end
	end

	ix.command.Add("NpcRemove", COMMAND)
end

--[[
	Character commands
--]]

do
	local COMMAND = {}

	COMMAND.description = "Search the tied character you are looking at."

	function COMMAND:OnRun(client)
		local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 96
		data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target) and target:IsPlayer() and target:IsRestricted()) then
			if (! client:IsRestricted()) then
				Schema.SearchPlayer(client, target)
			else
				return "@notNow"
			end
		end
	end

	ix.command.Add("CharSearch", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "Fake damage to a certain body part of yourself or the character you are looking at."
	COMMAND.arguments = {
		bit.bor(ix.type.string, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional)
	}
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, bodyPart, amount)
		local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 96
		data.filter = client
		local target = util.TraceLine(data).Entity

		if (not IsValid(target) or not target:IsPlayer()) then
			target = client
		end

		amount = amount or 2

		if (not target:Alive()) then
			client:Notify("This character is dead!")
			return
		end

		bodyPart = (bodyPart or "head"):lower()
		local hitGroup = HITGROUP_HEAD

		if (bodyPart == "head") then
			hitGroup = HITGROUP_HEAD
		elseif (bodyPart == "chest") then
			hitGroup = HITGROUP_CHEST
		elseif (bodyPart == "stomach") then
			hitGroup = HITGROUP_STOMACH
		elseif (bodyPart == "leftarm" or bodyPart == "left arm") then
			hitGroup = HITGROUP_LEFTARM
		elseif (bodyPart == "rightarm" or bodyPart == "right arm") then
			hitGroup = HITGROUP_RIGHTARM
		elseif (bodyPart == "leftleg" or bodyPart == "left leg") then
			hitGroup = HITGROUP_LEFTLEG
		elseif (bodyPart == "rightleg" or bodyPart == "right leg") then
			hitGroup = HITGROUP_RIGHTLEG
		elseif (bodyPart == "gear") then
			hitGroup = HITGROUP_GEAR
		else
			client:Notify("Invalid body part specified!")
			return
		end

		local inflictor = client:GetActiveWeapon()
		local damageType = DMG_BULLET

		if (inflictor and inflictor.MeleeDamageType) then
			damageType = inflictor.MeleeDamageType
		end

		local damageInfo = DamageInfo()
		damageInfo:SetDamage(amount)
		damageInfo:SetAttacker(client)
		damageInfo:SetInflictor(inflictor)
		damageInfo:SetDamageType(damageType)

		Schema:ScalePlayerDamage(target, hitGroup, damageInfo)

		target:TakeDamageInfo(damageInfo)

		client:Notify("You have damaged " .. target:GetName() .. "'s " .. bodyPart .. " for " .. amount .. " damage.")
	end

	ix.command.Add("CharTakeDamage", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Gives the specified item to someone's locker inventory."
	COMMAND.arguments = {
		ix.type.character,
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional)
	}
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, target, item, amount)
		local lockerInventory = target:GetLockerInventory()

		if (not lockerInventory) then
			client:Notify("This character does not have a locker inventory! Have they opened a locker before?")
			return
		end

		local uniqueID = item:lower()

		if (! ix.item.list[uniqueID]) then
			for k, v in SortedPairs(ix.item.list) do
				if (ix.util.StringMatches(v.name, uniqueID)) then
					uniqueID = k

					break
				end
			end
		end

		amount = amount or 1
		local bSuccess, error = lockerInventory:Add(uniqueID, amount)

		if (bSuccess) then
			target:GetPlayer():NotifyLocalized("itemCreated")

			if (target ~= client:GetCharacter()) then
				return "@itemCreated"
			end
		else
			return "@" .. tostring(error)
		end
	end

	ix.command.Add("CharGiveItemLocker", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Applies a buff to yourself or the character you are looking at."
	COMMAND.arguments = {
		ix.type.string,
	}
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, buffUniqueID)
		if (not Schema.buff.Exists(buffUniqueID)) then
			client:Notify("Invalid Buff Unique ID!")
			return
		end

		local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 96
		data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target) and target:IsPlayer()) then
			client:Notify("Buff applied to " .. target:GetName() .. ".")
		else
			target = client
			client:Notify("Buff applied to yourself.")
		end

		Schema.buff.SetActive(target, buffUniqueID)
	end

	ix.command.Add("CharBuffActivate", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description =
	"Immediately removes all buffs of a certain type from yourself or the character you are looking at."
	COMMAND.arguments = {
		ix.type.string,
	}
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, buffUniqueID)
		if (not Schema.buff.Exists(buffUniqueID)) then
			client:Notify("Invalid Buff Unique ID!")
			return
		end

		local data = {}
		data.start = client:GetShootPos()
		data.endpos = data.start + client:GetAimVector() * 96
		data.filter = client
		local target = util.TraceLine(data).Entity

		if (not IsValid(target) or not target:IsPlayer()) then
			target = client
		end

		local expiredCount = Schema.buff.CheckExpired(target, function(client, buffTable, buff)
			return buffTable.uniqueID == buffUniqueID
		end)

		client:Notify("Removed " ..
			expiredCount .. " buffs of type '" .. buffUniqueID .. "' from " .. target:GetName() .. ".")
	end

	ix.command.Add("CharBuffExpire", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Bring the given character to where you are looking."
	COMMAND.arguments = {
		ix.type.character
	}
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, target)
		target = target:GetPlayer()

		target:SetPos(client:GetEyeTraceNoCursor().HitPos)

		client:Notify("You have brought " .. target:GetName() .. " to your location.")
	end

	ix.command.Add("CharBring", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Give the specified character a perk."
	COMMAND.arguments = {
		ix.type.character,
		ix.type.string
	}

	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, target, perkUniqueID)
		local perkTable = Schema.perk.Get(perkUniqueID)

		if (not perkTable) then
			client:Notify("Invalid Perk Unique ID!")
			return
		end

		Schema.perk.Give(target:GetPlayer(), perkUniqueID)
		client:Notify("You have given " .. target:GetName() .. " the '" .. perkTable.name .. "' perk.")
	end

	ix.command.Add("CharPerkGive", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Remove the specified perk from the given character."
	COMMAND.arguments = {
		ix.type.character,
		ix.type.string
	}

	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, target, perkUniqueID)
		local perkTable = Schema.perk.Get(perkUniqueID)

		if (not perkTable) then
			client:Notify("Invalid Perk Unique ID!")
			return
		end

		Schema.perk.Take(target:GetPlayer(), perkUniqueID)
		client:Notify("You have removed the '" .. perkTable.name .. "' perk from " .. target:GetName() .. ".")
	end

	ix.command.Add("CharPerkRemove", COMMAND)
end

--[[
	Commands for testing the scene-based cinematic system.
--]]

do
	local COMMAND = {}

	COMMAND.description = "Put a player in a cinematic scene."
	COMMAND.arguments = {
		ix.type.player,
		ix.type.string
	}

	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, target, sceneID)
		local success = Schema.cinematics.PutPlayerInScene(target, sceneID)

		if (success) then
			client:Notify("Put " .. target:Name() .. " in scene '" .. sceneID .. "'")
		else
			client:Notify("Failed to put " .. target:Name() .. " in scene '" .. sceneID .. "'")
		end
	end

	ix.command.Add("ScenePut", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Remove a player from their current scene."
	COMMAND.arguments = {
		ix.type.player
	}

	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, target)
		local currentScene = Schema.cinematics.GetPlayerScene(target)

		if (currentScene) then
			Schema.cinematics.RemovePlayerFromScene(target)
			client:Notify("Removed " .. target:Name() .. " from scene '" .. currentScene .. "'")
		else
			client:Notify(target:Name() .. " is not in any scene")
		end
	end

	ix.command.Add("SceneRemove", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Transition a player to a different scene."
	COMMAND.arguments = {
		ix.type.player,
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional)
	}

	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, target, newSceneID, fadeTime, blackPeriod)
		local success = Schema.cinematics.TransitionPlayerToScene(target, newSceneID, fadeTime, blackPeriod)

		if (success) then
			client:Notify("Transitioning " .. target:Name() .. " to scene '" .. newSceneID .. "'")
		else
			client:Notify("Failed to transition " .. target:Name() .. " to scene '" .. newSceneID .. "'")
		end
	end

	ix.command.Add("SceneTransition", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Show cinematic text to a player."
	COMMAND.arguments = {
		ix.type.player,
		ix.type.string,
		bit.bor(ix.type.number, ix.type.optional)
	}

	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, target, text, duration)
		Schema.cinematics.ShowCinematicText(target, text, duration)

		client:Notify("Showing text to " .. target:Name() .. ": '" .. text .. "'")
	end

	ix.command.Add("SceneText", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Check which scene a player is currently in."
	COMMAND.arguments = {
		ix.type.player
	}

	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, target)
		local currentScene = Schema.cinematics.GetPlayerScene(target)

		if (currentScene) then
			client:Notify(target:Name() .. " is in scene '" .. currentScene .. "'")
		else
			client:Notify(target:Name() .. " is not in any scene")
		end
	end

	ix.command.Add("SceneCheck", COMMAND)
end

--[[
	Commands for Spawn Points
--]]

do
	local COMMAND = {}

	COMMAND.description =
	"Make where you are standing (and the way you are looking) a spawn location, providing information on where it's located on the 2D map."
	COMMAND.arguments = {
		ix.type.string,
	}

	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, name)
		local position = client:GetPos()
		local angles = client:EyeAngles()

		Schema.spawnPoints.spawns[#Schema.spawnPoints.spawns + 1] = {
			name = name,
			position = position,
			angles = angles,
		}

		hook.Run("SaveData")

		client:Notify("You added a spawn point.")
	end

	ix.command.Add("SpawnAdd", COMMAND)
end

do
	local COMMAND = {}

	COMMAND.description = "Remove the spawn point closest to where you are looking."
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client)
		local position = client:GetPos()
		local closestSpawn
		local closestDistance = math.huge
		local maxDistance = 256

		for k, v in ipairs(Schema.spawnPoints.spawns) do
			local distance = v.position:Distance(position)

			if (distance > maxDistance) then
				continue
			end

			if (distance < closestDistance) then
				closestDistance = distance
				closestSpawn = k
			end
		end

		if (closestSpawn) then
			table.remove(Schema.spawnPoints.spawns, closestSpawn)

			hook.Run("SaveData")

			client:Notify("You removed a spawn point.")
		else
			client:Notify("No spawn points found.")
		end
	end

	ix.command.Add("SpawnRemove", COMMAND)
end
