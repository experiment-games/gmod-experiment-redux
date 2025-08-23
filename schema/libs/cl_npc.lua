--- Client library that exposes functions to interact with NPCs.
--- It also has all functions a `CommonLibrary` has.
--- @class Schema.npc : CommonLibrary
Schema.npc = ix.util.GetOrCreateCommonLibrary("npc", function() return ix.util.NewMetaObject(Schema.meta.npc) end)
Schema.npc.isInlineEditing = Schema.npc.isInlineEditing or false

ix.chat.Register("npc_me", {
	CanSay = function(self, speaker, text)
		-- Only NPCs can use this chat, they are provided through data.npcSpeakerEntity
		return not IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text, anonymous, data)
		local format = "** %s %s"

		if (string.sub(text, 1, 1) == "'") then
			format = "** %s%s"
		end

		chat.AddText(Color(102, 205, 170), format:format(data.name, text))
	end,
	CanHear = function(self, speaker, listener, data)
		if (not IsValid(data.npcSpeakerEntity) or not IsValid(listener)) then
			return false
		end

		local range = ix.config.Get("chatRange") * 2
		return data.npcSpeakerEntity:GetPos():DistToSqr(listener:GetPos()) <= range * range
	end,
})

ix.chat.Register("npc", {
	CanSay = function(self, speaker, text)
		-- Only NPCs can use this chat, they are provided through data.npcSpeakerEntity
		return not IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text, anonymous, data)
		local format = "%s says \"%s\""

		if (data.yelling) then
			format = "%s yells \"%s\""
		elseif (data.whispering) then
			format = "%s whispers \"%s\""
		end

		chat.AddText(Color(255, 255, 255), format:format(data.name, text))
	end,
})

--- Makes it so that when talking to NPC's, operators/admins can modify the NPC's interactions.
function Schema.npc.ToggleInlineEditor()
	if (not Schema.npc.HasManagePermission(LocalPlayer())) then
		return
	end

	Schema.npc.isInlineEditing = not Schema.npc.isInlineEditing
end

function Schema.npc.CreateRewardHTML(bolts, items, attributes)
	local html = "<div class=\"rewards\"><h2>Rewards</h2>"

	-- Add bolts if provided
	if (bolts and bolts > 0) then
		html = html .. "<div><h3>Bolts:</h3> " .. string.Comma(bolts) .. "</div>"
	end

	-- Add items if provided
	if (items and table.Count(items) > 0) then
		html = html .. "<div><h3>Items:</h3><ul>"

		for itemID, quantity in pairs(items) do
			local itemName = itemID

			if (ix.item.list[itemID]) then
				itemName = ix.item.list[itemID].name or itemID
			end

			html = html .. "<li>" .. quantity .. "x " .. itemName .. "</li>"
		end

		html = html .. "</ul></div>"
	end

	-- Add attributes if provided
	if (attributes and table.Count(attributes) > 0) then
		html = html .. "<div><h3>Attribute increases:</h3><ul>"

		for attributeID, increase in pairs(attributes) do
			local attributeName = attributeID

			if (ix.attributes.list[attributeID]) then
				attributeName = ix.attributes.list[attributeID].name or attributeID
			end

			-- Format the increase value nicely
			local formattedIncrease = increase

			if (type(increase) == "number") then
				if (increase == math.floor(increase)) then
					formattedIncrease = tostring(increase)
				else
					formattedIncrease = string.format("%.2f", increase)
				end
			end

			html = html .. "<li>+" .. formattedIncrease .. " " .. attributeName .. "</li>"
		end

		html = html .. "</ul></div>"
	end

	html = html .. "</div>"

	return html
end

net.Receive("expNpcInteractShow", function(length)
	local npcEntity = net.ReadEntity()
	local interactionSet = net.ReadString()
	local interaction = net.ReadString()

	local npc = Schema.npc.Get(npcEntity:GetNpcId())

	if (not npc) then
		ix.util.SchemaErrorNoHaltFormatted("Attempted to interact with an invalid NPC.")
		return
	end

	interactionSet = npc:GetInteractionSet(interactionSet)

	if (not interactionSet) then
		ix.util.SchemaErrorNoHaltFormatted("Attempted to interact with an invalid NPC interaction set.\n")
		return
	end

	interaction = interactionSet:GetInteraction(interaction)

	if (not interaction) then
		ix.util.SchemaErrorNoHaltFormatted("Attempted to interact with an invalid NPC interaction.\n")
		return
	end

	if (IsValid(Schema.npc.panel)) then
		Schema.npc.panel:SetInteraction(interaction, npc, npcEntity)
		return
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
	interactionPanel:SetInteraction(interaction, npc, npcEntity)

	panel:SetMainPanel(interactionPanel)
	panel:SetToRemoveOnceInvalid(interactionPanel)
end)
