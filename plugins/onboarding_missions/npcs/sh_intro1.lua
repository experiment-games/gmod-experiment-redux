local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

-- NPC Configuration
NPC.name = "Liam Vanderberg"
NPC.description = "A frail-looking man with a kind smile."
NPC.model = "models/hl2rp/citizens/male_10.mdl"
NPC.skin = 2
NPC.bodygroups = {
	[1] = 12, -- Odessa vest
	[2] = 7, -- Rebel pants with holsters
	[3] = 2, -- Fingerless gloves
	[4] = 2, -- Green beanie
}
NPC.voicePitch = 101

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
