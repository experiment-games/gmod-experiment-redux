local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

-- NPC Configuration
NPC.name = "Kevin Choi"
NPC.description = "This young man has a friendly demeanor."
NPC.model = "models/hl2rp/citizens/male_05.mdl"
NPC.skin = 6
NPC.bodygroups = {
	[1] = 4, -- Green shirt
	[2] = 10, -- Clean black pants
	[3] = 0, -- No gloves
	[4] = 2, -- Red beanie
	[5] = 0, -- No glasses
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
