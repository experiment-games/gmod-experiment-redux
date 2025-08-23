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
