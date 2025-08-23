local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

-- NPC Configuration
NPC.name = "Elroy Anderson"
NPC.description = "A man with a rugged appearance, wearing a tattered shirt and jeans."
NPC.model = "models/hl2rp/citizens/male_01.mdl"
NPC.skin = 14
NPC.bodygroups = {
	[1] = 5, -- Tattered citizen shirt
	[2] = 2, -- Bright blue jeans
	[3] = 1, -- Gloves
	[4] = 0, -- No hat
	[5] = 1, -- Glasses
}
NPC.voicePitch = 98

ix.util.Include(PLUGIN.folder .. "/interactions/sh_mission2.lua", true)
ix.util.Include(PLUGIN.folder .. "/interactions/sh_mission3.lua", true)
ix.util.Include(PLUGIN.folder .. "/interactions/sh_faq.lua", true)
