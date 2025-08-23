local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

-- NPC Configuration
NPC.name = "Emilio Sanchez"
NPC.description = "This young man has a friendly demeanor, dressed in a casual outfit."
NPC.model = "models/hl2rp/citizens/male_12.mdl"
NPC.skin = 8
NPC.bodygroups = {
	[1] = 3, -- Off-white shirt with green accents
	[2] = 1, -- Blackgray jeans
	[3] = 0, -- No gloves
	[4] = 0, -- No hat
	[5] = 0, -- No glasses
}
NPC.voicePitch = 102

ix.util.Include(PLUGIN.folder .. "/interactions/sh_mission2.lua", true)
ix.util.Include(PLUGIN.folder .. "/interactions/sh_mission3.lua", true)
ix.util.Include(PLUGIN.folder .. "/interactions/sh_faq.lua", true)
