util.AddNetworkString("AllianceRankSet")
util.AddNetworkString("AllianceMemberLeft")

local META = FindMetaTable("Player")

function META:SetAllianceRank(rank)
	local character = self:GetCharacter()
	local alliance = character:GetData("alliance")
	character:SetData("rank", rank)

	net.Start("AllianceRankSet")
	net.WriteUInt(character:GetID(), 32)
	net.WriteString(character:GetName())
	net.WriteUInt(rank, 8)
	net.Send(Schema.alliance.GetOnlineMembers(alliance.id))
end

function META:SetAlliance(alliance)
	local isValidAlliance = type(alliance) == "table" and alliance.id ~= nil and alliance.name ~= nil

	if (alliance ~= nil and not isValidAlliance) then
		PrintTable(alliance)
		error("Alliance must be a table with an `id` and `name` property.")
	end

	local character = self:GetCharacter()
	local oldAlliance = character:GetData("alliance")

	if (oldAlliance ~= nil) then
		net.Start("AllianceMemberLeft")
		net.WriteUInt(character:GetID(), 32)
		net.WriteString(character:GetName())
		net.WriteBool(false)
		net.Send(Schema.alliance.GetOnlineMembers(oldAlliance.id))
	end

	character:SetData("alliance", alliance)
end

function META:GetAlliance()
	local character = self:GetCharacter()

	if (not character) then
		return
	end

	local alliance = character:GetData("alliance")

	return alliance
end

function META:QueueBoostRemove(boostID, attribID, delay)
	local character = self:GetCharacter()

	if (not character) then
		return
	end

	local boostsToRemove = character:GetVar("boostsToRemove", {})

	boostsToRemove[boostID] = boostsToRemove[boostID] or {}
	boostsToRemove[boostID][attribID] = CurTime() + delay

	character:SetVar("boostsToRemove", boostsToRemove)
end

function META:CheckQueuedBoostRemovals(character)
	local boostsToRemove = character:GetVar("boostsToRemove", {})
	local curTime = CurTime()

	for boostID, attributes in pairs(boostsToRemove) do
		for attribID, removeTime in pairs(attributes) do
			if (curTime >= removeTime) then
				character:RemoveBoost(boostID, attribID)
				boostsToRemove[boostID][attribID] = nil
			end
		end
	end

	character:SetVar("boostsToRemove", boostsToRemove)
end

function META:RegisterEntityToRemoveOnLeave(entity)
	local character = self:GetCharacter()
	local characterEntities = character:GetVar("charEnts") or {}
	table.insert(characterEntities, entity)
	character:SetVar("charEnts", characterEntities, true)
end

--- Performs a time-delay action that requires this player to stand still.
--- @param callback function The function to call after the delay
--- @param delay number The delay in seconds
--- @param onCancel function The function to call if the player moves before the delay is up
function META:DoStandStillAction(callback, delay, onCancel)
	local uniqueID = "expStandStill" .. self:SteamID64()
	local startPos = self:GetPos()
	local moveMargin = 4

	timer.Create(uniqueID, 0.1, delay / 0.1, function()
		local currentPos = self:GetPos()

		if (IsValid(self) and startPos:DistToSqr(currentPos) < moveMargin) then
			if (callback and timer.RepsLeft(uniqueID) == 0) then
				callback()
			end
		else
			timer.Remove(uniqueID)

			if (onCancel) then
				onCancel()
			end
		end
	end)
end

-- ! WORKAROUND: This fixes a bug where Helix tries to SaveData for bots
-- ! Since bots never have LoadData called, ixData wont be set. Since we dont want to save data for bots, we just return
META.expSaveData = META.expSaveData or META.SaveData

function META:SaveData()
	if (self:IsBot()) then
		return
	end

	self:expSaveData()
end

-- ! This overrides Helix's SetRagdolled to call the OnCharacterFallover hook also when getting up after the time expires
-- ! helix/gamemode/core/meta/sh_player.lua is the original file this is based on
--- Sets this player's ragdoll status.
-- @realm server
-- @bool bState Whether or not to ragdoll this player
-- @number[opt=0] time How long this player should stay ragdolled for. Set to `0` if they should stay ragdolled until they
-- get back up manually
-- @number[opt=5] getUpGrace How much time in seconds to wait before the player is able to get back up manually. Set to
-- the same number as `time` to disable getting up manually entirely
function META:SetRagdolled(bState, time, getUpGrace)
	if (! self:Alive()) then
		return
	end

	getUpGrace = getUpGrace or time or 5

	if (bState) then
		if (IsValid(self.ixRagdoll)) then
			self.ixRagdoll:Remove()
		end

		local entity = self:CreateServerRagdoll()

		entity:CallOnRemove("fixer", function()
			if (not IsValid(self)) then
				return
			end

			self:SetLocalVar("blur", nil)
			self:SetLocalVar("ragdoll", nil)

			if (! entity.ixNoReset) then
				self:SetPos(entity:GetPos())
			end

			self:SetNoDraw(false)
			self:SetNotSolid(false)
			self:SetMoveType(MOVETYPE_WALK)
			self:SetLocalVelocity(IsValid(entity) and entity.ixLastVelocity or vector_origin)

			hook.Run("OnCharacterFallover", self, nil, false)

			if (not entity.ixIgnoreDelete) then
				if (entity.ixWeapons) then
					for _, v in ipairs(entity.ixWeapons) do
						if (v.class) then
							local weapon = self:Give(v.class, true)

							if (v.item) then
								weapon.ixItem = v.item
							end

							self:SetAmmo(v.ammo, weapon:GetPrimaryAmmoType())
							weapon:SetClip1(v.clip)
						elseif (v.item and v.invID == v.item.invID) then
							v.item:Equip(self, true, true)
							self:SetAmmo(v.ammo, self.carryWeapons[v.item.weaponCategory]:GetPrimaryAmmoType())
						end
					end
				end

				if (entity.ixActiveWeapon) then
					if (self:HasWeapon(entity.ixActiveWeapon)) then
						self:SetActiveWeapon(self:GetWeapon(entity.ixActiveWeapon))
					else
						local weapons = self:GetWeapons()
						if (#weapons > 0) then
							self:SetActiveWeapon(weapons[1])
						end
					end
				end

				if (self:IsStuck()) then
					entity:DropToFloor()
					self:SetPos(entity:GetPos() + Vector(0, 0, 16))

					local positions = ix.util.FindEmptySpace(self, { entity, self })

					for _, v in ipairs(positions) do
						self:SetPos(v)

						if (! self:IsStuck()) then
							return
						end
					end
				end
			end
		end)

		self:SetLocalVar("blur", 25)
		self.ixRagdoll = entity

		entity.ixWeapons = {}
		entity.ixPlayer = self

		if (getUpGrace) then
			entity.ixGrace = CurTime() + getUpGrace
		end

		if (time and time > 0) then
			entity.ixStart = CurTime()
			entity.ixFinish = entity.ixStart + time

			self:SetAction("@wakingUp", nil, nil, entity.ixStart, entity.ixFinish)
		end

		if (IsValid(self:GetActiveWeapon())) then
			entity.ixActiveWeapon = self:GetActiveWeapon():GetClass()
		end

		for _, v in ipairs(self:GetWeapons()) do
			if (v.ixItem and v.ixItem.Equip and v.ixItem.Unequip) then
				entity.ixWeapons[#entity.ixWeapons + 1] = {
					item = v.ixItem,
					invID = v.ixItem.invID,
					ammo = self:GetAmmoCount(v:GetPrimaryAmmoType())
				}
				v.ixItem:Unequip(self, false)
			else
				local clip = v:Clip1()
				local reserve = self:GetAmmoCount(v:GetPrimaryAmmoType())
				entity.ixWeapons[#entity.ixWeapons + 1] = {
					class = v:GetClass(),
					item = v.ixItem,
					clip = clip,
					ammo = reserve
				}
			end
		end

		self:GodDisable()
		self:StripWeapons()
		self:SetMoveType(MOVETYPE_OBSERVER)
		self:SetNoDraw(true)
		self:SetNotSolid(true)

		local uniqueID = "ixUnRagdoll" .. self:SteamID()

		if (time) then
			timer.Create(uniqueID, 0.33, 0, function()
				if (IsValid(entity) and IsValid(self) and self.ixRagdoll == entity) then
					local velocity = entity:GetVelocity()
					entity.ixLastVelocity = velocity

					self:SetPos(entity:GetPos())

					if (velocity:Length2D() >= 8) then
						if (! entity.ixPausing) then
							self:SetAction()
							entity.ixPausing = true
						end

						return
					elseif (entity.ixPausing) then
						self:SetAction("@wakingUp", time)
						entity.ixPausing = false
					end

					time = time - 0.33

					if (time <= 0) then
						entity:Remove()
					end
				else
					timer.Remove(uniqueID)
				end
			end)
		else
			timer.Create(uniqueID, 0.33, 0, function()
				if (IsValid(entity) and IsValid(self) and self.ixRagdoll == entity) then
					self:SetPos(entity:GetPos())
				else
					timer.Remove(uniqueID)
				end
			end)
		end

		self:SetLocalVar("ragdoll", entity:EntIndex())
		hook.Run("OnCharacterFallover", self, entity, true)
	elseif (IsValid(self.ixRagdoll)) then
		self.ixRagdoll:Remove()
	end
end

-- ! This overrides Helix's CreateServerRagdoll to check whether the bones should be copied over
-- ! helix/gamemode/core/meta/sh_player.lua is the original file this is based on
--- Creates a ragdoll entity of this player that will be synced with clients. This does **not** affect the player like
-- `SetRagdolled` does.
-- @realm server
-- @bool[opt=false] bDontSetPlayer Whether or not to avoid setting the ragdoll's owning player
-- @treturn entity Created ragdoll entity
function META:CreateServerRagdoll(bDontSetPlayer)
	local entity = ents.Create("prop_ragdoll")
	entity:SetPos(self:GetPos())
	entity:SetAngles(self:EyeAngles())
	entity:SetModel(self:GetModel())
	entity:SetSkin(self:GetSkin())

	for i = 0, (self:GetNumBodyGroups() - 1) do
		entity:SetBodygroup(i, self:GetBodygroup(i))
	end

	entity:Spawn()

	if (! bDontSetPlayer) then
		entity:SetNetVar("player", self)
	end

	entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	entity:Activate()

	local velocity = self:GetVelocity()

	for i = 0, entity:GetPhysicsObjectCount() - 1 do
		local physObj = entity:GetPhysicsObjectNum(i)

		if (IsValid(physObj)) then
			physObj:SetVelocity(velocity)

			local index = entity:TranslatePhysBoneToBone(i)

			if (index and (not self.expIgnoreBoneManipulation or not self.expIgnoreBoneManipulation[index])) then
				local position, angles = self:GetBonePosition(index)

				physObj:SetPos(position)
				physObj:SetAngles(angles)
			end
		end
	end

	return entity
end

-- ! This overrides Helix's GetItemDropPos so it also ignores the player's active weapon
--- Returns a good position in front of the player for an entity to be placed. This is usually used for item entities.
-- @realm shared
-- @entity entity Entity to get a position for
-- @treturn vector Best guess for a good drop position in front of the player
-- @usage local position = client:GetItemDropPos(entity)
-- entity:SetPos(position)
function META:GetItemDropPos(entity)
	local data = {}
	local trace

	data.start = self:GetShootPos()
	data.endpos = self:GetShootPos() + self:GetAimVector() * 86
	data.filter = self

	if (IsValid(entity)) then
		-- use a hull trace if there's a valid entity to avoid collisions
		local mins, maxs = entity:GetRotatedAABB(entity:OBBMins(), entity:OBBMaxs())

		data.mins = mins
		data.maxs = maxs
		data.filter = function(ent)
			if (ent == self or ent == entity or (ent:IsWeapon() and not IsValid(ent:GetOwner()))) then
				return false
			end

			return true
		end

		trace = util.TraceHull(data)
	else
		-- trace along the normal for a few units so we can attempt to avoid a collision
		trace = util.TraceLine(data)

		data.start = trace.HitPos
		data.endpos = data.start + trace.HitNormal * 48
		trace = util.TraceLine(data)
	end

	return trace.HitPos
end

-- ! This overrides Helix's SetWepRaised so it also calls 'PlayerChangedWeaponRaised'
--- Sets whether or not this player's current weapon is raised.
-- @realm server
-- @bool bState Whether or not the raise the weapon
-- @entity[opt=GetActiveWeapon()] weapon Weapon to raise or lower. You should pass this argument if you already have a
-- reference to this player's current weapon to avoid an expensive lookup for this player's current weapon.
function META:SetWepRaised(bState, weapon)
	weapon = weapon or self:GetActiveWeapon()

	if (IsValid(weapon)) then
		local bCanShoot = ! bState and weapon.FireWhenLowered or bState
		self:SetNetVar("raised", bState)

		if (bCanShoot) then
			-- delay shooting while the raise animation is playing
			timer.Create("ixWeaponRaise" .. self:SteamID64(), 1, 1, function()
				if (IsValid(self)) then
					self:SetNetVar("canShoot", true)
				end
			end)
		else
			timer.Remove("ixWeaponRaise" .. self:SteamID64())
			self:SetNetVar("canShoot", false)
		end
	else
		timer.Remove("ixWeaponRaise" .. self:SteamID64())
		self:SetNetVar("raised", false)
		self:SetNetVar("canShoot", false)
	end

	hook.Run("PlayerChangedWeaponRaised", self, weapon, bState)
end
