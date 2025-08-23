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
