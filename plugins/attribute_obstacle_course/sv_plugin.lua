local PLUGIN = PLUGIN

util.AddNetworkString("expObstacleCourseUpdate")

PLUGIN.obstacleCourses = PLUGIN.obstacleCourses or {}

--- Grace period before door opens
local QUEUE_PERIOD_SECONDS = 10

--- How long the door takes to close fully
local DOOR_CLOSE_DURATION_SECONDS = 10

--- How long the door stays open
local DOOR_OPEN_DURATION_SECONDS = 20

--- Minimum players required to start
local MIN_PLAYERS = 1

--- Attribute reward functions for finishing the course
local ATTRIBUTE_REWARDS = {
	acrobatics = function(finishPosition, numPlayers)
		local baseReward = 0.1
		local increasePerPlayer = 0.05

		return math.max(0.005,
			(baseReward + increasePerPlayer * (numPlayers - 1)) * (1 - (finishPosition - 1) / numPlayers)
		)
	end,

	agility = function(finishPosition, numPlayers)
		local baseReward = 0.05
		local increasePerPlayer = 0.04

		return math.max(0.005,
			(baseReward + increasePerPlayer * (numPlayers - 1)) * (1 - (finishPosition - 1) / numPlayers)
		)
	end,
}

concommand.Add("exp_list_attribute_rewards", function(client, command, arguments)
	if (not client:IsAdmin()) then
		return
	end

	local maxPlayers = tonumber(arguments[1]) or 10

	if (maxPlayers < 1) then
		print("Invalid number of players specified. Must be at least 1.")
		return
	end

	local header = string.format("%-12s", "Players:")

	for players = 1, maxPlayers do
		header = header .. string.format("%6d", players)
	end

	print(header .. "\nPosition:")

	for attrName, rewardFunc in pairs(ATTRIBUTE_REWARDS) do
		print("\nAttribute: " .. attrName)

		for pos = 1, maxPlayers do
			local line = string.format("%-12d", pos)

			for players = 1, maxPlayers do
				local reward = rewardFunc(pos, players)
				line = line .. string.format("%6.2f", reward)
			end

			print(line)
		end
	end
end)

function PLUGIN:InitializeObstacleCourse(courseID)
	if (self.obstacleCourses[courseID]) then
		return
	end

	self.obstacleCourses[courseID] = {
		waitingPlayers = {},
		activePlayers = {},
		finishedPlayers = {},
		graceTimer = nil,
		doorTimer = nil,
		isDoorOpen = false,
		isActive = false,
	}
end

function PLUGIN:GetPlayersOnObstacleCourse(courseID)
	if (not self.obstacleCourses[courseID]) then
		return {}
	end

	local validPlayers = {}

	for client, data in pairs(self.obstacleCourses[courseID].activePlayers) do
		if (IsValid(client)) then
			validPlayers[#validPlayers + 1] = client
		end
	end

	return validPlayers
end

function PLUGIN:IsObstacleCourseEmpty(courseID)
	local players = self:GetPlayersOnObstacleCourse(courseID)

	return #players == 0
end

--- Finds all start entities for this course and tell them to network
function PLUGIN:NetworkCourseUpdate(courseID)
	for _, ent in ipairs(ents.FindByClass("exp_obstacle_course_start")) do
		if (ent:GetCourseID() == courseID) then
			ent:NetworkCourseDataToAll(courseID)
		end
	end
end

--- Finds the exp_obstacle_course_start entity for a given course ID and
--- checks its door target to find the door entity.
--- Returns the door entity if found, or nil if not.
--- @param courseID string The ID of the obstacle course.
--- @return Entity? # The door entity or nil if not found.
function PLUGIN:FindDoorForCourse(courseID)
	local startEntity = ents.FindByClass("exp_obstacle_course_start")

	for _, ent in ipairs(startEntity) do
		if (ent:GetCourseID() == courseID and ent:GetDoorTarget() ~= "") then
			return ents.FindByName(ent:GetDoorTarget())[1]
		end
	end

	return nil
end

function PLUGIN:OpenObstacleDoor(courseID)
	local door = self:FindDoorForCourse(courseID)

	if (not IsValid(door)) then
		return ix.util.SchemaError("Obstacle course door not found for course ID: " .. courseID)
	end

	door:Fire("Unlock")
	door:Fire("Close") -- I know it's reversed, but its so lighting on the door isnt baked in messed up
	door:Fire("Lock")
end

function PLUGIN:CloseObstacleDoor(courseID)
	local door = self:FindDoorForCourse(courseID)

	if (not IsValid(door)) then
		return ix.util.SchemaError("Obstacle course door not found for course ID: " .. courseID)
	end

	door:Fire("Unlock")
	door:Fire("Open") -- Intentionally reversed, see above.
	door:Fire("Lock")
end

function PLUGIN:StartGracePeriod(courseID)
	local courseData = self.obstacleCourses[courseID]

	if (courseData.graceTimer) then
		timer.Remove(courseData.graceTimer)
	end

	local timerName = "expObstacleCourseGrace_" .. courseID
	courseData.graceTimer = timerName

	timer.Create(timerName, QUEUE_PERIOD_SECONDS, 1, function()
		if (not self.obstacleCourses[courseID]) then
			return
		end

		-- Check if we still have enough waiting players
		local validWaitingPlayers = {}
		for client, _ in pairs(courseData.waitingPlayers) do
			if (IsValid(client)) then
				validWaitingPlayers[#validWaitingPlayers + 1] = client
			end
		end

		if (#validWaitingPlayers >= MIN_PLAYERS and self:IsObstacleCourseEmpty(courseID)) then
			self:OpenObstacleDoor(courseID)
			courseData.isDoorOpen = true

			self:NetworkCourseUpdate(courseID)

			-- Notify waiting players
			for _, client in ipairs(validWaitingPlayers) do
				client:Notify("The obstacle course door is now open! You have " ..
					DOOR_OPEN_DURATION_SECONDS .. " seconds to enter.")
			end

			-- Start door close timer
			local doorTimerName = "expObstacleCourseDoor_" .. courseID
			courseData.doorTimer = doorTimerName

			timer.Create(doorTimerName, DOOR_OPEN_DURATION_SECONDS, 1, function()
				if (not self.obstacleCourses[courseID]) then
					return
				end

				self:CloseObstacleDoor(courseID)

				-- Disqualify any waiting players who didn't enter, note that they can still slip under the door so we wait a bit
				timer.Simple(DOOR_CLOSE_DURATION_SECONDS, function()
					if (not self.obstacleCourses[courseID]) then
						return
					end

					-- Disqualify all waiting players who didn't enter
					local courseData = self.obstacleCourses[courseID]

					for client, _ in pairs(courseData.waitingPlayers) do
						if (IsValid(client)) then
							PLUGIN:DisqualifyPlayer(client, courseID, "Did not enter before door closed")
						end
					end
				end)

				courseData.isDoorOpen = false
				courseData.doorTimer = nil

				self:NetworkCourseUpdate(courseID)
			end)
		end

		courseData.graceTimer = nil
	end)
end

function PLUGIN:AddPlayerToWaiting(client, courseID)
	self:InitializeObstacleCourse(courseID)
	local courseData = self.obstacleCourses[courseID]

	courseData.waitingPlayers[client] = {
		joinedAt = CurTime(),
	}
	client.expObstacleCoursePvsEntities = ents.FindByClass("exp_obstacle_course_camera")

	self:NetworkCourseUpdate(courseID)

	-- Check if we should start grace period
	local waitingCount = table.Count(courseData.waitingPlayers)

	if (waitingCount >= MIN_PLAYERS and self:IsObstacleCourseEmpty(courseID) and not courseData.graceTimer) then
		self:StartGracePeriod(courseID)

		-- Notify all waiting players
		for waitingClient, _ in pairs(courseData.waitingPlayers) do
			if (IsValid(waitingClient)) then
				waitingClient:Notify("Obstacle course will open in " .. QUEUE_PERIOD_SECONDS .. " seconds...")
			end
		end
	end
end

function PLUGIN:RemovePlayerFromWaiting(client, courseID)
	if (not self.obstacleCourses[courseID]) then
		return
	end

	local courseData = self.obstacleCourses[courseID]
	courseData.waitingPlayers[client] = nil
	client.expObstacleCoursePvsEntities = nil

	self:NetworkCourseUpdate(courseID)

	-- Cancel grace period if not enough players
	local waitingCount = table.Count(courseData.waitingPlayers)

	if (waitingCount < MIN_PLAYERS and courseData.graceTimer) then
		timer.Remove(courseData.graceTimer)
		courseData.graceTimer = nil

		-- Notify remaining players
		for waitingClient, _ in pairs(courseData.waitingPlayers) do
			if (IsValid(waitingClient)) then
				waitingClient:Notify("Not enough players for obstacle course. Waiting for more...")
			end
		end
	end
end

function PLUGIN:StartPlayerOnCourse(client, courseID)
	self:InitializeObstacleCourse(courseID)
	local courseData = self.obstacleCourses[courseID]

	-- Remove from waiting and add to active
	courseData.waitingPlayers[client] = nil
	courseData.activePlayers[client] = {
		startedAt = CurTime(),
	}
	client.expObstacleCoursePvsEntities = nil -- Clear PVS entities since they are now active

	courseData.isActive = true

	self:NetworkCourseUpdate(courseID)
end

function PLUGIN:FinishPlayerOnCourse(client, courseID)
	if (not self.obstacleCourses[courseID]) then
		return
	end

	local courseData = self.obstacleCourses[courseID]
	local playerData = courseData.activePlayers[client]

	if (not playerData) then
		return -- Player wasn't active on this course
	end

	-- Calculate finish time
	local finishTime = CurTime() - playerData.startedAt
	local position = #courseData.finishedPlayers + 1

	-- Add to finished players
	courseData.finishedPlayers[#courseData.finishedPlayers + 1] = {
		client = client,
		position = position,
		finishTime = finishTime,
		finishedAt = CurTime(),
	}

	courseData.activePlayers[client] = nil

	self:NetworkCourseUpdate(courseID)

	-- Notify player of their performance
	local timeString = string.NiceTime(math.ceil(finishTime))
	client:Notify("You finished in position #" .. position .. " with a time of " .. timeString .. "!")

	-- Update attributes
	-- TODO: Balance this
	local character = client:GetCharacter()

	if (character) then
		for attribute, rewardFunc in pairs(ATTRIBUTE_REWARDS) do
			local totalPlayers = #courseData.finishedPlayers + #courseData.activePlayers
			local reward = rewardFunc(position, totalPlayers)
			character:UpdateAttrib(attribute, reward)

			client:Notify(
				"You gained " .. math.Round(reward, 2) .. " " .. attribute
				.. " for finishing the course in position #" .. position .. "/" .. totalPlayers .. "!"
			)
		end
	end

	if (self:IsObstacleCourseEmpty(courseID)) then
		courseData.isActive = false
	end
end

function PLUGIN:DisqualifyPlayer(client, courseID, reason)
	if (not self.obstacleCourses[courseID]) then
		return
	end

	local courseData = self.obstacleCourses[courseID]

	-- Remove from all lists
	courseData.waitingPlayers[client] = nil
	courseData.activePlayers[client] = nil

	client.expObstacleCoursePvsEntities = nil -- Clear PVS entities

	self:NetworkCourseUpdate(courseID)

	client:Notify("You have been disqualified from the obstacle course: " .. (reason or "Unknown reason"))

	-- Check if course is now empty
	if (self:IsObstacleCourseEmpty(courseID)) then
		courseData.isActive = false
	end
end

function PLUGIN:CleanupObstacleCourse(courseID)
	if (not self.obstacleCourses[courseID]) then
		return
	end

	local courseData = self.obstacleCourses[courseID]

	-- Clean up timers
	if (courseData.graceTimer) then
		timer.Remove(courseData.graceTimer)
	end

	if (courseData.doorTimer) then
		timer.Remove(courseData.doorTimer)
	end

	-- Reset course data
	courseData.waitingPlayers = {}
	courseData.activePlayers = {}
	courseData.finishedPlayers = {}
	courseData.graceTimer = nil
	courseData.doorTimer = nil
	courseData.isDoorOpen = false
	courseData.isActive = false

	self:NetworkCourseUpdate(courseID)

	self:CloseObstacleDoor(courseID)
end

--- Finds which course a player is participating in
function PLUGIN:FindPlayerCourse(client)
	for courseID, courseData in pairs(self.obstacleCourses) do
		if (courseData.waitingPlayers[client] or courseData.activePlayers[client]) then
			return courseID
		end
	end

	return nil
end

--- Handle player death - disqualify from obstacle course
function PLUGIN:PlayerDeath(client, inflictor, attacker)
	local courseID = self:FindPlayerCourse(client)

	if (courseID) then
		self:DisqualifyPlayer(client, courseID, "Died during the course")
	end
end

function PLUGIN:PlayerDisconnected(client)
	-- Remove from all obstacle courses
	for courseID, courseData in pairs(self.obstacleCourses) do
		local wasInCourse = courseData.waitingPlayers[client] or courseData.activePlayers[client]

		courseData.waitingPlayers[client] = nil
		courseData.activePlayers[client] = nil

		-- Remove from finished players list
		for i = #courseData.finishedPlayers, 1, -1 do
			if (courseData.finishedPlayers[i].client == client) then
				table.remove(courseData.finishedPlayers, i)
			end
		end

		-- Network update if player was involved
		if wasInCourse then
			self:NetworkCourseUpdate(courseID)
		end
	end
end

function PLUGIN:SetupPlayerVisibility(client, viewEntity)
	-- Add all cameras for the courses the player is waiting for to PVS, such that they can see
	-- everything the camera sees (like moving obstacles).
	if (not client.expObstacleCoursePvsEntities) then
		return
	end

	for _, ent in ipairs(client.expObstacleCoursePvsEntities) do
		if (IsValid(ent)) then
			AddOriginToPVS(ent:GetPos())
		end
	end
end
