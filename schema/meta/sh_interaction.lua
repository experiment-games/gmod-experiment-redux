--- @realm shared
--- @alias InteractionTextCallback fun(interaction: Interaction, player: Player, npcEntity: Entity): string

--- @realm shared
--- @alias InteractionCheckCallback fun(interaction: Interaction, player: Player, npcEntity: Entity): boolean

--- @realm shared
--- @alias InteractionCallback fun(interaction: Interaction, player: Player, npcEntity: Entity)

--- @realm shared
--- @class InteractionInfo
--- @field uniqueID string The unique identifier for this interaction.
--- @field text string|InteractionTextCallback|table The text that the NPC will say to the player when this interaction is started.
---
--- @field serverCheckShouldStart? InteractionCheckCallback A function that determines if the player should start with this interaction based on their inventory, progression, etc.
--- @field serverOnStart? InteractionCallback Called when the player starts this interaction with the NPC.
--- @field clientOnClosedInteraction? InteractionCallback Called on the client when the interaction is closed through the close button.

--- @realm shared
--- @class Interaction : InteractionInfo
---
--- @field private responses? InteractionResponse[] The responses that the player can choose from when this interaction is started.
--- @field private conditions? NpcCondition[] Conditions that must be met for this interaction to be shown to the player.
--- @field private effects? NpcEffectInfo[] Effects that are executed when the player starts this interaction.
local META = Schema.meta.interaction or {}
Schema.meta.interaction = META

META.__index = META

--- Metamethod to style how the interaction is displayed when printed as a string.
--- @return string
--- @realm shared
function META:__tostring()
	return "interaction[" .. self.uniqueID .. "]"
end

--- Gets the unique identifier for this interaction.
--- @return string
--- @realm shared
function META:GetUniqueID()
	return self.uniqueID
end

--- Gets the text that the NPC will say to the player when this interaction is started.
--- Processes the text if it is a function or a table.
--- @param player Player
--- @param npcEntity Entity
--- @return string
--- @realm shared
function META:GetText(player, npcEntity)
	local text = self.text

	if (isfunction(text)) then
		text = self.text(self, player, npcEntity)
	end

	if (istable(text)) then
		local randomIndex = math.random(1, #text)
		local textOrFunction = text[randomIndex]

		if (isfunction(textOrFunction)) then
			return textOrFunction(self, player, npcEntity)
		end

		return textOrFunction
	end

	--- @type string
	return text
end

--- Gets the responses for this interaction.
--- @return InteractionResponse[]
--- @realm shared
function META:GetResponses()
	return self.responses
end

--- Initializes the responses for this interaction, or
--- resets them if they have already been initialized.
--- @realm shared
function META:InitResponses()
	self.responses = {}
end

--- Registers a response for this interaction. The order in which responses are registered is
--- the order in which they will be displayed to the player.
--- @param responseInfo InteractionResponseInfo
--- @return InteractionResponse
--- @realm shared
function META:RegisterResponse(responseInfo)
	--- @cast responseInfo InteractionResponse
	local response = setmetatable(responseInfo, Schema.meta.interactionResponse)
	table.insert(self.responses, response)

	response:SetIndex(#self.responses)

	return response
end

--- Gets a response by its index in the list of responses.
--- @param index number
--- @return InteractionResponse
--- @realm shared
function META:GetResponseByIndex(index)
	return self.responses[index]
end

if (SERVER) then
	--- Checks if the player should start this interaction.
	--- @param player Player
	--- @param npcEntity Entity
	--- @realm server
	function META:CheckShouldStart(player, npcEntity)
		if (not self.serverCheckShouldStart) then
			-- Check if dynamically created interaction sets have conditions
			if (not Schema.npcCondition.CheckPass(self.conditions, player, npcEntity)) then
				return false
			end

			return true
		end

		return self:serverCheckShouldStart(player, npcEntity)
	end

	--- Calls the serverOnStart callback for this interaction.
	--- @param player Player
	--- @param npcEntity Entity
	--- @realm server
	function META:CallServerOnStart(player, npcEntity)
		if (not self.serverOnStart) then
			Schema.npcEffect.Execute(self.effects, player, npcEntity)

			return
		end

		self:serverOnStart(player, npcEntity)
	end
elseif (CLIENT) then
	--- Calls the clientOnClosedInteraction callback for this interaction.
	--- Called only on the client at the moment, when the close button is
	--- clicked on the interaction panel.
	--- @param player Player
	--- @param npcEntity Entity
	--- @realm client
	function META:CallClientOnClosed(player, npcEntity)
		if (self.clientOnClosedInteraction) then
			self:clientOnClosedInteraction(player, npcEntity)
		end
	end
end
