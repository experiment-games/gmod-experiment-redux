local PLUGIN = PLUGIN

util.AddNetworkString("expSetMonitorTarget")
util.AddNetworkString("expMonitorsPrintPresets")
util.AddNetworkString("expSetMonitorVgui")

ix.util.AddResourceFile("materials/experiment-redux/arrow.png")
ix.util.AddResourceFile("materials/experiment-redux/arrow_forward.png")
ix.util.AddResourceFile("materials/experiment-redux/arrow_backward.png")
ix.util.AddResourceSingleFile("materials/experiment-redux/combinescanline.vmt")

function PLUGIN:SpawnMonitor(parent, monitor)
	local monitorEnt = ents.Create("exp_monitor")
	monitorEnt:SetMonitorWidth(monitor.width)
	monitorEnt:SetMonitorHeight(monitor.height)
	monitorEnt:SetMonitorScale(monitor.scale or 1)
	monitorEnt:ConfigureParent(parent, monitor.offsetPosition, monitor.offsetAngles)
	monitorEnt:Spawn()
	monitorEnt:SetPoweredOn(false)

	return monitorEnt
end

function PLUGIN:SetupParentEntity(parent, preset)
	parent:SetModel(preset.model)
	parent:SetModelScale(preset.modelScale or 1)
end

function PLUGIN:DramaticDelayEachMonitor(monitorEntities, callback)
	for i = 1, #monitorEntities do
		local monitor = monitorEntities[i]

		timer.Simple(math.Rand(0, 1) * i, function()
			if (IsValid(monitor)) then
				callback(monitor)
			end
		end)
	end
end

function PLUGIN:SetTarget(entity)
	self.currentTarget = entity

	net.Start("expSetMonitorTarget")
	net.WriteEntity(entity)
	net.Broadcast()

	local monitorEntities = ents.FindByClass("exp_monitor")

	hook.Run("ExperimentMonitorsFilter", monitorEntities, "target")

	-- Dramatically turn on/off all monitors with delay
	self:DramaticDelayEachMonitor(monitorEntities, function(monitor)
		if (IsValid(entity)) then
			monitor:SetPoweredOn(true)
		else
			monitor:SetPoweredOn(false)
		end
	end)
end

function PLUGIN:RelateMonitorToParent(monitor, parent)
	parent._relatedMonitors = parent._relatedMonitors or {}
	parent._relatedMonitors[#parent._relatedMonitors + 1] = monitor

	if (not parent._uniqueNameForSaving) then
		PLUGIN.lastUniqueName = (PLUGIN.lastUniqueName or 0) + 1
		parent._uniqueNameForSaving = util.Base64Encode(os.time() .. "#" .. PLUGIN.lastUniqueName)
	end

	monitor._parentUniqueName = parent._uniqueNameForSaving
end

function PLUGIN:SaveMonitorData()
	local entities = {}

	local parentEntities = {}

	for _, monitor in ipairs(ents.FindByClass("exp_monitor")) do
		if (monitor:MapCreationID() > -1) then
			-- Do not save entities that are part of the map.
			continue
		end

		if (not IsValid(monitor) or not monitor._parentUniqueName) then
			continue
		end

		local data = {
			width = monitor:GetMonitorWidth(),
			height = monitor:GetMonitorHeight(),
			scale = monitor:GetMonitorScale(),
			parentName = monitor._parentUniqueName,
			angles = monitor:GetLocalAngles(),
			pos = monitor:GetLocalPos(),
		}

		parentEntities[monitor._parentUniqueName] = parentEntities[monitor._parentUniqueName] or monitor:GetParent()

		entities[#entities + 1] = data
	end

	local parentEntitiesData = {}

	for uniqueName, parentEntity in pairs(parentEntities) do
		if (not IsValid(parentEntity)) then
			continue
		end

		local data = {
			name = parentEntity._uniqueNameForSaving,
			model = parentEntity:GetModel(),
			scale = parentEntity:GetModelScale(),
			pos = parentEntity:GetPos(),
			angles = parentEntity:GetAngles()
		}

		local physicsObject = parentEntity:GetPhysicsObject()

		if (IsValid(physicsObject)) then
			data.movable = physicsObject:IsMoveable()
		end

		parentEntitiesData[uniqueName] = data
	end

	self:SetData({
		entities = entities,
		parentEntities = parentEntitiesData
	})
end

function PLUGIN:LoadMonitorData()
	local data = self:GetData()

	if (not data) then
		return
	end

	-- Place the parent entities
	local parentEntities = {}

	for uniqueName, parentData in pairs(data.parentEntities or {}) do
		local parent = ents.Create("prop_physics")
		PLUGIN:SetupParentEntity(parent, {
			model = parentData.model,
			modelScale = parentData.scale,
		})
		parent:SetPos(parentData.pos)
		parent:SetAngles(parentData.angles)
		parent:Spawn()

		local physicsObject = parent:GetPhysicsObject()

		if (IsValid(physicsObject) and parentData.movable) then
			physicsObject:EnableMotion(parentData.movable)
		else
			parent:SetMoveType(MOVETYPE_NONE)
		end

		parent._uniqueNameForSaving = uniqueName
		parent._relatedMonitors = {}

		parentEntities[uniqueName] = parent
	end

	-- Place the monitors
	for _, monitorData in ipairs(data.entities or {}) do
		local parent = parentEntities[monitorData.parentName]

		if (not IsValid(parent)) then
			continue
		end

		self:SpawnMonitor(parent, {
			width = monitorData.width,
			height = monitorData.height,
			scale = monitorData.scale,
			offsetPosition = monitorData.pos,
			offsetAngles = monitorData.angles,
		})
	end
end
