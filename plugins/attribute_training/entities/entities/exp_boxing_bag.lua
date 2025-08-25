local PLUGIN = PLUGIN

AddCSLuaFile()
DEFINE_BASECLASS("base_gmodentity")

ENT.Type = "anim"
ENT.PrintName = "Boxing Bag"
ENT.Category = "Experiment Redux"
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar("String", "ItemID")
end

function ENT:GetItemTable()
	return ix.item.list[self:GetItemID()]
end

if (not SERVER) then
	function ENT:GetEntityMenu(client)
		local itemTable = self:GetItemTable()
		local options = {}

		if (not itemTable) then
			return false
		end

		itemTable.player = client
		itemTable.entity = self

		options[L("pickup")] = {
			callback = function() end,
			forceListEnd = true,
		}

		itemTable.player = nil
		itemTable.entity = nil

		return options
	end

	return
end

function ENT:Initialize()
	self:SetModel("models/experiment-redux/boxing_bag.mdl")

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)

	self:SetUseType(SIMPLE_USE)

	-- Get physics physics
	local physObj = self:GetPhysicsObject()
	if (IsValid(physObj)) then
		physObj:SetMass(50) -- Heavy bag
		physObj:Wake()
	end

	self:CreateBallsocket()
end

function ENT:SetupBoxingBag(owner, ceilingPos, item)
	self:SetItemID(item.uniqueID)

	self.expItemID = item.id
	self.expOwner = owner
	self.expCeilingPos = ceilingPos
end

function ENT:CreateBallsocket()
	local ceilingPos = self.expCeilingPos

	if (not ceilingPos or ceilingPos == Vector(0, 0, 0)) then
		return
	end

	-- Create an invisible anchor point at the ceiling
	local anchor = ents.Create("prop_physics")
	anchor:SetModel("models/hunter/plates/plate.mdl")
	anchor:SetMaterial("phoenix_storms/metalset_1-2")
	anchor:SetPos(ceilingPos)
	anchor:SetNoDraw(true)
	anchor:SetNotSolid(true)
	anchor:SetMoveType(MOVETYPE_NONE)
	anchor:Spawn()

	-- Get physics objects
	local anchorPhys = anchor:GetPhysicsObject()
	local bagPhys = self:GetPhysicsObject()

	if (IsValid(anchorPhys) and IsValid(bagPhys)) then
		anchorPhys:EnableMotion(false)

		-- Create ball socket constraint
		local constraint = constraint.Ballsocket(
			anchor,  -- Entity 1 (ceiling anchor)
			self,    -- Entity 2 (boxing bag)
			0,       -- Bone 1
			0,       -- Bone 2
			Vector(0, 0, 80), -- Local pos 1 (top of boxing bag)
			0,       -- Force limit (0 = no limit)
			0,       -- Torque limit (0 = no limit),
			0        -- No collision (0 = no collision between entities)
		)

		-- Store reference to anchor and constraint for cleanup
		self.CeilingAnchor = anchor
		self.BallsocketConstraint = constraint

		-- Remove anchor when bag is removed
		self:CallOnRemove("CleanupAnchor", function()
			if (IsValid(anchor)) then
				anchor:Remove()
			end
		end)
	end
end

function ENT:PhysicsUpdate(physObj)
	-- Add damping to make it swing more realistically
	local vel = physObj:GetVelocity()
	if (vel:LengthSqr() > 1) then
		physObj:SetVelocity(vel * 0.98) -- Slight damping
	end

	local angVel = physObj:GetAngleVelocity()
	if (angVel:LengthSqr() > 1) then
		physObj:SetAngleVelocity(angVel * 0.98) -- Slight angular damping
	end
end

function ENT:OnHitWithBoxingGloves(client, wasSpecialAttack)
	local character = client:GetCharacter()
	character:UpdateAttrib("strength", 0.01)
end

function ENT:OnOptionSelected(client, option, data)
	if (option == L("pickup", client)) then
		local character = client:GetCharacter()
		local inventory = character:GetInventory()
		local success, errorMessage = inventory:Add(self.expItemID)

		if (not success) then
			client:Notify(errorMessage or "Failed to pick up the boxing bag.")
			return
		end

		self:Remove()
	end
end
