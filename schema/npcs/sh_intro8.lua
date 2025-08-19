local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

-- NPC Configuration
NPC.name = "Nahm Park"
NPC.description = "A young woman with a calm demeanor."
NPC.model = "models/hl2rp/citizens/female_04.mdl"
NPC.skin = 13
NPC.bodygroups = {
	[1] = 0, -- Citizen shirt
	[2] = 3, -- Dark gray jeans
	[3] = 0, -- No gloves
	[4] = 1, -- Glasses
}
NPC.voicePitch = 99
