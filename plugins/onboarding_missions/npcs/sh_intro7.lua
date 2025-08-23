local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

-- NPC Configuration
NPC.name = "Rose Lewis"
NPC.description = "A young woman who's eyes seem to hold a deep sadness."
NPC.model = "models/hl2rp/citizens/female_06.mdl"
NPC.skin = 7
NPC.bodygroups = {
	[1] = 6, -- Tattered citizen shirt
	[2] = 0, -- Jeans
	[3] = 1, -- Fingerless gloves
	[4] = 0, -- No glasses
}
NPC.voicePitch = 100

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
