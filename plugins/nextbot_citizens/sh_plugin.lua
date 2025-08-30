local PLUGIN = PLUGIN

PLUGIN.name = "NextBot Citizens"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Add NextBot citizens to fill the city with life."

ix.util.Include("sv_plugin.lua")

do
	local COMMAND = {}
	COMMAND.description = "Spawn a NextBot at your crosshair location."
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client)
		local trace = client:GetEyeTraceNoCursor()

		if (not trace.Hit or trace.HitSky) then
			client:Notify("Invalid spawn location!")
			return
		end

		local walkSpeed = ix.config.Get("walkSpeed")
		local runSpeed = ix.config.Get("runSpeed")
		local bot = ents.Create("exp_nextbot_citizen")
		bot:SetPos(trace.HitPos)
		bot:SetWalkSpeed(walkSpeed)
		bot:SetRunSpeed(runSpeed)
		bot:Spawn()

		bot:SetWeaponList({
			"exp_tacrp_ex_glock", -- Close range
			"exp_tacrp_uzi", -- Medium range
			"exp_tacrp_ak47", -- Long range
			"exp_tacrp_m_crowbar.lua" -- Melee backup
		})

		PLUGIN:AddBotCitizen(bot)
		client:Notify("NextBot spawned successfully.")
	end

	ix.command.Add("CitizenBotSpawn", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "Remove all spawned NextBots."
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client)
		local count = PLUGIN:RemoveAllBotCitizens()

		if (count > 0) then
			client:Notify("Removed " .. count .. " NextBot(s).")
		else
			client:Notify("No NextBots to remove.")
		end
	end

	ix.command.Add("CitizenBotRemoveAll", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "Set the home entity for all NextBots to the entity you're looking at."
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client)
		local trace = client:GetEyeTraceNoCursor()
		local bots = PLUGIN:GetBotCitizens()

		if (#bots == 0) then
			client:Notify("No NextBots spawned!")
			return
		end

		local homeEntity = trace.Entity
		if (not IsValid(homeEntity)) then
			client:Notify("Invalid home entity!")
			return
		end

		local count = 0
		for _, bot in pairs(bots) do
			if (IsValid(bot) and bot.SetHomeEntity) then
				bot:SetHomeEntity(homeEntity)
				count = count + 1
			end
		end

		client:Notify("Set home entity for " .. count .. " NextBot(s).")
	end

	ix.command.Add("CitizenBotSetHome", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "Set a task for all NextBots with the specified urgency level."
	COMMAND.arguments = {
		ix.type.number
	}
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, urgency)
		urgency = urgency or 2

		local trace = client:GetEyeTraceNoCursor()
		local bots = PLUGIN:GetBotCitizens()

		if (#bots == 0) then
			client:Notify("No NextBots spawned!")
			return
		end

		local taskEntity = trace.Entity
		if (not IsValid(taskEntity)) then
			client:Notify("Invalid task entity!")
			return
		end

		local count = 0
		for _, bot in pairs(bots) do
			if (IsValid(bot) and bot.SetTaskUrgency and bot.SetTaskEntity) then
				bot:SetTaskUrgency(urgency)
				bot:SetTaskEntity(taskEntity)
				count = count + 1
			end
		end

		client:Notify("Set task for " .. count .. " NextBot(s) with urgency level " .. urgency .. ".")
	end

	ix.command.Add("CitizenBotSetTask", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "Set all NextBots to aggressive mode against you."
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client)
		local bots = PLUGIN:GetBotCitizens()

		if (#bots == 0) then
			client:Notify("No NextBots spawned!")
			return
		end

		local count = 0
		for _, bot in pairs(bots) do
			if (IsValid(bot) and bot.SetAggressiveMode) then
				bot:SetAggressiveMode(client)
				count = count + 1
			end
		end

		client:Notify("Set " .. count .. " NextBot(s) to aggressive mode against you.")
	end

	ix.command.Add("CitizenBotSetAggressive", COMMAND)
end

do
	local COMMAND = {}
	COMMAND.description = "Set all NextBots to defensive mode."
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client)
		local bots = PLUGIN:GetBotCitizens()

		if (#bots == 0) then
			client:Notify("No NextBots spawned!")
			return
		end

		local count = 0

		for _, bot in pairs(bots) do
			if (IsValid(bot) and bot.SetDefensiveMode) then
				bot:SetDefensiveMode()
				count = count + 1
			end
		end

		client:Notify("Set " .. count .. " NextBot(s) to defensive mode.")
	end

	ix.command.Add("CitizenBotSetDefensive", COMMAND)
end
