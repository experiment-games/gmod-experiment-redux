util.AddNetworkString("expDoorMenu")
util.AddNetworkString("expDoorPermission")
util.AddNetworkString("expDoorPickupProtector")

resource.AddFile("models/experiment-redux/door_protector_basic.mdl")
resource.AddFile("materials/models/experiment-redux/door-protectors/door_protector_basic.vmt")
resource.AddFile("materials/experiment-redux/electricity.png")

ix.log.AddType("lostdoor", function(client, ...)
	return Format("%s has lost a door.", client:Name())
end, FLAG_WARNING)

-- Variables for door data.
local variables = {
	-- Whether or not the door will be disabled.
	"disabled",
	-- The name of the door.
	"name",
	-- Price of the door.
	"price",
	-- If the door is ownable.
	"ownable",
	-- The faction that owns a door.
	"faction",
	-- The class that owns a door.
	"class",
	-- Whether or not the door will be hidden.
	"visible"
}

function PLUGIN:OnCharacterCreated(client, character)
	local inventory = character:GetInventory()
	inventory:Add("door_protector", 1)
end

function PLUGIN:EntityIsDoor(entity)
	if (entity:GetClass() == "exp_door_protector") then
		return false
	end
end

function PLUGIN:PlayerCanBreachEntity(client, entity)
	if (entity:GetClass() == "exp_door_protector") then
		return true
	end
end

function PLUGIN:CanPlayerShootOpen(client, entity)
	if (IsValid(entity.expProtector)) then
		return false
	end
end

function PLUGIN:CanPlayerHoldObject(client, entity)
	if (entity:GetClass() == "exp_door_protector") then
		return true
	end
end

function PLUGIN:CallOnDoorChildren(entity, callback)
	local parent

	if (entity.ixChildren) then
		parent = entity
	elseif (entity.ixParent) then
		parent = entity.ixParent
	end

	if (IsValid(parent)) then
		callback(parent)

		for k, _ in pairs(parent.ixChildren) do
			local child = ents.GetMapCreatedEntity(k)

			if (IsValid(child)) then
				callback(child)
			end
		end
	end
end

function PLUGIN:CopyParentDoor(child)
	local parent = child.ixParent

	if (IsValid(parent)) then
		for _, v in ipairs(variables) do
			local value = parent:GetNetVar(v)

			if (child:GetNetVar(v) ~= value) then
				child:SetNetVar(v, value)
			end
		end
	end
end

-- Called after the entities have loaded.
function PLUGIN:LoadData()
	-- Restore the saved door information.
	local data = self:GetData()

	if (not data) then
		return
	end

	-- Loop through all of the saved doors.
	for k, v in pairs(data) do
		-- Get the door entity from the saved ID.
		local entity = ents.GetMapCreatedEntity(k)

		-- Check it is a valid door in-case something went wrong.
		if (IsValid(entity) and entity:IsDoor()) then
			-- Loop through all of our door variables.
			for k2, v2 in pairs(v) do
				if (k2 == "children") then
					entity.ixChildren = v2

					for index, _ in pairs(v2) do
						local door = ents.GetMapCreatedEntity(index)

						if (IsValid(door)) then
							door.ixParent = entity
						end
					end
				elseif (k2 == "faction") then
					for k3, v3 in pairs(ix.faction.teams) do
						if (k3 == v2) then
							entity.ixFactionID = k3
							entity:SetNetVar("faction", v3.index)

							break
						end
					end
				else
					entity:SetNetVar(k2, v2)
				end
			end
		end
	end
end

-- Called before the gamemode shuts down.
function PLUGIN:SaveDoorData()
	-- Create an empty table to save information in.
	local data = {}
	local doors = {}

	for _, v in ipairs(ents.GetAll()) do
		if (v:IsDoor()) then
			doors[v:MapCreationID()] = v
		end
	end

	local doorData

	-- Loop through doors with information.
	for k, v in pairs(doors) do
		-- Another empty table for actual information regarding the door.
		doorData = {}

		-- Save all of the needed variables to the doorData table.
		for _, v2 in ipairs(variables) do
			local value = v:GetNetVar(v2)

			if (value) then
				doorData[v2] = v:GetNetVar(v2)
			end
		end

		if (v.ixChildren) then
			doorData.children = v.ixChildren
		end

		if (v.ixClassID) then
			doorData.class = v.ixClassID
		end

		if (v.ixFactionID) then
			doorData.faction = v.ixFactionID
		end

		-- Add the door to the door information.
		if (not table.IsEmpty(doorData)) then
			data[k] = doorData
		end
	end
	-- Save all of the door information.
	self:SetData(data)
end

function PLUGIN:CanPlayerUseDoor(client, entity)
	if (entity:GetNetVar("disabled")) then
		return false
	end
end

-- Whether or not a player a player has any abilities over the door, such as locking.
function PLUGIN:CanPlayerAccessDoor(client, door, access)
	local faction = door:GetNetVar("faction")

	-- If the door has a faction set which the client is a member of, allow access.
	if (faction and client:Team() == faction) then
		return true
	end

	local class = door:GetNetVar("class")

	-- If the door has a faction set which the client is a member of, allow access.
	local classData = ix.class.list[class]
	local charClass = client:GetCharacter():GetClass()
	local classData2 = ix.class.list[charClass]

	if (class and classData and classData2) then
		if (classData.team) then
			if (classData.team ~= classData2.team) then
				return false
			end
		else
			if (charClass ~= class) then
				return false
			end
		end

		return true
	end
end

function PLUGIN:PostPlayerLoadout(client)
	client:Give("exp_keys")
end

function PLUGIN:ShowTeam(client)
	local data = {}
	data.start = client:GetShootPos()
	data.endpos = data.start + client:GetAimVector() * 96
	data.filter = client
	local trace = util.TraceLine(data)
	local entity = trace.Entity

	if (IsValid(entity) and not entity:GetNetVar("faction") and not entity:GetNetVar("class")) then
		if (entity:CheckDoorAccess(client, DOOR_TENANT)) then
			local door = entity:GetDoor()

			if (not door) then
				return false
			end

			if (IsValid(door.ixParent)) then
				door = door.ixParent
			end

			net.Start("expDoorMenu")
			net.WriteEntity(door)
			net.WriteTable(door.ixAccess)
			net.WriteEntity(door)
			net.Send(client)
		elseif (entity:IsDoor()) then
			client:NotifyLocalized("notAllowed")
		end

		return true
	end
end

function PLUGIN:PlayerLoadedCharacter(client, curChar, prevChar)
	if (prevChar) then
		local doors = prevChar:GetVar("doors") or {}

		for _, door in ipairs(doors) do
			if (IsValid(door) and door:IsDoor() and door:GetDTEntity(0) == client) then
				door:RemoveDoorAccessData()
			end
		end

		prevChar:SetVar("doors", nil)
	end
end

function PLUGIN:PlayerDisconnected(client)
	local character = client:GetCharacter()

	if (character) then
		local doors = character:GetVar("doors") or {}

		for _, door in ipairs(doors) do
			if (IsValid(door) and door:IsDoor() and door:GetDTEntity(0) == client) then
				door:RemoveDoorAccessData()
			end
		end

		character:SetVar("doors", nil)
	end
end

net.Receive("expDoorPermission", function(length, client)
	local door = net.ReadEntity()
	local target = net.ReadEntity()
	local access = net.ReadUInt(4)

	if (IsValid(target) and target:GetCharacter() and door.ixAccess and door:GetDTEntity(0) == client and target ~= client) then
		access = math.Clamp(access or 0, DOOR_NONE, DOOR_TENANT)

		if (access == door.ixAccess[target]) then
			return
		end

		door.ixAccess[target] = access

		local recipient = {}

		for k, v in pairs(door.ixAccess) do
			if (v > DOOR_GUEST) then
				recipient[#recipient + 1] = k
			end
		end

		if (#recipient > 0) then
			net.Start("expDoorPermission")
			net.WriteEntity(door)
			net.WriteEntity(target)
			net.WriteUInt(access, 4)
			net.Send(recipient)
		end
	end
end)

net.Receive("expDoorPickupProtector", function(length, client)
	local door = net.ReadEntity()

	if (not IsValid(door) or not IsValid(door.expProtector) or door.expProtector.expClient ~= client) then
		client:NotifyLocalized("pickupProtectorNotAllowed")
		return
	end

	local inventory = client:GetCharacter():GetInventory()
	local success, error = inventory:Add(door.expProtector.expItemUniqueID)

	if (not success) then
		client:Notify(error)
		return
	end

	door.expProtector:Remove()
end)
