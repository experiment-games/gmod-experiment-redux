local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

-- NPC Configuration
NPC.name = "Luca Moretti"
NPC.description = "This young man has a friendly demeanor, dressed in a casual outfit."
NPC.model = "models/hl2rp/citizens/male_11.mdl"
NPC.skin = 8
NPC.bodygroups = {
	[1] = 4, -- Greenish shirt
	[2] = 1, -- Brownish jeans
	[3] = 2, -- Fingerless Gloves
	[4] = 1, -- Black beanie
	[5] = 0, -- No glasses
}
NPC.voicePitch = 100
