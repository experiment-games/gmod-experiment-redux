local helixSkin = derma.GetNamedSkin("helix")

-- Make tooltips better readable by reducing the opacity of the background
helixSkin.Colours.DarkerBackground.a = 200

-- TODO: Find different place to show credits.
-- For now I just don't like the way credits are presented to players, it breaks immersion.
hook.Remove("PopulateHelpMenu", "ixCredits")

-- There's no need to bother players with technical details on the schema. It breaks immersion.
helixSkin.DrawHelixCurved = function() end
hook.Remove("CreateMenuButtons", "ixHelpMenu")

net.Receive("expClearEntityInfoTooltip", function()
	local targetEntity = net.ReadEntity()

	if (not IsValid(ix.gui.entityInfo)) then
		return
	end

	if (targetEntity ~= Entity(0) and targetEntity ~= ix.gui.entityInfo.entity) then
		return
	end

	ix.gui.entityInfo:Remove()

	local infoPanel = vgui.Create(ix.option.Get("minimalTooltips", false) and "ixTooltipMinimal" or "ixTooltip")
	infoPanel:StopAnimations() -- Stop the expanding

	local entityPlayer = targetEntity:GetNetVar("player")

	if (entityPlayer) then
		infoPanel:SetEntity(entityPlayer)
		infoPanel.entity = targetEntity
	else
		infoPanel:SetEntity(targetEntity)
	end

	infoPanel:SetDrawArrow(true)
	ix.gui.entityInfo = infoPanel
end)

function Schema:LoadFonts(headingFont, readableFont)
	local enabledAccessibilityFont = ix.option.Get("accessibilityFont", false)
	local accessibilityFontScale = ix.option.Get("accessibilityFontScale", 1)

	local function scaleFont(size)
		return size * accessibilityFontScale
	end

	if (enabledAccessibilityFont) then
		readableFont = "Arial"
	end

	surface.CreateFont("expTinyFont", {
		font = readableFont,
		size = scaleFont(math.max(ScreenScale(4), 16)),
		extended = true,
		weight = 600
	})

	surface.CreateFont("expSmallerFont", {
		font = readableFont,
		size = scaleFont(math.max(ScreenScale(6), 24)),
		extended = true,
		weight = 400
	})

	surface.CreateFont("expSmallItalicFont", {
		font = readableFont,
		size = scaleFont(math.max(ScreenScale(6), 26)),
		extended = true,
		weight = 400,
		italic = true
	})

	surface.CreateFont("expSmallOutlinedFont", {
		font = readableFont,
		size = scaleFont(math.max(ScreenScale(6), 24)),
		extended = true,
		shadow = true,
		weight = 600,
	})

	surface.CreateFont("expMonitorLarge", {
		font = "Consolas",
		size = 255, -- max is 255
		extended = true,
		weight = 100
	})

	surface.CreateFont("expMonitorMedium", {
		font = "Consolas",
		size = 128,
		extended = true,
		weight = 100
	})

	surface.CreateFont("expMonitorSmall", {
		font = "Consolas",
		size = 64,
		extended = true,
		weight = 100
	})

	--[[
		Override default Helix fonts
	--]]
	timer.Simple(0, function()
		surface.CreateFont("ix3D2DFont", {
			font = headingFont,
			size = 128,
			extended = true,
			weight = 400
		})

		surface.CreateFont("ix3D2DMediumFont", {
			font = headingFont,
			size = 48,
			extended = true,
			weight = 400
		})

		surface.CreateFont("ix3D2DSmallFont", {
			font = headingFont,
			size = 24,
			extended = true,
			weight = 400
		})

		surface.CreateFont("ixTitleFont", {
			font = headingFont,
			size = scaleFont(ScreenScale(30)),
			extended = true,
			weight = 600
		})

		surface.CreateFont("ixSubTitleFont", {
			font = headingFont,
			size = scaleFont(math.max(ScreenScale(16), 24)),
			extended = true,
			weight = 400
		})

		surface.CreateFont("ixMenuMiniFont", {
			font = readableFont,
			size = scaleFont(math.max(ScreenScale(4), 24)),
			weight = 300,
		})

		surface.CreateFont("ixMenuButtonFont", {
			font = readableFont,
			size = scaleFont(ScreenScale(14)),
			extended = true,
			weight = 100
		})

		surface.CreateFont("ixMenuButtonFontSmall", {
			font = readableFont,
			size = scaleFont(ScreenScale(10)),
			extended = true,
			weight = 100
		})

		surface.CreateFont("ixMenuButtonFontThick", {
			font = readableFont,
			size = scaleFont(ScreenScale(14)),
			extended = true,
			weight = 600
		})

		surface.CreateFont("ixMenuButtonLabelFont", {
			font = readableFont,
			size = 28,
			extended = true,
			weight = 400
		})

		surface.CreateFont("ixMenuButtonHugeFont", {
			font = headingFont,
			size = scaleFont(ScreenScale(24)),
			extended = true,
			weight = 400
		})

		surface.CreateFont("ixToolTipText", { -- Never used
			font = readableFont,
			size = scaleFont(20),
			extended = true,
			weight = 600
		})

		surface.CreateFont("ixMonoSmallFont", {
			font = "Consolas",
			size = scaleFont(12),
			extended = true,
			weight = 800
		})

		surface.CreateFont("ixMonoMediumFont", {
			font = "Consolas",
			size = scaleFont(22),
			extended = true,
			weight = 800
		})

		surface.CreateFont("ixBigFont", {
			font = headingFont,
			size = scaleFont(36),
			extended = true,
			weight = 4000
		})

		surface.CreateFont("ixBigFontOutlined", {
			font = headingFont,
			size = scaleFont(36),
			extended = true,
			weight = 4000,
			outline = true
		})

		surface.CreateFont("ixMediumFont", {
			font = readableFont,
			size = scaleFont(28),
			extended = true,
			weight = 4000
		})

		surface.CreateFont("ixNoticeFont", {
			font = readableFont,
			size = scaleFont(math.max(ScreenScale(8), 24)),
			weight = 400,
			extended = true,
			antialias = true
		})

		surface.CreateFont("ixMediumLightFont", {
			font = headingFont,
			size = scaleFont(math.max(ScreenScale(8), 22)),
			extended = true,
			weight = 600
		})

		surface.CreateFont("ixMediumLightBlurFont", {
			font = headingFont,
			size = scaleFont(math.max(ScreenScale(8), 22)),
			extended = true,
			weight = 600,
			blursize = 4
		})

		surface.CreateFont("ixGenericFont", {
			font = readableFont,
			size = scaleFont(math.max(ScreenScale(7), 24)),
			extended = true,
			weight = 400
		})

		surface.CreateFont("ixChatFont", {
			font = readableFont,
			size = math.max(ScreenScale(7), 24) * ix.option.Get("chatFontScale", 1),
			extended = true,
			weight = 600,
			antialias = true
		})

		surface.CreateFont("ixChatFontItalics", {
			font = readableFont,
			size = math.max(ScreenScale(7), 24) * ix.option.Get("chatFontScale", 1),
			extended = true,
			weight = 600,
			antialias = true,
			italic = true
		})

		surface.CreateFont("ixSmallTitleFont", {
			font = readableFont,
			size = scaleFont(math.max(ScreenScale(12), 26)),
			extended = true,
			weight = 400
		})

		surface.CreateFont("ixMinimalTitleFont", {
			font = headingFont,
			size = scaleFont(math.max(ScreenScale(8), 26)),
			extended = true,
			weight = 800
		})

		surface.CreateFont("ixSmallFont", {
			font = readableFont,
			size = scaleFont(math.max(ScreenScale(6), 24)),
			extended = true,
			weight = 400
		})

		surface.CreateFont("ixItemDescFont", {
			font = readableFont,
			size = scaleFont(math.max(ScreenScale(6), 24)),
			extended = true,
			shadow = true,
			weight = 400
		})

		surface.CreateFont("ixSmallBoldFont", {
			font = readableFont,
			size = scaleFont(math.max(ScreenScale(8), 22)),
			extended = true,
			weight = 800
		})

		surface.CreateFont("ixItemBoldFont", {
			font = readableFont,
			shadow = true,
			size = scaleFont(math.max(ScreenScale(8), 20)),
			extended = true,
			weight = 800
		})

		surface.CreateFont("ixIntroTitleFont", {
			font = headingFont,
			size = scaleFont(math.min(ScreenScale(128), 128)),
			extended = true,
			weight = 400
		})

		surface.CreateFont("ixIntroTitleBlurFont", {
			font = headingFont,
			size = scaleFont(math.min(ScreenScale(128), 128)),
			extended = true,
			weight = 400,
			blursize = 4
		})

		surface.CreateFont("ixIntroSubtitleFont", {
			font = headingFont,
			size = scaleFont(ScreenScale(28)),
			extended = true,
			weight = 400
		})

		surface.CreateFont("ixIntroSmallFont", {
			font = headingFont,
			size = scaleFont(ScreenScale(24)),
			extended = true,
			weight = 400
		})
	end)
end

-- We override the default main menu so we can customize it
function Schema:ScoreboardShow()
	if (LocalPlayer():GetCharacter()) then
		vgui.Create("expMenu")

		-- We MUST return true to prevent default Helix behavior
		return true
	end
end

-- Copied from gamemode/core/derma/cl_help.lua to only show a tab with commands
function Schema:CreateMenuButtons(tabs)
	tabs["help"] = function(parentContainer)
		local backgroundColor = Color(0, 0, 0, 66)
		local container = parentContainer:Add("DScrollPanel")
		container:Dock(FILL)
		container:DockMargin(8, 0, 0, 0)
		container.Paint = function(_, width, height)
			surface.SetDrawColor(backgroundColor)
			surface.DrawRect(0, 0, width, height)
		end
		container.DisableScrolling = function()
			container:GetCanvas():SetVisible(false)
			container:GetVBar():SetVisible(false)
			container.OnChildAdded = function() end
		end

		local info = container:Add("DLabel")
		info:SetFont("ixSmallFont")
		info:SetText(L("helpCommands"))
		info:SetContentAlignment(5)
		info:SetTextColor(color_white)
		info:SetExpensiveShadow(1, color_black)
		info:Dock(TOP)
		info:DockMargin(0, 0, 0, 8)
		info:SizeToContents()
		info:SetTall(info:GetTall() + 16)

		info.Paint = function(_, width, height)
			surface.SetDrawColor(ColorAlpha(derma.GetColor("Info", info), 160))
			surface.DrawRect(0, 0, width, height)
		end

		for uniqueID, command in SortedPairs(ix.command.list) do
			if (command.OnCheckAccess and not command:OnCheckAccess(LocalPlayer())) then
				continue
			end

			local bIsAlias = false
			local aliasText = ""

			-- we want to show aliases in the same entry for better readability
			if (command.alias) then
				local alias = istable(command.alias) and command.alias or { command.alias }

				for _, v in ipairs(alias) do
					if (v:lower() == uniqueID) then
						bIsAlias = true
						break
					end

					aliasText = aliasText .. ", /" .. v
				end

				if (bIsAlias) then
					continue
				end
			end

			local title = container:Add("DLabel")
			title:SetFont("ixSmallBoldFont")
			title:SetText("/" .. command.name .. aliasText)
			title:Dock(TOP)
			title:SetTextColor(ix.config.Get("color"))
			title:SetExpensiveShadow(1, color_black)
			title:SizeToContents()

			local syntaxText = command.syntax
			local syntax

			if (syntaxText ~= "" and syntaxText ~= "[none]") then
				syntax = container:Add("DLabel")
				syntax:SetFont("ixMediumLightFont")
				syntax:SetText(syntaxText)
				syntax:Dock(TOP)
				syntax:SetTextColor(color_white)
				syntax:SetExpensiveShadow(1, color_black)
				syntax:SetWrap(true)
				syntax:SetAutoStretchVertical(true)
				syntax:SizeToContents()
			end

			local descriptionText = command:GetDescription()

			if (descriptionText ~= "") then
				local description = container:Add("DLabel")
				description:SetFont("ixSmallFont")
				description:SetText(descriptionText)
				description:Dock(TOP)
				description:SetTextColor(color_white)
				description:SetExpensiveShadow(1, color_black)
				description:SetWrap(true)
				description:SetAutoStretchVertical(true)
				description:SizeToContents()
				description:DockMargin(0, 0, 0, 8)
			elseif (syntax) then
				syntax:DockMargin(0, 0, 0, 8)
			else
				title:DockMargin(0, 0, 0, 8)
			end
		end
	end
end

function Schema:InitPostEntity()
	Schema.buff.CreateHUDPanel()
end

function Schema:CharacterLoaded(character)
	Schema.buff.CreateHUDPanel()
end

function Schema:ScreenResolutionChanged(oldWidth, oldHeight)
	Schema.buff.CreateHUDPanel()
end

function Schema:CreateCharacterInfo(panel)
	-- Adds the buff manager to the character panel
	panel.buffs = panel:Add("ixCategoryPanel")
	panel.buffs:SetText(L("buffs"))
	panel.buffs:Dock(TOP)
	panel.buffs:DockMargin(0, 0, 0, 8)

	local buffManager = panel.buffs:Add("expBuffManager")
	buffManager:Dock(TOP)
	buffManager:RefreshBuffs()
	buffManager.characterPanel = panel
	panel.buffs.manager = buffManager

	ix.gui.characterBuffs = buffManager

	panel.buffs:SizeToContents()

	hook.Run("CreateCharacterBuffInfo", panel, panel.buffs)

	-- Adds the ammo manager to the character panel
	panel.ammo = panel:Add("ixCategoryPanel")
	panel.ammo:SetText("Equipped Ammunition")
	panel.ammo:Dock(TOP)
	panel.ammo:DockMargin(0, 0, 0, 8)

	panel.ammoManager = panel.ammo:Add("expAmmoManager")
	panel.ammoManager:Dock(TOP)
	panel.ammoManager:RefreshAmmo()
	panel.ammo.manager = panel.ammoManager

	panel.ammo:SizeToContents()

	hook.Run("CreateCharacterAmmoInfo", panel, panel.ammoManager)
end

function Schema:UpdateCharacterInfo(panel, character)
	if (panel.buffs and panel.buffs.manager) then
		panel.buffs.manager:RefreshBuffs()
	end

	if (panel.ammo and panel.ammoManager) then
		panel.ammoManager:RefreshAmmo()
	end
end

function Schema:ContextMenuOpen()
	return LocalPlayer():IsAdmin() and IS_CONTEXT_MENU_ENABLED
end

function Schema:RenderScreenspaceEffects()
	if (not IsValid(LocalPlayer())) then
		return
	end

	local modify = {}
	local curTime = CurTime()

	if (self.flashEffect) then
		local timeLeft = math.Clamp(self.flashEffect.endAt - curTime, 0, self.flashEffect.duration)
		local incrementer = 1 / self.flashEffect.duration

		if (timeLeft > 0) then
			modify = {}

			modify["$pp_colour_brightness"] = 0
			modify["$pp_colour_contrast"] = 1 + (timeLeft * incrementer)
			modify["$pp_colour_colour"] = 1 - (incrementer * timeLeft)
			modify["$pp_colour_addr"] = incrementer * timeLeft
			modify["$pp_colour_addg"] = 0
			modify["$pp_colour_addb"] = 0
			modify["$pp_colour_mulr"] = 1
			modify["$pp_colour_mulg"] = 0
			modify["$pp_colour_mulb"] = 0

			DrawColorModify(modify)
			DrawMotionBlur(1 - (incrementer * timeLeft), 1, 0)
		else
			self.flashEffect = nil
		end
	end

	if (self.tearGassed) then
		local timeLeft = self.tearGassed - curTime

		if (timeLeft > 0) then
			if (timeLeft >= 15) then
				DrawMotionBlur(0.1 + (0.9 / (20 - timeLeft)), 1, 0)
			else
				DrawMotionBlur(0.1, 1, 0)
			end
		else
			self.tearGassed = nil
		end
	end
end

function Schema:HUDPaintBackground()
	local client = LocalPlayer()

	if (not client:GetCharacter()) then
		return
	end

	if (not client:GetLocalVar("tied")) then
		return
	end

	local canBreakFreeKey = client:GetNetVar("canBreakFreeKey")
	local breakFreeText

	if (canBreakFreeKey) then
		local keyName = input.GetKeyName(canBreakFreeKey):upper()
		breakFreeText = L("tiedBreakFreeStart", keyName)
	end

	Schema.draw.DrawLabeledValue(L "fTiedUp", breakFreeText or "")
end

function Schema:PostDrawHUD()
	local curTime = CurTime()
	local scrW, scrH = ScrW(), ScrH()

	if (self.stunEffects) then
		for k, stunEffect in pairs(self.stunEffects) do
			local alpha = math.Clamp((255 / stunEffect.duration) * (stunEffect.endAt - curTime), 0, 255)

			if (alpha ~= 0) then
				draw.RoundedBox(0, 0, 0, scrW, scrH, Color(255, 255, 255, alpha))
			else
				table.remove(self.stunEffects, k)
			end
		end
	end

	-- Warn the user clearly if disconnecting (possibly) results in losing items
	if (#Schema.disconnectPenaltiesActive > 0) then
		local anyCertainAll = false
		local reasonTexts = {}

		if (anyCertainAll) then
			reasonTexts[1] = L("disconnectPenaltyAllItems")
		else
			reasonTexts[1] = L("disconnectPenalty")
		end

		-- Disabled since it looks ugly and is unclear with current leading text
		-- for _, reasonInfo in ipairs(Schema.disconnectPenaltiesActive) do
		-- 	if (reasonInfo.isCertain) then
		-- 		anyCertainAll = true
		-- 	end

		-- 	reasonTexts[#reasonTexts + 1] = reasonInfo.reason
		-- end

		local borderThickness = 4
		local paddingX = 8
		local paddingY = 4
		local y = borderThickness
		local largestWidth = 0
		local alpha = 100

		surface.SetDrawColor(255, 0, 0, alpha)
		surface.DrawOutlinedRect(0, 0, scrW, scrH, borderThickness)

		-- Show the reasonText + all reasons underneath it
		for i, reasonText in ipairs(reasonTexts) do
			local textWidth, textHeight = Schema.GetCachedTextSize(
				"ixSmallFont",
				reasonText
			)

			local boxWidth = textWidth + (paddingX * 2)
			local boxHeight = textHeight + (paddingY * 2)

			if (boxWidth > largestWidth) then
				largestWidth = boxWidth
			end

			draw.RoundedBoxEx(
				8,
				(scrW * .5) - (largestWidth * .5),
				y,
				largestWidth,
				boxHeight,
				Color(255, 0, 0, alpha),
				false, false, true, true
			)

			draw.SimpleText(
				reasonText,
				"ixSmallFont",
				scrW * .5,
				y + paddingY,
				color_white,
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_TOP
			)

			y = y + boxHeight
		end
	end
end

function Schema:PostDrawInventory(inventory)
	if (not IsValid(inventory)) then
		return
	end

	local client = LocalPlayer()
	local character = IsValid(client) and client:GetCharacter() or nil

	if (not character) then
		return
	end

	local menuPanel = ix.gui.menu

	if (not IsValid(menuPanel) or menuPanel.bIsClosing) then
		return
	end

	if (menuPanel:GetActiveTab() ~= "inv") then
		return
	end

	local money = character:GetMoney()
	local font = "ixBigFont"
	local moneyText = ix.currency.Get(money)
	local moneyX, moneyY = ScrW() - 64, ScrH() - 64

	local moneyWidth, moneyHeight = draw.SimpleText(
		moneyText,
		font,
		moneyX, moneyY,
		ColorAlpha(ix.config.Get("color"), menuPanel.currentAlpha),
		TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM
	)

	draw.SimpleText(
		L "wallet" .. ":",
		"expSmallerFont",
		moneyX - moneyWidth - 8,
		moneyY - (moneyHeight * .5),
		Color(255, 255, 255, menuPanel.currentAlpha * .5),
		TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER
	)
end

function Schema:PopulateCharacterInfo(client, character, tooltip)
	if (client:IsRestricted()) then
		local panel = tooltip:AddRowAfter("name", "ziptie")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		panel:SetText(L("tiedUp"))
		panel:SizeToContents()
	elseif (client:GetNetVar("beingTied")) then
		local panel = tooltip:AddRowAfter("name", "ziptie")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		panel:SetText(L("beingTied"))
		panel:SizeToContents()
	elseif (client:GetNetVar("beingUntied")) then
		local panel = tooltip:AddRowAfter("name", "ziptie")
		panel:SetBackgroundColor(derma.GetColor("Warning", tooltip))
		panel:SetText(L("beingUntied"))
		panel:SizeToContents()
	end
end

function Schema:CreateItemInteractionMenu(inventoryPanel, menu, itemTable)
	local hasCashbackPerk, cashbackPerkTable = Schema.perk.GetOwned("cashback")

	if (not hasCashbackPerk) then
		return
	end

	if (not itemTable.price or itemTable.noBusiness) then
		return
	end

	-- TODO: This is a hacky way to get cashback to appear at the end of the menu, if Helix provides a way to do this, we should use it
	local oldMenuOpen = menu.Open

	function menu:Open(...)
		menu:AddOption(L("cashback"), function()
			local cashbackPrice = math.floor(itemTable.price * cashbackPerkTable.returnFraction)
			Derma_Query(L("cashbackConfirmation", ix.currency.Get(cashbackPrice)), L("cashback"), L("yes"),
				function()
					net.Start("expCashbackRequest")
					net.WriteUInt(itemTable:GetID(), 32)
					net.SendToServer()
				end, L("no"))
		end):SetImage("icon16/money_delete.png")

		oldMenuOpen(self, ...)
	end
end

function Schema:ShouldBarDraw(info)
	if (info.identifier == "health" and info:GetValue() < 1) then
		return true
	end
end

function Schema:PlayerPerkBought(client, perk)
	if (IsValid(Schema.businessPanel) and IsValid(ix.gui.menu)) then
		ix.gui.menu:FullRefresh()
	end
end

function Schema:NetworkEntityCreated(entity)
	local client = LocalPlayer()

	if (entity:GetClass() ~= "prop_ragdoll" or not IsValid(client)) then
		return
	end

	local monsterCorpseIndex = entity:GetNetVar("monsterCorpse")

	if (monsterCorpseIndex) then
		entity.GetEntityMenu = function(entity)
			if (client:IsRestricted() or not client:Alive() or not client:GetCharacter()) then
				return
			end

			local options = {}
			options[L("searchCorpse")] = true

			return options
		end

		return
	end

	local player = entity:GetNetVar("player", NULL)

	local function setupPlayerCorpse()
		entity.GetEntityMenu = function(entity)
			if (client:IsRestricted() or not client:Alive() or not client:GetCharacter()) then
				return
			end

			local target = entity:GetNetVar("player", NULL)
			local options = {}

			hook.Run("AdjustPlayerRagdollEntityMenu", options, target, entity)

			return options
		end
	end

	if (not IsValid(player)) then
		-- try again in a moment, since the player netvar might not exist yet
		timer.Simple(2, setupPlayerCorpse)
		return
	end

	setupPlayerCorpse()
end

function Schema:GetPlayerEntityMenu(target, options)
	local client = LocalPlayer()

	if (client:IsRestricted() or not client:Alive() or not client:GetCharacter()) then
		return
	end

	if (target:IsRestricted() and target:IsPlayer() and not target:GetNetVar("beingUntied")) then
		options[L("untie")] = true
	end
end

function Schema:AdjustPlayerRagdollEntityMenu(options, target, ragdoll)
	local client = LocalPlayer()

	if (client:IsRestricted() or not client:Alive() or not client:GetCharacter()) then
		return
	end

	local corpseOwnerID = ragdoll:GetNetVar("corpseOwnerID")

	if (not corpseOwnerID and target:IsPlayer()) then
		if (target:Alive() and target:IsRestricted()) then
			options[L("searchTied")] = true
			options[L("untie")] = true
		end

		return
	end

	options[L("searchCorpse")] = true

	local hasMutilatorPerk, mutilatorPerkTable = Schema.perk.GetOwned("mutilator")

	if (hasMutilatorPerk and ragdoll:GetNetVar("mutilated", 0) < mutilatorPerkTable.maximumMutilations) then
		if (hook.Run("CanPlayerMutilate", LocalPlayer(), target, ragdoll) ~= false) then
			options[L("mutilateCorpse")] = true
		end
	end
end

function Schema:ShouldPopulateEntityInfo(entity)
	if (not LocalPlayer():Alive()) then
		return false
	end

	local corpseOwnerID = entity:GetNetVar("corpseOwnerID")

	if (corpseOwnerID) then
		local character = ix.char.loaded[corpseOwnerID]
		local player = character and character:GetPlayer() or nil

		if (IsValid(player)) then
			-- Annoying how Helix doesnt keep a record of the real entity being looked at, but replaces that information with the player (from the NetVar)
			player.expPopulatingCorpse = CurTime()

			return true
		end
	end
end

function Schema:PopulateCharacterInfo(client, character, tooltip)
	if (not client.expPopulatingCorpse or client.expPopulatingCorpse < CurTime() - 1) then
		return
	end

	if (not LocalPlayer():Alive() or not LocalPlayer():GetCharacter()) then
		return
	end

	local ownerName = L "someone"

	if (character) then
		local ourCharacter = LocalPlayer():GetCharacter()

		if (ourCharacter and character and ourCharacter:DoesRecognize(character)) then
			ownerName = character:GetName()
		end
	end

	local name = L("corpseOwnerName", ownerName)

	-- Remove the default name and description
	-- Needed because Helix doesnt keep a record of the real entity being looked at (see expPopulatingCorpse above)
	tooltip:Clear()

	-- Clear only removes children the next frame, so we need this hacky delay
	timer.Simple(0, function()
		if (not IsValid(tooltip)) then
			return
		end

		local corpse = tooltip:AddRow("corpse")
		corpse:SetImportant()
		corpse:SetText(name)
		corpse:SizeToContents()
		tooltip:SizeToContents()
	end)
end

-- TODO: We could use weaponItemTable.pacData to let PAC3 handle the attachment
function Schema:PostPlayerDraw(client)
	local character = client:GetCharacter()

	if (not character) then
		return
	end

	local clientsideModelCache = Schema.clientsideModelCache or {}
	local weapons = client:GetWeapons()

	for _, weapon in pairs(weapons) do
		local class = weapon:GetClass()
		local itemTable = Schema.GetWeaponAttachment(class)

		if (not itemTable) then
			continue
		end

		if (IsValid(client:GetActiveWeapon()) and client:GetActiveWeapon():GetClass() == class) then
			continue
		end

		local model = clientsideModelCache[class]

		if (not IsValid(model)) then
			model = ClientsideModel(itemTable.model)
			model:SetNoDraw(true)

			clientsideModelCache[class] = model
		end

		local boneID = client:LookupBone(itemTable.attachmentBone)

		if (not boneID) then
			continue
		end

		local matrix = client:GetBoneMatrix(boneID)
		local position, angles = LocalToWorld(itemTable.attachmentOffsetVector, itemTable.attachmentOffsetAngles,
			matrix:GetTranslation(), matrix:GetAngles())

		model:SetPos(position)
		model:SetAngles(angles)
		model:SetupBones()
		model:DrawModel()
	end

	Schema.clientsideModelCache = clientsideModelCache
end

Schema.chunkedNetwork.HandleSend("NpcInteractShowDynamic", function(data, extraData)
	local npcEntity = Entity(data.npcEntityIndex)
	local npc = data.npc
	local interaction = data.interaction

	Schema.InitMetaObject(npc, Schema.meta.npc)
	Schema.InitMetaObject(interaction, Schema.meta.interaction)

	local responses = interaction:GetResponses()

	for _, response in ipairs(responses) do
		Schema.InitMetaObject(response, Schema.meta.interactionResponse)
	end

	local panel = vgui.Create("expEntityMenu")
	panel:InitDoubleList()
	panel:SetEntity(npcEntity)
	panel:SetCallOnRemove(function()
		if (IsValid(Schema.npc.panel)) then
			Schema.npc.panel:Remove()
		end
	end)

	local interactionPanel = vgui.Create("expNpcInteraction")
	interactionPanel:SetInteraction(interaction, npc, npcEntity, true)

	panel:SetMainPanel(interactionPanel)
	panel:SetToRemoveOnceInvalid(interactionPanel)
end)

Schema.chunkedNetwork.HandleSend("ProgressionDynamicAll", function(data, extraData)
	-- Put the data into the dynamic trackers, the values in stored.
	for _, dynamicData in ipairs(data) do
		local tracker = dynamicData.progressionTracker
		local keys = dynamicData.keys
		local goals = tracker.goals

		-- Hydrate the tracker, ensuring the correct metatables are set
		tracker.isInProgress = function(player, progression)
			-- TODO: Check if the progression is in progress (isInProgressInfo.type, isInProgressInfo.value)
			return true
		end

		-- Register the goals so the metatables are set for em
		tracker.goals = {}

		tracker = setmetatable(tracker, Schema.meta.progressionTracker)

		for _, goalInfo in ipairs(goals) do
			goalInfo.getProgress = Schema.progression.CreateGetProgressScript(tracker, goalInfo.getProgressScript)

			tracker:RegisterGoal(goalInfo)
		end

		-- If the tracker doesn't exist, we create it
		if (not Schema.progression.dynamicTrackers[tracker.uniqueID]) then
			Schema.progression.dynamicTrackers[tracker.uniqueID] = tracker
		end

		Schema.progression.StoreTracker(tracker)

		-- If the scope doesn't exist, we create it
		if (not Schema.progression.stored[tracker.scope]) then
			Schema.progression.stored[tracker.scope] = {}
		end

		-- Put the keys into the stored
		for key, value in pairs(keys) do
			Schema.progression.stored[tracker.scope][key] = value
		end
	end
end)

Schema.chunkedNetwork.HandleSend("NpcEditOpen", function(data, extraData)
	local npcToEditIndex = data.entityIndex
	local npcData

	if (npcToEditIndex) then
		npcData = data
	end

	if (IsValid(Schema.npc.editorPanel)) then
		Schema.npc.editorPanel:Close()
	end

	local function openDialog(npcToEdit)
		local dialog = vgui.Create("expNpcEditor")
		Schema.npc.editorPanel = dialog

		if (npcData) then
			Schema.InitMetaObject(npcData, Schema.meta.npc)
			dialog:SetNpcToEdit(npcToEdit, npcData)
		end

		dialog:SetSize(ScrW(), ScrH())
		dialog:Center()
		dialog:SetSizable(true)
		dialog:SetScreenLock(true)
		dialog:SetDraggable(false)
		dialog:MakePopup()
	end

	if (not npcToEditIndex) then
		openDialog()
		return
	end

	-- Since the server only just spawned the NPC, we need to wait for the entity to be valid.
	local waitForEntityTimer = "expWaitForNpcEntity" .. tostring(SysTime())

	timer.Create(waitForEntityTimer, 0.01, 500, function()
		local npcToEdit = Entity(npcToEditIndex)

		if (IsValid(npcToEdit)) then
			openDialog(npcToEdit)
			timer.Remove(waitForEntityTimer)
		end
	end)
end)

Schema.chunkedNetwork.HandleSend("ProgressionsEdit", function(progressions, extraData)
	local dialog = vgui.Create("expProgressionsEditor")
	dialog:SetSize(ScrW(), ScrH())
	dialog:Center()
	dialog:SetSizable(true)
	dialog:SetScreenLock(true)
	dialog:SetDraggable(false)
	dialog:MakePopup()
	Schema.progression.editorPanel = dialog

	-- For testing:
	-- local progressions = {
	-- 	{
	-- 		currentUniqueID = "azzd",
	-- 		uniqueID = "azzd",
	-- 		scope = "azzd#test",
	-- 		name = "Test azzd",
	-- 		completedKey = "completed",
	-- 		isInProgressInfo = {
	-- 			type = "key",
	-- 			value = "accepted",
	-- 		},
	-- 		progressionKeys = {
	-- 			{ key = "completed", type = "boolean" },
	-- 			{ key = "accepted",  type = "boolean" },
	-- 		},
	-- 		goals = {
	-- 			{
	-- 				key = "goal1",
	-- 				name = "Goal 1",
	-- 				type = "boolean",
	-- 				getProgressScript = "return 1, 2, 3",
	-- 			},
	-- 			{
	-- 				key = "goal2",
	-- 				name = "Goal 2",
	-- 				type = "boolean",
	-- 				getProgressScript = "return 3, 4, 5",
	-- 			},
	-- 		}
	-- 	},
	-- }

	Schema.PrintTableDev(progressions)
	dialog:LoadProgressions(progressions)
end)
