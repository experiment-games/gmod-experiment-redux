--[[
	Chunk Player Proxy Entity

	This entity acts as an invisible collision proxy for players in neighboring chunks,
	allowing damage to be properly forwarded for cross-chunk combat.
]]

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Category = "Chunk System"
ENT.PrintName = "Chunk Player Proxy"
ENT.Spawnable = false
ENT.AdminOnly = true

if (SERVER) then
	AddCSLuaFile()

	--- Initialize the proxy entity
	function ENT:Initialize()
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_BBOX)
		self:SetCollisionGroup(COLLISION_GROUP_PLAYER)

		-- Make invisible to clients but keep collision
		self:SetNotSolid(false)

		-- Prevent normal interactions
		self:SetUseType(SIMPLE_USE)

		-- Mark as proxy for identification
		self.IsChunkPlayerProxy = true
		self.ProxiedPlayer = nil
		self.ChunkOffset = Vector(0, 0, 0)
	end

	--- Sets the player this proxy represents
	--- @param client Player The player to proxy
	--- @param chunkOffset Vector The offset from the player's actual position
	function ENT:SetProxiedPlayer(client, chunkOffset)
		if (not IsValid(client) or not client:IsPlayer()) then
			self:Remove()
			return
		end

		self.ProxiedPlayer = client
		self.ChunkOffset = chunkOffset or Vector(0, 0, 0)

		-- Set up initial model and bounds
		self:SetModel(client:GetModel())

		-- Copy player's collision bounds
		local mins, maxs = client:GetCollisionBounds()
		self:SetCollisionBounds(mins, maxs)

		-- Initial position sync
		self:SyncWithPlayer()

		-- Set up bodygroups and submodels
		self:SyncPlayerAppearance()
	end

	--- Sets the chunk coordinates this proxy is associated with for debugging purposes
	--- @param chunkX number The X coordinate of the chunk
	--- @param chunkY number The Y coordinate of the chunk
	function ENT:SetChunkCoordinates(chunkX, chunkY)
		self:SetNWInt("ChunkX", chunkX)
		self:SetNWInt("ChunkY", chunkY)
	end

	--- Gets the player this proxy represents
	--- @return Player? The proxied player
	function ENT:GetProxiedPlayer()
		return self.ProxiedPlayer
	end

	--- Synchronizes proxy position and angles with the real player
	function ENT:SyncWithPlayer()
		local client = self.ProxiedPlayer
		if (not IsValid(client)) then
			self:Remove()
			return
		end

		-- Calculate proxy position based on player position + chunk offset
		local playerPos = client:GetPos()
		local proxyPos = playerPos + self.ChunkOffset

		self:SetPos(proxyPos)
		self:SetAngles(client:GetAngles())

		-- Sync velocity for prediction
		self:SetVelocity(client:GetVelocity())
	end

	--- Synchronizes visual appearance with the real player
	function ENT:SyncPlayerAppearance()
		local client = self.ProxiedPlayer
		if (not IsValid(client)) then
			return
		end

		-- Sync model if changed
		if (self:GetModel() ~= client:GetModel()) then
			self:SetModel(client:GetModel())
		end

		-- Sync bodygroups
		for i = 0, client:GetNumBodyGroups() - 1 do
			self:SetBodygroup(i, client:GetBodygroup(i))
		end

		-- Sync submodels/skin
		self:SetSkin(client:GetSkin())

		-- Sync material if player has custom material for proper trace material hits
		local playerMaterial = client:GetMaterial()
		if (playerMaterial and playerMaterial ~= "") then
			self:SetMaterial(playerMaterial)
		end

		local mins, maxs = client:GetCollisionBounds()
		self:SetCollisionBounds(mins, maxs)
	end

	--- Synchronizes animation state with the real player
	function ENT:SyncPlayerAnimation()
		local client = self.ProxiedPlayer
		if (not IsValid(client)) then
			return
		end

		-- Get player's current sequence
		local sequence = client:GetSequence()
		if (self:GetSequence() ~= sequence) then
			self:SetSequence(sequence)
			self:SetCycle(client:GetCycle())
		else
			-- Update cycle for current animation
			self:SetCycle(client:GetCycle())
		end

		-- Sync pose parameters for accurate hitboxes
		for i = 0, client:GetNumPoseParameters() - 1 do
			local paramName = client:GetPoseParameterName(i)
			if (paramName) then
				local value = client:GetPoseParameter(paramName)
				self:SetPoseParameter(paramName, value)
			end
		end

		-- Sync playback rate
		self:SetPlaybackRate(client:GetPlaybackRate())
	end

	--- Think function to keep proxy synchronized
	function ENT:Think()
		if (not IsValid(self.ProxiedPlayer)) then
			self:Remove()
			return
		end

		self:SyncWithPlayer()
		self:SyncPlayerAppearance()
		self:SyncPlayerAnimation()

		self:NextThink(CurTime())
		return true
	end

	--- Handle damage taken by the proxy
	--- @param dmgInfo CTakeDamageInfo
	function ENT:OnTakeDamage(dmgInfo)
		local client = self.ProxiedPlayer
		if (not IsValid(client)) then
			return
		end

		local attacker = dmgInfo:GetAttacker()
		if (not IsValid(attacker) or not attacker:IsPlayer()) then
			return
		end

		-- Verify this is cross-chunk damage that should be allowed
		local attackerChunk = Schema.chunk.GetPlayerChunk(attacker)
		local targetChunk = Schema.chunk.GetPlayerChunk(client)

		if (not Schema.chunk.IsNeighboringChunk(attackerChunk, targetChunk)) then
			return -- Block damage if not from neighboring chunk
		end

		-- Create new damage info for the real player
		local newDmgInfo = DamageInfo()
		newDmgInfo:SetDamage(dmgInfo:GetDamage())
		newDmgInfo:SetDamageType(dmgInfo:GetDamageType())
		newDmgInfo:SetAttacker(dmgInfo:GetAttacker())
		newDmgInfo:SetInflictor(dmgInfo:GetInflictor())

		-- Calculate hit position relative to real player
		local hitPos = dmgInfo:GetDamagePosition()
		if (hitPos and hitPos ~= Vector(0, 0, 0)) then
			-- Adjust hit position back to real player's coordinate space
			local adjustedHitPos = hitPos - self.ChunkOffset
			newDmgInfo:SetDamagePosition(adjustedHitPos)
		end

		-- Copy damage force and direction
		newDmgInfo:SetDamageForce(dmgInfo:GetDamageForce())

		-- Forward damage to real player
		client:TakeDamageInfo(newDmgInfo)

		-- Call hook for external systems
		hook.Run("ChunkProxyDamageForwarded", self, client, attacker, dmgInfo, newDmgInfo)
	end

	--- Clean up when removed
	function ENT:OnRemove()
		-- Notify chunk system that proxy was removed
		if (IsValid(self.ProxiedPlayer)) then
			hook.Run("ChunkPlayerProxyRemoved", self.ProxiedPlayer, self)
		end
	end

	--- Override physics collision to prevent interference
	function ENT:PhysicsCollide(data, phys)
		-- Do nothing - we only want damage collision
	end

	--- Override use to prevent interaction
	function ENT:Use(activator, caller)
		-- Do nothing - proxies should not be usable
	end
end

if (CLIENT) then
	--- Client should never see these entities
	function ENT:Draw()
		-- Never draw on client unless debugging in developer mode
		if (GetConVar("developer"):GetInt() > 0) then
			local collisionMins, collisionMaxs = self:GetCollisionBounds()
			debugoverlay.Box(self:GetPos(), collisionMins, collisionMaxs, 0, Color(255, 0, 0, 100))

			local chunkX = self:GetNWInt("ChunkX", 0)
			local chunkY = self:GetNWInt("ChunkY", 0)
			local text = string.format("Chunk Proxy (%d, %d)", chunkX, chunkY)

			debugoverlay.Text(self:GetPos() + Vector(0, 0, 80), text, 0, Color(255, 255, 255), true)
		end
	end

	function ENT:DrawTranslucent()
		-- Never draw on client
	end
end
