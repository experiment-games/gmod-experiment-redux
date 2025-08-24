local PLUGIN = PLUGIN

PLUGIN.name = "The Business"
PLUGIN.author = "Experiment Redux"
PLUGIN.description = "Adds physical business locations to the game world" -- TODO: , that appear at random locations."

function PLUGIN:BuildBusinessMenu()
	return false
end

if (SERVER) then
	util.AddNetworkString("expBusinessPurchase")
	util.AddNetworkString("expBusinessPurchaseCompleted")

	ix.util.AddResourceFile("models/experiment-redux/shopkeeper.mdl")
	ix.util.AddResourceFile("models/experiment-redux/shopkeeper_portal_door.mdl")
	ix.util.AddResourceFile("materials/models/experiment-redux/shopkeeper/robot_eye.vmt")
	ix.util.AddResourceFile("materials/models/experiment-redux/shopkeeper/robot_paint.vmt")
	ix.util.AddResourceFile("materials/models/experiment-redux/shopkeeper/robot_shipment_portal.vmt")
	ix.util.AddResourceFile("materials/models/experiment-redux/shopkeeper/robot_steel.vmt")

	net.Receive("expBusinessPurchase", function(length, client)
		local entity = net.ReadEntity()
		local uniqueID = net.ReadString()
		local itemTable = ix.item.Get(uniqueID)

		if (not itemTable) then
			client:Notify("This item is not valid.")
			return
		end

		if (not IsValid(entity) or entity:GetPos():DistToSqr(client:GetPos()) > ix.config.Get("maxInteractionDistance") ^ 2) then
			client:Notify("You are too far away from the business vendor to buy this item.")
			return
		end

		if (hook.Run("CanPlayerUseBusiness", client, uniqueID) == false) then
			client:Notify("You cannot buy this item.")
			return
		end

		local character = client:GetCharacter()
		local batchSize = itemTable.shipmentSize or 1
		local price = (itemTable.price or 0) * batchSize

		if (not character:HasMoney(price)) then
			client:Notify("You do not have enough money to purchase this item.")
			return
		end

		local inventory = character:GetInventory()
		local canFitOrPositions, maxFit = inventory:CanItemsFit(itemTable.width or 1, itemTable.height or 1, batchSize)

		if (not canFitOrPositions) then
			if (batchSize > 1) then
				client:Notify("You do not have enough space in your inventory to purchase this batch of items.")
			else
				client:Notify("You do not have enough space in your inventory to purchase this item.")
			end

			return
		end

		local status, errorMessage = inventory:Add(uniqueID, batchSize)

		-- This shouldn't happen since we checked with CanItemsFit before adding.
		if (not status) then
			ix.util.SchemaErrorNoHaltWithStack("Failed to add item to inventory (DEV THOUGHT THIS SHOULD NOT HAPPEN): " ..
				errorMessage)
			return
		end

		character:TakeMoney(price)

		if (batchSize > 1) then
			Schema.achievement.Progress("master_trader", client)
		end

		hook.Run("OnBusinessItemPurchased", client, itemTable, price, entity)

		local hasMercantilePerk, mercantilePerkTable = Schema.perk.GetOwned("mercantile", client)

		if (hasMercantilePerk) then
			local rebate = price * mercantilePerkTable.priceRebate

			if (rebate > 0) then
				character:GiveMoney(rebate)
			end
		end

		net.Start("expBusinessPurchaseCompleted")
		net.WriteUInt(character:GetMoney(), 32)
		net.Send(client)

		entity:SetNWBool("open", true)
		entity:OneShotSequence("inspect", function()
			entity:SetNWBool("open", false)
		end)
	end)
end

if (not CLIENT) then
	return
end

net.Receive("expBusinessPurchaseCompleted", function()
	local money = net.ReadUInt(32)
	Schema.businessPurchasePanel:SetItemVisible(false)
	Schema.businessPanel:UpdateWallet(money)

	LocalPlayer():EmitSound("items/suitchargeok1.wav", SNDLVL_40dB, 90, 0.5)
end)

function PLUGIN:ShowEntityMenu(entity)
	local builderOrOptions = entity:GetEntityMenu(LocalPlayer())

	if (not isfunction(builderOrOptions)) then
		return
	end

	if (IsValid(ix.menu.panel)) then
		return
	end

	local panel = vgui.Create("expEntityMenu")
	panel:InitDoubleList()
	panel:SetShowCloseButton(true)
	panel:SetEntity(entity)

	local mainPanel, entityPanel = builderOrOptions()

	panel:SetMainPanel(mainPanel)

	if (entityPanel) then
		panel:SetEntityPanel(entityPanel)
	end

	-- Don't open the default entity menu
	return true
end

-- PLUGIN.businessOutlets = PLUGIN.businessOutlets or {}
-- PLUGIN.businessOutletWindowAnimations = PLUGIN.businessOutletWindowAnimations or {}

-- local DISTANCE_FROM_WALL = 1
-- local TEXTURE_SIZE = 1024

-- local ANIMATE_WALL_OPEN = {
--     move = function(model, start, finish, duration, startTime)
--         startTime = startTime or CurTime()
--         local endTime = startTime + duration

--         PLUGIN.businessOutletWindowAnimations[#PLUGIN.businessOutletWindowAnimations + 1] = {
--             model = model,
--             startTime = startTime,
--             endTime = endTime,
--             start = start,
--             finish = finish
--         }

--         return endTime
--     end
-- }

-- function PLUGIN:DoDrawModel(model)
--     cam.PushModelMatrix(model:GetWorldTransformMatrix())
--     model:DrawModel()
--     cam.PopModelMatrix()
-- end

-- --- Takes a given position for a point on a surface, creates a render target and renders the surface to it (render.RenderView)
-- --- @param position Vector
-- --- @param angles Angle # The angle of the surface
-- --- @return ITexture
-- function PLUGIN:RenderWall(position, angles)
--     -- TODO: Reuse render targets from a pool (e.g: if we need 10, only create 10, then reuse them)
--     -- TODO: So don't give em these unique names, just give them a number 1-10
--     local name = util.CRC(
-- 		"surface_" .. position.x .. "_" .. position.y .. "_" .. position.z ..
--         "#" .. angles.p .. "_" .. angles.y .. "_" .. angles.r
-- 	)
--     local renderTarget = GetRenderTarget(
--         name,
--         TEXTURE_SIZE,
--         TEXTURE_SIZE
--     )
--     render.PushRenderTarget(renderTarget)
--     render.Clear(0, 0, 0, 255, true, true)

--     -- To brighten the model without setting up lighting
--     render.SuppressEngineLighting(true)

--     -- By default, 3D rendering to a Render Target will put the Depth Buffer into the alpha channel of the image.
--     -- I do not know why this is the case, but we can disable that behavior with this function.
--     render.SetWriteDepthToDestAlpha(false)

--     local scaledTextureSize = (TEXTURE_SIZE * 0.025) -- dunno where this number comes from, but it works for most surfaces (maybe lightmapscale?)

--     render.RenderView({
--         origin = position,
--         angles = angles,
--         x = 0,
--         y = 0,
--         w = TEXTURE_SIZE,
--         h = TEXTURE_SIZE,
--         drawviewmodel = false,
--         viewid = VIEW_MONITOR,

--         znear = 1,
--         zfar = 32768,
--         ortho = {
--             left   = -scaledTextureSize,
--             right  = scaledTextureSize,
--             top    = -scaledTextureSize,
--             bottom = scaledTextureSize
--         }
--     })

--     render.SetWriteDepthToDestAlpha(true)
--     render.SuppressEngineLighting(false)

--     render.PopRenderTarget()

--     return renderTarget
-- end

-- --- Sets a render target as the material of an entity
-- --- @param entity Entity
-- --- @param renderTarget ITexture
-- function PLUGIN:SetRenderTargetMaterial(entity, renderTarget)
--     local name = renderTarget:GetName()
--     local material = CreateMaterial(name, "VertexLitGeneric", {
--         ["$basetexture"] = renderTarget:GetName(),
--         ["$model"] = 1,
--         ["$translucent"] = 0,
--         ["$vertexalpha"] = 0,
--         ["$vertexcolor"] = 0,
--     })

--     entity:SetMaterial("!" .. name)
-- end

-- --- lua_run_cl tr = LocalPlayer():GetEyeTraceNoCursor() ix.plugin.Get("the_business"):CreateWallReplacement(tr.HitPos, tr.HitNormal:Angle(), "models/hunter/plates/plate1x1.mdl")
-- --- Creates a prop with a render target material
-- --- @param position Vector
-- --- @param angles Angle
-- --- @param plane string
-- function PLUGIN:CreateWallReplacement(position, angles, plane)
--     -- Rotate so the we render the surface from the way the player is looking
--     angles:RotateAroundAxis(angles:Up(), -180)

--     local surfacePosition = Vector(position)
--     local surfaceAngles = Angle(angles)

--     -- Move the position a bit away from the surface, so we render the surface (not from inside the surface)
--     position = position + (angles:Forward() * -DISTANCE_FROM_WALL)

--     local renderTarget = self:RenderWall(position, angles)

--     -- Flip the model to face the right way
--     surfaceAngles:RotateAroundAxis(surfaceAngles:Right(), -90)

--     -- Move the model into the surface so it can appear coming out of the surface
--     local INTO_SURFACE_BY = 5
--     surfacePosition = surfacePosition + (surfaceAngles:Up() * INTO_SURFACE_BY)

--     local entity = ClientsideModel(plane)
--     entity:SetPos(surfacePosition)
--     entity:SetAngles(surfaceAngles)
--     entity:Spawn()
--     entity:SetNoDraw(true)

--     self:SetRenderTargetMaterial(entity, renderTarget)

--     local outletAngles = Angle(surfaceAngles)
--     outletAngles:RotateAroundAxis(outletAngles:Right(), 180)
--     outletAngles:RotateAroundAxis(outletAngles:Up(), -90)

--     local forward = surfaceAngles:Up() * -INTO_SURFACE_BY

-- 	local element = vgui.Create("expBusinessTerminal")
-- 	element:SetSize(512, 512)
-- 	element:SetPaintedManually(true)

-- 	local businessOutlet = {
-- 		entity = entity,
-- 		position = surfacePosition + forward + (surfaceAngles:Right() * -23.5) + (surfaceAngles:Forward() * -23.5),
-- 		angles = outletAngles,
-- 		vgui = element,
-- 		vguiShowAt = CurTime() + 2 -- When the wall is done moving forward
-- 	}
-- 	PLUGIN.businessOutlets[#PLUGIN.businessOutlets + 1] = businessOutlet

-- 	businessOutlet.shopkeeperRenderTarget = businessOutlet.shopkeeperRenderTarget or GetRenderTarget("ShopKeeperView", TEXTURE_SIZE, TEXTURE_SIZE) -- TODO: Reuse render targets, allow multiple
-- 	businessOutlet.shopkeeperRenderTargetMaterial = businessOutlet.shopkeeperRenderTargetMaterial or CreateMaterial("ShopKeeperViewMaterial", "UnlitGeneric", {
-- 		["$basetexture"] = businessOutlet.shopkeeperRenderTarget:GetName(),
-- 		["$translucent"] = 0,
-- 		["$vertexcolor"] = 1
--     })

--     local targets = {
--         { transform = forward, time = 2 },
--         { transform = surfaceAngles:Right() * 48, time = 4 }
--     }
--     local endTime = nil
--     local previousPosition = surfacePosition

--     for i, target in ipairs(targets) do
--         local targetPosition = previousPosition + target.transform
--         endTime = ANIMATE_WALL_OPEN.move(entity, previousPosition, targetPosition, target.time, endTime)
--         previousPosition = targetPosition
--     end
-- end

-- function PLUGIN:Think()
--     for i, anim in ipairs(PLUGIN.businessOutletWindowAnimations) do
--         local model = anim.model
--         local startTime = anim.startTime
--         local endTime = anim.endTime
--         local start = anim.start
--         local finish = anim.finish

--         local time = CurTime()
--         local progress = (time - startTime) / (endTime - startTime)

--         if (progress >= 1) then
--             table.remove(PLUGIN.businessOutletWindowAnimations, i)
--             continue
--         end

--         -- Check if its started already
--         if (time < startTime) then
--             continue
--         end

--         local position = Lerp(progress, start, finish)
--         model:SetPos(position)
--     end

-- 	-- self:RenderScene()
-- end

-- function PLUGIN:PostDrawOpaqueRenderables(drawingDepth, drawingSkybox, drawingSkybox3d)
--     if (drawingSkybox) then
--         return
--     end

--     for _, businessOutlet in ipairs(PLUGIN.businessOutlets) do
--         if (not businessOutlet.vgui or (businessOutlet.vguiShowAt and businessOutlet.vguiShowAt > CurTime())) then
--             continue
--         end

-- 		local scale = 0.093
--         cam.Start3D2D(businessOutlet.position, businessOutlet.angles, scale)

-- 		-- Source for Mouse X, Y logic: https://github.com/wyozi-gmod/imgui/blob/master/imgui.lua
--         if (not vgui.CursorVisible() or vgui.IsHoveringWorld()) then
--             local trace = LocalPlayer():GetEyeTrace()
--             local eyePosition = trace.StartPos
--             local eyeNormal

--             if (vgui.CursorVisible() and vgui.IsHoveringWorld()) then
--                 eyeNormal = gui.ScreenToVector(input.GetCursorPos())
--             else
--                 eyeNormal = trace.Normal
--             end

--             local planeNormal = businessOutlet.angles:Up()

--             local hitPos = util.IntersectRayWithPlane(eyePosition, eyeNormal, businessOutlet.position, planeNormal)

--             if (not hitPos) then
-- 				PLUGIN.worldMousePosition = nil
--             else
-- 				local diff = businessOutlet.position - hitPos

-- 				-- This cool code is from Willox's keypad CalculateCursorPos
-- 				local x = diff:Dot(-businessOutlet.angles:Forward()) / scale
-- 				local y = diff:Dot(-businessOutlet.angles:Right()) / scale

-- 				PLUGIN.worldMousePosition = {x = x, y = y}
--             end
--         else
--             PLUGIN.worldMousePosition = nil
--         end

-- 		surface.SetDrawColor(255, 255, 255, 255)
-- 		businessOutlet.vgui:PaintManual()
-- 		cam.End3D2D()
-- 	end

-- 	-- Draw the wall models
--     render.SuppressEngineLighting(true)
--     render.ResetModelLighting(.5, .5, .5) -- Why does this make the models exactly the right brightness?
--     for _, businessOutlet in ipairs(PLUGIN.businessOutlets) do
--         self:DoDrawModel(businessOutlet.entity)
--     end
--     render.SuppressEngineLighting(false)

--     for _, businessOutlet in ipairs(PLUGIN.businessOutlets) do
--         render.RenderFlashlights(function()
--             self:DoDrawModel(businessOutlet.entity)
--         end)
--     end
-- end
