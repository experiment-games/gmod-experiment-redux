local PLUGIN = PLUGIN

include("shared.lua")

function ENT:OnPopulateEntityInfo(tooltip)
	local ownerName, isOwner = self:GetOwnerName()
	local name = tooltip:AddRow("name")
	name:SetImportant()

	if (isOwner) then
		name:SetText(L("turretOwnerSelf"))
	else
		if (ownerName == false) then
			name:SetText(L("turretOwnerTheBusiness"))
			name:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		else
			name:SetText(L("turretOwnerName", ownerName))
		end
	end

	name:SizeToContents()

	-- Show turret mode
	local modeRow = tooltip:AddRow("mode")
	modeRow:SetText(L("turretMode", self:GetModeDisplayName()))
	modeRow:SizeToContents()

	local healthBar = tooltip:Add("expProgressBar")
	healthBar:SetValue(self:Health())
	healthBar:SetMaxValue(self:GetMaxHealth())
	healthBar:SetPrefix(L("turretHealth"))

	-- Only red
	healthBar:SetProgressColors({
		{ threshold = 1, color = derma.GetColor("Error", healthBar) },
	})

	healthBar:Dock(BOTTOM)
	healthBar:SizeToContents()
end

function ENT:Think()
	if (IsValid(self.turretNPC)) then
		-- Already setup
		return
	end

	self.turretNPC = self:GetChildren()[1]

	if (not IsValid(self.turretNPC)) then
		-- Not yet fully spawned
		return
	end

	self.turretNPC.PopulateEntityInfo = true
	self.turretNPC.OnPopulateEntityInfo = function(npc, tooltip)
		self:OnPopulateEntityInfo(tooltip)
	end
	self.turretNPC.GetEntityMenu = function(...)
		return self:GetEntityMenu(...)
	end
end

function ENT:GetEntityMenu()
	local options = {}

	-- Only owner can change settings
	if (not self:IsOwner(LocalPlayer())) then
		return options
	end

	-- If the turret is damaged, allow repairs
	if (self:Health() < self:GetMaxHealth()) then
		options[L("turretRepair")] = function() end

		if (self:Health() <= 0) then
			-- Don't allow mode changes
			return
		end
	end

	local playerAlliance = LocalPlayer():GetAlliance()

	-- Add mode options
	if (not self:GetPlayerDisabled()) then
		options[L("turretModeDisable")] = function()
			self:SendLongRangeInteraction("changeTurretMode", PLUGIN.TURRET_MODES.DISABLED)

			return false
		end
	end

	local currentMode = self:GetPlayerDisabled() and -1 or self:GetTurretMode()

	if (currentMode ~= PLUGIN.TURRET_MODES.DEFEND_ALL) then
		options[L("turretModeDefendAll")] = function()
			self:SendLongRangeInteraction("changeTurretMode", PLUGIN.TURRET_MODES.DEFEND_ALL)

			return false
		end
	end

	if (currentMode ~= PLUGIN.TURRET_MODES.DEFEND_OWNER) then
		options[L("turretModeDefendOwner")] = function()
			self:SendLongRangeInteraction("changeTurretMode", PLUGIN.TURRET_MODES.DEFEND_OWNER)

			return false
		end
	end

	-- Alliance modes only available if player has an alliance
	if (playerAlliance) then
		if (currentMode ~= PLUGIN.TURRET_MODES.DEFEND_ALLIANCE) then
			options[L("turretModeDefendAlliance")] = function()
				self:SendLongRangeInteraction("changeTurretMode", PLUGIN.TURRET_MODES.DEFEND_ALLIANCE)

				return false
			end
		end

		if (currentMode ~= PLUGIN.TURRET_MODES.DEFEND_AREA_ALLIANCE) then
			options[L("turretModeDefendAreaAlliance")] = function()
				self:SendLongRangeInteraction("changeTurretMode", PLUGIN.TURRET_MODES.DEFEND_AREA_ALLIANCE)

				return false
			end
		end

		if (currentMode ~= PLUGIN.TURRET_MODES.DEFEND_AREA_ALLIANCE) then
			options[L("turretModeDefendAreaAlliance")] = function()
				self:SendLongRangeInteraction("changeTurretMode", PLUGIN.TURRET_MODES.DEFEND_AREA_ALLIANCE)

				return false
			end
		end
	end

	if (currentMode ~= PLUGIN.TURRET_MODES.DEFEND_AREA_OWNER) then
		options[L("turretModeDefendAreaOwner")] = function()
			self:SendLongRangeInteraction("changeTurretMode", PLUGIN.TURRET_MODES.DEFEND_AREA_OWNER)

			return false
		end
	end

	return options
end
