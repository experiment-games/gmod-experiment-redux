--- Represents a coded NPC that players can interact with.
--- @realm shared
--- @class ExperimentNpc
---
--- @field uniqueID string The unique identifier for this NPC.
--- @field name string The name of the NPC. This is what will be displayed when the player looks at the NPC.
--- @field description string The description of the NPC is shown under the name when the player looks at the NPC.
--- @field health number The health of the NPC. This is how much damage the NPC can take before dying. Set to Schema.npc.NO_HEALTH to make the NPC invincible.
---
--- @field model string|table The model of the NPC. This is what the NPC will look like. Can be a table, in which case a random model will be chosen each server restart.
--- @field skin number The skin of the NPC. This determines the appearance of the NPC's model.
--- @field bodygroups table<number, number> A table representing the bodygroups of the NPC. The keys are the bodygroup IDs, and the values are the bodygroup values.
---
--- @field voicePitch number The voice pitch of the NPC. This can be a number between 0 and 255. It will change the voice set lines to sound higher or lower.
--- @field voiceSet table The voice set, a random table of voice lines that the NPC will say when interacted with.
---
--- @field OnStart fun(npc: ExperimentNpc, player: Player, npcEntity: Entity):(boolean?)? Called when the player starts an interaction with the NPC.
--- @field OnEnd fun(npc: ExperimentNpc, player: Player, npcEntity: Entity)? Called when the player's interaction with the NPC ends.
--- @field OnThink fun(npc: ExperimentNpc, npcEntity: Entity)? Called every time the NPC entity thinks
--- @field ClientGetAvailable fun(npc: ExperimentNpc, npcEntity: Entity):(boolean?)? Called to determine if the NPC should have a mission marker over their head (true for the available marker, false for the in-progress marker, nil for no marker)
---
--- @field interactionSets InteractionSet[] The interactionSets that the player can choose from when they interact with this NPC.
local META = Schema.meta.npc or {}
Schema.meta.npc = META

META.__index = META

--- Metamethod to style how the NPC is displayed when printed as a string.
--- @return string
--- @realm shared
function META:__tostring()
	return "npc[" .. self.uniqueID .. "]"
end

--- Gets the unique identifier of the NPC.
--- @return string
--- @realm shared
function META:GetUniqueID()
	return self.uniqueID
end

--- Gets the name of the NPC.
--- @return string
--- @realm shared
function META:GetName()
	return self.name
end

--- Gets the description of the NPC.
--- @return string
--- @realm shared
function META:GetDescription()
	return self.description
end

--- Gets the model of the NPC.
--- @return string|table
--- @realm shared
function META:GetModel()
	if (isstring(self.model)) then
		return self.model
	end

	return self.model[math.random(1, #self.model)]
end

--- Gets the health of the NPC. Will be `Schema.npc.NO_HEALTH` if no
--- health is set, meaning the NPC is invincible.
--- @return number
--- @realm shared
function META:GetHealth()
	return self.health or Schema.npc.NO_HEALTH
end

--- Gets the voice pitch of the NPC.
--- @return number
--- @realm shared
function META:GetVoicePitch()
	return self.voicePitch
end

--- Gets the voice set of the NPC.
--- @return table
--- @realm shared
function META:GetVoiceSet()
	return self.voiceSet
end

--- Gets all interaction sets for this NPC.
--- @return InteractionSet[]
--- @realm shared
function META:GetInteractions()
	return self.interactionSets
end

--- Registers an interaction for this NPC. The order in which interactionSets are registered is
--- the order in which they will be displayed to the player. Using serverCheckShouldStart
--- you can determine which interactionSets should be shown to the player.
--- @param interactionSetInfo InteractionSetInfo
--- @return InteractionSet
--- @realm shared
function META:RegisterInteractionSet(interactionSetInfo)
	self.interactionSets = self.interactionSets or {}

	-- To support Lua refreshing, we first try to see if this interaction set already exists.
	-- If it does, we update it. If it doesn't, we create it.
	local interactionSet = self:GetInteractionSet(interactionSetInfo.uniqueID)

	if (interactionSet) then
		table.Merge(interactionSet, interactionSetInfo, true)
	else
		--- @cast interactionSetInfo InteractionSet
		interactionSet = setmetatable(interactionSetInfo, Schema.meta.interactionSet)
		table.insert(self.interactionSets, interactionSet)
	end

	--- When Lua refreshes, we want to ensure the new responses do not
	--- append to the old responses. So we wipe the responses table.
	--- Shortly after this the responses will be re-registered anyway.
	interactionSet:InitInteractions()

	return interactionSet
end

--- Gets an interaction set by its uniqueID.
--- @param uniqueID string
--- @return InteractionSet?
--- @realm shared
function META:GetInteractionSet(uniqueID)
	if (not self.interactionSets) then
		return
	end

	for _, interactionSet in ipairs(self.interactionSets) do
		if (interactionSet.uniqueID == uniqueID) then
			return interactionSet
		end
	end
end

--- Determines a fitting interaction for the player and this NPC.
--- @param player Player
--- @param npcEntity Entity
--- @return InteractionSet?
--- @realm shared
function META:GetDesiredInteractionSet(player, npcEntity)
	if (not self.interactionSets) then
		return
	end

	for _, interactionSet in ipairs(self.interactionSets) do
		local shouldStart = interactionSet:CheckShouldStart(player, npcEntity)

		if (DEBUG_SHOULD_START) then
			print("npc", self.uniqueID, "interactionSet", interactionSet.uniqueID, "shouldStart", shouldStart)
		end

		if (shouldStart) then
			return interactionSet
		end
	end
end

--- Sets the entity that represents this NPC. Note that this will not work
--- if multiple entities represent the same NPC.
--- @param entity Entity
--- @realm shared
function META:SetEntity(entity)
	self.entity = entity
end

--- Gets the entity that represents this NPC.
--- @return Entity
--- @realm shared
function META:GetEntity()
	return self.entity
end
