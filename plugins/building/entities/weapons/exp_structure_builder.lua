local PLUGIN = PLUGIN

if (SERVER) then
	AddCSLuaFile()
end

DEFINE_BASECLASS("exp_base_holder")

SWEP.Base = "exp_base_holder"
SWEP.PrintName = "Blueprint Builder"
SWEP.Instructions = "{+attack}: Build.\n{+attack2}: Rotate (Hold {+speed}-button to snap)."
SWEP.Purpose = "Construct structures."

SWEP.HoldingModel = "models/props_lab/clipboard.mdl"
SWEP.HoldingAttachmentBone = "ValveBiped.Bip01_R_Hand"
SWEP.HoldingAttachmentOffset = Vector(4.5, 1.5, -1.5)
SWEP.HoldingAttachmentAngle = Angle(90, -45, 90)
SWEP.HoldingAttachmentScale = 0.6

local wireframeMaterial = Material("models/wireframe")

hook.Add("InputMouseApply", "expStructureBuilderHandleInput", function(userCommand, x, y, angle)
	local client = LocalPlayer()
	local weapon = client:GetActiveWeapon()

	if (not IsValid(weapon) or weapon:GetClass() ~= "exp_structure_builder") then
		return
	end

	local isSpeedDown = client:KeyDown(IN_SPEED)

	if (weapon.expRotation and client:KeyDown(IN_ATTACK2)) then
		userCommand:SetMouseX(0)
		userCommand:SetMouseY(0)

		local rotateY = x * FrameTime() * 10
		local rotateP = y * FrameTime() * 10

		weapon.expRotationUnboundedY = (weapon.expRotationUnboundedY or weapon.expRotation.y) + rotateY
		weapon.expRotationUnboundedP = (weapon.expRotationUnboundedP or weapon.expRotation.p) + rotateP

		weapon.expRotation.y = weapon.expRotation.y + rotateY
		weapon.expRotation.p = weapon.expRotation.p + rotateP

		if (isSpeedDown) then
			local snapAngleDegrees = 45

			weapon.expRotation.y = math.Round(weapon.expRotationUnboundedY / snapAngleDegrees) * snapAngleDegrees
			weapon.expRotation.p = math.Round(weapon.expRotationUnboundedP / snapAngleDegrees) * snapAngleDegrees
		end

		return true
	end

	-- if (client:KeyDown(IN_USE)) then
	-- 	userCommand:SetMouseX(0)
	-- 	userCommand:SetMouseY(0)

	-- 	local moveZ = -y * FrameTime() * 10
	--     local moveX = x * FrameTime() * 10

	-- 	weapon.expPositionOffset = weapon.expPositionOffset or Vector(0, 0, 0)

	--     weapon.expPositionOffset.z = math.Clamp(weapon.expPositionOffset.z + moveZ, -100, 100)
	--     weapon.expPositionOffset.x = math.Clamp(weapon.expPositionOffset.x + moveX, -100, 100)

	--     if (isSpeedDown) then
	-- 		weapon.expPositionSnap = 10
	-- 	end

	--     return true
	-- else
	-- 	weapon.expPositionSnap = nil
	-- end
end)

hook.Add("PostDrawOpaqueRenderables", "expStructureBuilderDrawStructure", function(depth, isDrawingSkybox)
	if (isDrawingSkybox) then
		return
	end

	local client = LocalPlayer()

	if (not IsValid(client)) then
		return
	end

	local weapon = client:GetActiveWeapon()

	if (not IsValid(weapon) or weapon:GetClass() ~= "exp_structure_builder") then
		return
	end

	if (not weapon.ixItem) then
		return
	end

	local position, angles = PLUGIN:GetPlacementTrace(client)
	local isPlacementValid, otherStructureOrError = PLUGIN:GetPlacementValid(client, position, angles)
	weapon.expRotation = weapon.expRotation or angles

	-- if (weapon.expPositionOffset) then
	-- 	local aim = client:EyeAngles()
	--     local offset =
	-- 		aim:Forward() * weapon.expPositionOffset.x
	-- 		-- + aim:Up() * weapon.expPositionOffset.z

	-- 	position = position + offset
	-- end

	if (weapon.ixItem.structureOffset) then
		position = position + weapon.ixItem.structureOffset
	end

	-- Draw all the structure parts, positioning them relative to the placement trace
	for _, structure in ipairs(weapon.expClientSideModels or {}) do
		local structurePosition, structureAngles = LocalToWorld(
			structure.part.position,
			structure.part.angles,
			position,
			weapon.expRotation)

		-- if (weapon.expPositionSnap) then
		-- 	structurePosition = Vector(
		-- 		math.Round(structurePosition.x / weapon.expPositionSnap) * weapon.expPositionSnap,
		-- 		math.Round(structurePosition.y / weapon.expPositionSnap) * weapon.expPositionSnap,
		-- 		math.Round(structurePosition.z / weapon.expPositionSnap) * weapon.expPositionSnap
		-- 	)
		-- end

		weapon.expLastStructurePosition = structurePosition
		weapon.expLastStructureAngles = structureAngles

		structure.entity:SetPos(weapon.expLastStructurePosition)
		structure.entity:SetAngles(weapon.expLastStructureAngles)

		local placeError = nil

		if (not isPlacementValid) then
			placeError = otherStructureOrError
		else
			local boundsMin, boundsMax = structure.entity:GetCollisionBounds()
			local cube = weapon.ixItem.GetBoundsCube
				and weapon.ixItem:GetBoundsCube(structure.entity, boundsMin, boundsMax)
				or Schema.util.ExpandBoundsToCube(
					boundsMin,
					boundsMax,
					structure.entity:GetPos(),
					structure.entity:GetAngles()
				)
			local canPlace = not Schema.util.TracePointsHit(cube, function(e)
				return not (e.IsStructure or e.IsStructurePart)
			end)

			if (not canPlace) then
				placeError = "You cannot build here."
			elseif (weapon.ixItem.OnCanBuild and not weapon.ixItem:OnCanBuild(client, position, angles)) then
				placeError = "You cannot build here."
			end
		end

		weapon.expLastCanPlaceError = placeError

		render.SuppressEngineLighting(true)
		render.MaterialOverride(wireframeMaterial)
		if (weapon.expLastCanPlaceError == nil) then
			render.SetColorModulation(1, 1, 1)
		else
			render.SetColorModulation(1, 0, 0)
		end
		structure.entity:DrawModel()
		render.MaterialOverride()
		render.SuppressEngineLighting(false)
	end
end)

function SWEP:SetItemTable(itemTable)
	self.expItemTable = itemTable

	self:SetNetVar("itemID", itemTable.uniqueID)
end

function SWEP:GetItemTable()
	if (SERVER) then
		return self.expItemTable
	end

	local itemID = self:GetNetVar("itemID")

	if (not itemID) then
		return
	end

	return ix.item.list[itemID]
end

function SWEP:BuildStructureIfNotExists(client, itemTable)
	if (not CLIENT) then
		return
	end

	if (self.expStructureBuilt) then
		return
	end

	local structure = itemTable:GetStructure(client)

	self.expClientSideModels = self.expClientSideModels or {}
	self.ixItem = itemTable

	for _, structurePart in ipairs(structure) do
		local structureEntity = ClientsideModel(structurePart.model, RENDERGROUP_OPAQUE)
		structureEntity:SetNoDraw(true)
		self.expClientSideModels[#self.expClientSideModels + 1] = {
			entity = structureEntity,
			part = structurePart
		}
		structureEntity:SetModel(structurePart.model)
		structureEntity:Spawn()
		structureEntity:Activate()
	end

	self.expStructureBuilt = true
end

function SWEP:Think()
	if (not CLIENT) then
		return
	end

	local itemTable = self:GetItemTable()

	if (not itemTable) then
		return
	end

	self:BuildStructureIfNotExists(client, itemTable)
end

function SWEP:OnRemove()
	BaseClass.OnRemove(self)

	if (CLIENT) then
		for _, structure in ipairs(self.expClientSideModels or {}) do
			structure.entity:Remove()
		end

		self.expClientSideModels = nil
	end
end

function SWEP:PrimaryAttack()
	if (SERVER) then
		return
	end

	if (self.expLastCanPlaceError) then
		if (Schema.util.Throttle("StructureBuildError", 2)) then
			return
		end

		self.Owner:Notify(self.expLastCanPlaceError)
		return
	end

	local position = self.expLastStructurePosition

	if (not position) then
		return
	end

	if (self.ixItem.structureOffset) then
		position = position - self.ixItem.structureOffset
	end

	PLUGIN:RequestBuildStructure(position, self.expLastStructureAngles)
end

function SWEP:SecondaryAttack()
	if (not SERVER) then
		return
	end
end
