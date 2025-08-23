local PLUGIN = PLUGIN

ACCESS_LABELS = {}
ACCESS_LABELS[DOOR_OWNER] = "owner"
ACCESS_LABELS[DOOR_TENANT] = "tenant"
ACCESS_LABELS[DOOR_GUEST] = "guest"
ACCESS_LABELS[DOOR_NONE] = "none"

net.Receive("expDoorMenu", function(length)
	if (IsValid(ix.gui.door)) then
		return ix.gui.door:Remove()
	end

	if (length == 0) then
		return
	end

	local door = net.ReadEntity()
	local access = net.ReadTable()
	local entity = net.ReadEntity()

	if (not IsValid(door)) then
		return
	end

	local doorMenu = hook.Run("GetDoorMenu", door, access, entity)

	if (doorMenu) then
		ix.gui.door = doorMenu
		return
	end

	ix.gui.door = vgui.Create("expDoorMenu")
	ix.gui.door:SetDoor(door, access, entity)
end)

net.Receive("expDoorPermission", function()
	local door = net.ReadEntity()

	if (! IsValid(door)) then
		return
	end

	local target = net.ReadEntity()
	local access = net.ReadUInt(4)

	local panel = door.expPanel

	if (IsValid(panel) and IsValid(target)) then
		panel.access[target] = access

		for _, v in ipairs(panel.access:GetLines()) do
			if (v.player == target) then
				v:SetColumnText(2, L(ACCESS_LABELS[access or 0]))

				return
			end
		end
	end
end)

-- Draw an icon to show that a door is ownable.
function PLUGIN:DrawDoorInfo(door, width, position, angles, scale, clientPosition)
	local alpha = math.max((1 - clientPosition:DistToSqr(door:GetPos()) / 65536) * 255, 0)

	if (alpha < 1) then
		return
	end

	if (not door:GetNetVar("ownable")) then
		return
	end

	local color = ColorAlpha(ix.config.Get("color"), alpha)
	local icon = ix.util.GetMaterial("experiment-redux/electricity.png")
	local iconSize = 128 * scale

	surface.SetDrawColor(color)
	surface.SetMaterial(icon)
	surface.DrawTexturedRect(-iconSize * .5, -iconSize * .5, iconSize, iconSize)
end

function PLUGIN:PostDrawTranslucentRenderables(bDepth, bSkybox)
	if (bDepth or bSkybox or not LocalPlayer():GetCharacter()) then
		return
	end

	local entities = ents.FindInSphere(EyePos(), 256)
	local clientPosition = LocalPlayer():GetPos()

	for _, nearbyEntity in ipairs(entities) do
		if (not IsValid(nearbyEntity) or not nearbyEntity:IsDoor() or not nearbyEntity:GetNetVar("visible")) then
			continue
		end

		local color = nearbyEntity:GetColor()

		if (nearbyEntity:IsEffectActive(EF_NODRAW) or color.a <= 0) then
			continue
		end

		local position = nearbyEntity:LocalToWorld(nearbyEntity:OBBCenter())
		local mins, maxs = nearbyEntity:GetCollisionBounds()
		local width = 0
		local size = maxs - mins
		local trace = {
			collisiongroup = COLLISION_GROUP_WORLD,
			ignoreworld = true,
			endpos = position
		}

		-- trace from shortest side to center to get correct position for rendering
		if (size.z < size.x and size.z < size.y) then
			trace.start = position - nearbyEntity:GetUp() * size.z
			width = size.y
		elseif (size.x < size.y) then
			trace.start = position - nearbyEntity:GetForward() * size.x
			width = size.y
		elseif (size.y < size.x) then
			trace.start = position - nearbyEntity:GetRight() * size.y
			width = size.x
		end

		width = math.max(width, 12)
		trace = util.TraceLine(trace)

		local angles = trace.HitNormal:Angle()
		local anglesOpposite = trace.HitNormal:Angle()

		angles:RotateAroundAxis(angles:Forward(), 90)
		angles:RotateAroundAxis(angles:Right(), 90)
		anglesOpposite:RotateAroundAxis(anglesOpposite:Forward(), 90)
		anglesOpposite:RotateAroundAxis(anglesOpposite:Right(), -90)

		local positionFront = trace.HitPos - (((position - trace.HitPos):Length() * 2) + 1) * trace.HitNormal
		local positionOpposite = trace.HitPos + (trace.HitNormal * 2)

		if (trace.HitNormal:Dot((clientPosition - position):GetNormalized()) < 0) then
			-- draw front
			cam.Start3D2D(positionFront, angles, 0.1)
			self:DrawDoorInfo(nearbyEntity, width * 8, positionFront, angles, 1, clientPosition)
			cam.End3D2D()
		else
			-- draw back
			cam.Start3D2D(positionOpposite, anglesOpposite, 0.1)
			self:DrawDoorInfo(nearbyEntity, width * 8, positionOpposite, anglesOpposite, 1, clientPosition)
			cam.End3D2D()
		end
	end
end
