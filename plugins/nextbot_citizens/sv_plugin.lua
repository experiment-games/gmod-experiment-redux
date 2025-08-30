local PLUGIN = PLUGIN

function PLUGIN:AddBotCitizen(bot)
	if (not self.botCitizens) then
		self.botCitizens = {}
	end

	table.insert(self.botCitizens, bot)
end

function PLUGIN:RemoveBotCitizen(bot)
	if (not self.botCitizens) then
		return
	end

	for i, citizen in ipairs(self.botCitizens) do
		if (citizen == bot) then
			table.remove(self.botCitizens, i)
			break
		end
	end
end

function PLUGIN:GetBotCitizens()
	return self.botCitizens or {}
end

function PLUGIN:RemoveAllBotCitizens()
	if (not self.botCitizens) then
		return 0
	end

	local count = 0

	for _, bot in pairs(self.botCitizens) do
		if (IsValid(bot)) then
			bot:Remove()
			count = count + 1
		end
	end

	self.botCitizens = {}
	return count
end
