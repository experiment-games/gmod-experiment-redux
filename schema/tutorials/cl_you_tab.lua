local TUTORIAL = TUTORIAL

TUTORIAL.uniqueID = "you_tab"
TUTORIAL.activateOn = "OnMainMenuCreated"
TUTORIAL.deactivateOn = "CreateCharacterBuffInfo"

function TUTORIAL:OnActivate(menuPanel)
	-- Store reference if needed
end

function TUTORIAL:DrawFocusAreas(scrW, scrH, alpha)
	local youButton = Schema.tutorial.FindMenuButton("you")

	if not youButton or not IsValid(youButton) then
		return
	end

	Schema.tutorial.youButton = youButton

	local x, y = youButton:LocalToScreen(0, 0)
	local w, h = youButton:GetSize()

	if youButton:GetSelected() then
		Schema.tutorial.HideCurrentTutorial()
		return
	end

	Schema.draw.DrawUndimmedRect(x, y, w, h, alpha)
end

function TUTORIAL:GetText()
	local menuPanel = ix.gui.menu

	if not IsValid(menuPanel) or menuPanel.bClosing then
		local menuKey = Schema.util.LookupBinding("+showscores") or "TAB"

		return {
			Schema.tutorial.ImportantText("Press " .. menuKey .. " once to open the main menu."),
		}
	end

	if not Schema.tutorial.youButton or not IsValid(Schema.tutorial.youButton) then
		return
	end

	local x, y = Schema.tutorial.youButton:LocalToScreen(0, 0)
	local w, h = Schema.tutorial.youButton:GetSize()

	return Schema.tutorial.ImportantText("Click on the 'You' tab to continue."), x + w + 8, y + (h * .5), TEXT_ALIGN_LEFT,
		TEXT_ALIGN_CENTER
end

--[[

lastOrder = PLUGIN:AddTutorial(lastOrder + 1, {
	ActivateOn = "CreateCharacterBuffInfo",

	OnActivate = function(tutorial, menuPanel, buffsPanel)
		tutorial.buffsPanel = buffsPanel
	end,

	DrawFocusAreas = function(tutorial, scrW, scrH, alpha)
		local menuPanel = ix.gui.menu

		if (not IsValid(menuPanel) or not IsValid(menuPanel.tabs) or menuPanel.bClosing) then
			return
		end

		local inventoryButton = PLUGIN:FindMenuButton("inv")

		if (not inventoryButton or not IsValid(inventoryButton)) then
			return
		end

		tutorial.inventoryButton = inventoryButton

		if (inventoryButton:GetSelected()) then
			local tabs = inventoryButton:GetParent()
			local buttons = tabs:GetParent()
			local menu = buttons:GetParent()
			PLUGIN:NextTutorial(menu)
			return
		end

		if (not IsValid(tutorial.buffsPanel)) then
			return
		end

		local x, y = tutorial.buffsPanel:LocalToScreen(0, 0)
		local w, h = tutorial.buffsPanel:GetSize()

		local inventoryX, inventoryY = inventoryButton:LocalToScreen(0, 0)
		local combinedW, combinedH = w + (x - inventoryX), h + (y - inventoryY)

		Schema.draw.DrawUndimmedRect(
			math.min(x, inventoryX),
			math.min(y, inventoryY),
			combinedW,
			combinedH,
			alpha
		)
	end,

	GetText = function(tutorial)
		if (not IsValid(tutorial.buffsPanel)) then
			local menuKey = Schema.util.LookupBinding("+showscores") or "TAB"

			return {
				importantText("Press " .. menuKey .. " once to open the main menu."),
			}
		end

		local x, y = tutorial.buffsPanel:LocalToScreen(0, 0)
		local w, h = tutorial.buffsPanel:GetSize()
		local combinedW, combinedH = w, h

		if (tutorial.inventoryButton and IsValid(tutorial.inventoryButton)) then
			local inventoryX, inventoryY = tutorial.inventoryButton:LocalToScreen(0, 0)

			combinedW = w + (x - inventoryX)
			combinedH = h + (y - inventoryY)

			x = math.min(x, inventoryX)
			y = math.min(y, inventoryY)
		end

		return {
			"Through nano technology you can be (de)buffed.",
			"Hovering over a buff will show how it affects you.",
			importantText("Hover over a nano buff to view what it does."),
			importantText("Next, click on the inventory tab to continue."),
		}, x + (combinedW * .5), y + combinedH, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP
	end,
})

lastOrder = PLUGIN:AddTutorial(lastOrder + 1, {
	ActivateOn = "OnMainMenuCreated",

	OnActivate = function(tutorial, menuPanel)
		--
	end,

	DrawFocusAreas = function(tutorial, scrW, scrH, alpha)
		local inventoryButton = PLUGIN:FindMenuButton("inv")

		if (not inventoryButton or not IsValid(inventoryButton)) then
			return
		end

		tutorial.inventoryButton = inventoryButton

		local x, y = inventoryButton:LocalToScreen(0, 0)
		local w, h = inventoryButton:GetSize()

		if (inventoryButton:GetSelected()) then
			PLUGIN:NextTutorial()
			return
		end

		Schema.draw.DrawUndimmedRect(x, y, w, h, alpha)
	end,

	GetText = function(tutorial)
		local menuPanel = ix.gui.menu

		if (not IsValid(menuPanel) or menuPanel.bClosing) then
			local menuKey = Schema.util.LookupBinding("+showscores") or "TAB"

			return {
				importantText("Press " .. menuKey .. " once to open the main menu."),
			}
		end

		local x, y = tutorial.inventoryButton:LocalToScreen(0, 0)
		local w, h = tutorial.inventoryButton:GetSize()

		return importantText("Click on the inventory tab to continue."), x + w + 8, y + (h * .5), TEXT_ALIGN_LEFT,
			TEXT_ALIGN_CENTER
	end,
})

lastOrder = PLUGIN:AddTutorial(lastOrder + 1, {
	DrawFocusAreas = function(tutorial, scrW, scrH, alpha)
		if (not IsValid(ix.gui.inv1)) then
			return
		end

		local x, y = ix.gui.inv1:LocalToScreen(0, 0)
		local w, h = ix.gui.inv1:GetSize()

		Schema.draw.DrawUndimmedRect(x, y, w, h, alpha)
	end,

	GetText = function(tutorial)
		local menuPanel = ix.gui.menu

		if (not IsValid(menuPanel) or menuPanel.bClosing) then
			local menuKey = Schema.util.LookupBinding("+showscores") or "TAB"

			return {
				importantText("Press " .. menuKey .. " once to open the main menu."),
			}
		end

		if (not IsValid(ix.gui.inv1) or not ix.gui.inv1:IsVisible()) then
			return {
				importantText("Click on the inventory tab to continue."),
			}
		end

		local x, y = ix.gui.inv1:LocalToScreen(0, 0)
		local w, h = ix.gui.inv1:GetSize()

		return {
			"Here you see your inventory. Hover over an item to show more information.",
			"You can drag items around to organize them.",
			importantText("Now, first right-click the piece of paper named 'An Introduction',"),
			importantText("then select 'Read' to continue."),
		}, x, y + h, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
	end,
})
--]]
