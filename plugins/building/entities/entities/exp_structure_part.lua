local PLUGIN = PLUGIN

if (SERVER) then
	AddCSLuaFile()
end

ENT.Type = "anim"
ENT.PrintName = "Structure Part"
ENT.Category = "Experiment Redux"
ENT.IsStructurePart = true
ENT.IsStructureOrPart = true
ENT.PopulateEntityInfo = true
ENT.Spawnable = false
ENT.AdminOnly = true

function ENT:GetUnderConstruction()
	local parent = self:GetParent()

	if (IsValid(parent)) then
		return parent:GetUnderConstruction()
	end

	return false
end

function ENT:OnPopulateEntityInfo(tooltip)
	local parent = self:GetParent()

	if (IsValid(parent)) then
		parent:OnPopulateEntityInfo(tooltip)
	end
end

function ENT:GetEntityMenu(client)
	local parent = self:GetParent()

	if (IsValid(parent)) then
		return parent:GetEntityMenu(client)
	end
end

function ENT:GetGroundLevel()
	local parent = self:GetParent()

	if (IsValid(parent)) then
		return parent:GetGroundLevel()
	end

	return 0
end

if (SERVER) then
	function ENT:Initialize()
		self:SetMoveType(MOVETYPE_NONE)

		self:SetSolid(SOLID_BBOX)

		-- Start off with no collision, we'll be attached to the player until we're fully constructed
		self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end

	function ENT:OnTakeDamage(damageInfo)
		local parent = self:GetParent()

		if (IsValid(parent)) then
			parent:TakeDamage(damageInfo:GetDamage(), damageInfo:GetAttacker(), damageInfo:GetInflictor())
		end
	end

	function ENT:OnOptionSelected(client, option, data)
		local parent = self:GetParent()

		if (IsValid(parent)) then
			parent:OnOptionSelected(client, option, data)
		end
	end

	function ENT:Touch(entity)
		if (self.expIsTouched == nil) then
			return
		end

		-- Allow parts to only clip eachother
		if (entity.IsStructure or entity.IsStructurePart) then
			return
		end

		self.expIsTouched = true
	end

	function ENT:AcceptInput(inputName, activator, caller, data)
		local parent = self:GetParent()

		if (IsValid(parent)) then
			parent:AcceptInput(inputName, activator, caller, data)
		end
	end

	function ENT:OnRemove()
		local parent = self:GetParent()

		if (IsValid(parent)) then
			parent:Remove()
		end
	end
else
	function ENT:Draw()
		if (self:GetUnderConstruction()) then
			self:DrawModelOutline()
		else
			self:DrawModel()
		end
	end

	local wireframeMaterial = Material("models/wireframe")

	function ENT:DrawModelOutline()
		render.SuppressEngineLighting(true)
		render.MaterialOverride(wireframeMaterial)
		self:DrawModel()
		render.MaterialOverride()
		render.SuppressEngineLighting(false)
	end
end
