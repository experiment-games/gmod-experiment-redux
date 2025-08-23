Schema.achievement = ix.util.GetOrCreateCommonLibrary("achievement")

if (SERVER) then
	util.AddNetworkString("expAchievementProgress")
	util.AddNetworkString("expAchievementsLoad")

	--- Progress an achievement, optionally with a specific amount.
	--- If the progress is a string, it will be used as a key to track progress (1 progression per key)
	--- @param achievement any
	--- @param client Player
	--- @param progress any
	--- @return boolean
	function Schema.achievement.Progress(achievement, client, progress)
		local achievementTable = Schema.achievement.Get(achievement)
		local achievements = client:GetData("achievements", {})

		if (isstring(progress)) then
			local achievementProgressKeys = client:GetData("achievementProgressKeys", {})

			if (achievementProgressKeys[progress]) then
				return false
			end

			achievementProgressKeys[progress] = true
			client:SetData("achievementProgressKeys", achievementProgressKeys)

			progress = 1
		end

		if (not progress) then
			progress = 1
		end

		if (not achievementTable) then
			ix.log.Add(
				client,
				"schemaDebug",
				"Schema.achievement.Progress",
				"Attempted to progress an achievement that does not exist."
			)
			return false
		end

		local currentAchievement = achievements[achievementTable.uniqueID] or 0

		if (currentAchievement == achievementTable.maximum) then
			return false
		end

		achievements[achievementTable.uniqueID] = math.Clamp(
			currentAchievement + progress,
			0,
			achievementTable.maximum
		)
		client:SetData("achievements", achievements)

		if (achievements[achievementTable.uniqueID] < achievementTable.maximum) then
			if (achievementTable.OnProgress) then
				achievementTable:OnProgress(client, achievements[achievementTable.uniqueID])
			end
		else
			ix.chat.Send(client, "achievement", achievementTable.name)

			if (achievementTable.reward) then
				client:GetCharacter():GiveMoney(achievementTable.reward)
			end

			if (achievementTable.OnAchieved) then
				achievementTable:OnAchieved(client)
			end

			hook.Run("OnAchievementAchieved", client, achievementTable)
		end

		net.Start("expAchievementProgress")
		net.WriteUInt(achievementTable.index, 32)
		net.WriteUInt(achievements[achievementTable.uniqueID], 16)
		net.Send(client)

		return true
	end

	function Schema.achievement.LoadProgress(client, character)
		local achievements = client:GetData("achievements", {})

		net.Start("expAchievementsLoad")
		net.WriteTable(achievements)
		net.Send(client)
	end

	function Schema.achievement.HasAchieved(achievement, client)
		local achievementTable = Schema.achievement.Get(achievement)

		if (achievementTable) then
			if (Schema.achievement.GetProgress(achievement, client) == achievementTable.maximum) then
				return true
			end
		end

		return false
	end

	function Schema.achievement.GetProgress(achievement, client)
		local achievementTable = Schema.achievement.Get(achievement)
		local achievements = client:GetCharacter():GetData("achievements", {})

		if (achievementTable) then
			return achievements[achievementTable.uniqueID] or 0
		else
			return 0
		end
	end
else
	Schema.achievement.localAchieved = Schema.achievement.localAchieved or {}

	function Schema.achievement.GetPanel()
		return ix.gui.achievementsPanel
	end

	function Schema.achievement.UpdatePanel()
		local panel = Schema.achievement.GetPanel()

		if (IsValid(panel)) then
			panel:Update()
		end
	end

	function Schema.achievement.GetProgress(achievement)
		local achievementTable = Schema.achievement.Get(achievement)

		if (achievementTable) then
			return Schema.achievement.localAchieved[achievementTable.uniqueID] or 0
		else
			return 0
		end
	end

	function Schema.achievement.HasAchieved(achievement)
		local achievementTable = Schema.achievement.Get(achievement)

		if (achievementTable) then
			if (Schema.achievement.GetProgress(achievement) == achievementTable.maximum) then
				return true
			end
		end

		return false
	end

	net.Receive("expAchievementProgress", function(msg)
		local achievement = net.ReadUInt(32)
		local progress = net.ReadUInt(16)
		local achievementTable = Schema.achievement.Get(achievement)

		if (not achievementTable) then
			error("Achievement with index " .. achievement .. " does not exist.")
			return
		end

		Schema.achievement.localAchieved[achievementTable.uniqueID] = progress

		Schema.achievement.UpdatePanel()
	end)

	net.Receive("expAchievementsLoad", function()
		local achievements = net.ReadTable()
		Schema.achievement.localAchieved = {}

		for uniqueID, progress in pairs(achievements) do
			local achievement = Schema.achievement.Get(uniqueID)

			if (not achievement) then
				continue
			end

			Schema.achievement.localAchieved[uniqueID] = progress
		end

		Schema.achievement.UpdatePanel()
	end)
end
