local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

-- NPC Configuration
NPC.name = "Larissa Thompson"
NPC.description = "This young woman has a slightly stern look."
NPC.model = "models/hl2rp/citizens/female_02.mdl"
NPC.skin = 11
NPC.bodygroups = {
	[1] = 24, -- Bright white shirt
	[2] = 4, -- Black jeans
	[3] = 0, -- No gloves
	[4] = 1, -- Glasses
}
NPC.voicePitch = 102

ix.util.Include(PLUGIN.folder .. "/interactions/sh_mission2.lua", true)
ix.util.Include(PLUGIN.folder .. "/interactions/sh_mission3.lua", true)
ix.util.Include(PLUGIN.folder .. "/interactions/sh_faq.lua", true)

if (CLIENT) then
	--- Having this function will cause the npc to have a mission marker over their head
	--- Return false to show to unavailable marker and true to show the available marker.
	--- This is only called on the client.
	--- @param npcEntity Entity
	--- @return boolean?
	function NPC:ClientGetAvailable(npcEntity)
		return not PLUGIN.MISSION_2_TRACKER:IsCompleted()
			and not PLUGIN.MISSION_3_TRACKER:IsCompleted()
	end
end
