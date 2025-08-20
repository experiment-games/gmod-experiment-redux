local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

-- NPC Configuration
NPC.name = "Oprhelia Carter"
NPC.description = "This young woman has a mysterious aura."
NPC.model = "models/hl2rp/citizens/female_07.mdl"
NPC.skin = 6
NPC.bodygroups = {
	[1] = 5, -- Greenish shirt
	[2] = 7, -- Dark gray jeans
	[3] = 1, -- Fingerless gloves
	[4] = 1, -- Glasses
}
NPC.voicePitch = 100
