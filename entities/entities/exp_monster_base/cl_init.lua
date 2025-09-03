DEFINE_BASECLASS("base_ai")

local RECENT_CORPSE_PAC_OUTFITS = RECENT_CORPSE_PAC_OUTFITS or {}

local function AddRecentCorpsePACOutfit(entity, pacData)
	RECENT_CORPSE_PAC_OUTFITS[#RECENT_CORPSE_PAC_OUTFITS + 1] = {
		entIndex = entity:EntIndex(),
		pacData = pacData
	}

	-- Only keep the last 10 outfits
	if (#RECENT_CORPSE_PAC_OUTFITS > 10) then
		table.remove(RECENT_CORPSE_PAC_OUTFITS, 1)
	end
end

hook.Add("NetworkEntityCreated", "expRestorePacOutfitOnCorpseEntities", function(entity)
	local monsterCorpseIndex = entity:GetNetVar("monsterCorpse")

	local function setupCorpsePac()
		if (not IsValid(entity)) then
			return
		end

		for _, data in ipairs(RECENT_CORPSE_PAC_OUTFITS) do
			if (data.entIndex == monsterCorpseIndex) then
				if (not isfunction(entity.AttachPACPart)) then
					pac.SetupENT(entity)
				end

				entity:AttachPACPart(data.pacData)
				entity:SetPACDrawDistance(0)

				local invisibleTimer = "expCorpsePacInvisible" .. entity:EntIndex()
				timer.Create(invisibleTimer, 0, 0, function()
					if (not IsValid(entity)) then
						timer.Remove(invisibleTimer)
						return
					end

					entity:SetNoDraw(true)
				end)

				break
			end
		end
	end

	if (not monsterCorpseIndex) then
		-- Retry ASAP until the monsterCorpse index is received on this client
		local timerName = "expSetupCorpsePac" .. entity:EntIndex()

		timer.Create(timerName, 0, 500, function()
			if (not IsValid(entity)) then
				timer.Remove(timerName)
				return
			end

			monsterCorpseIndex = entity:GetNetVar("monsterCorpse", nil)

			if (monsterCorpseIndex) then
				timer.Remove(timerName)
				setupCorpsePac()
			end
		end)

		return
	end

	setupCorpsePac()
end)

include("shared.lua")

ENT.PopulateEntityInfo = true

function ENT:OnPopulateEntityInfo(container)
	local name = container:AddRow("name")
	name:SetImportant()
	name:SetText(self:GetDisplayName())
	name:SizeToContents()

	local healthBar = container:Add("expProgressBar")
	healthBar:SetValue(function()
		if (not IsValid(self)) then
			return 0
		end

		return self:Health()
	end)
	healthBar:SetMaxValue(self:GetMaxHealth())
	healthBar:SetPrefix("Health: ")
	healthBar:SetProgressColors({
		{ threshold = 0, color = derma.GetColor("Error", healthBar) },
	})
	healthBar:Dock(BOTTOM)
end

-- Override this to dress up the monster
function ENT:GetPacData()
	return nil
end

function ENT:Draw()
	-- Only draw the base model if PAC3 is not enabled
	if (not self.expSetupPAC) then
		self:DrawModel()
	end
end

function ENT:Think()
	if (self.expSetupPAC) then
		return
	end

	local pacData = self:GetPacData()

	if (not pacData) then
		return
	end

	if (not isfunction(self.AttachPACPart)) then
		pac.SetupENT(self)
	end

	self.expSetupPAC = true
	self:AttachPACPart(pacData)
	self:SetPACDrawDistance(0) -- Always draw
	AddRecentCorpsePACOutfit(self, pacData)
end
