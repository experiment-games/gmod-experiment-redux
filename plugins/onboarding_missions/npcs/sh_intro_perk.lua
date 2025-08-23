local PLUGIN = PLUGIN

--- @type ExperimentNpc
--- @diagnostic disable-next-line: assign-type-mismatch
local NPC = NPC

-- NPC Configuration
NPC.name = "Eliana Wagner"
NPC.description =
"A stern-looking woman with an authoritative presence, her posture radiating confidence and determination."
NPC.model = "models/hl2rp/citizens/female_07.mdl"
NPC.skin = 2
NPC.bodygroups = {
	[1] = 16, -- Rebel blue outfit
	[2] = 0, -- Dark pants
	[3] = 0, -- No gloves
	[4] = 1, -- Glasses
}
NPC.voicePitch = 98

ix.util.Include(PLUGIN.folder .. "/interactions/sh_perk_mission.lua", true)
ix.util.Include(PLUGIN.folder .. "/interactions/sh_perk_mission_reject.lua", true)

if (CLIENT) then
	--- Having this function will cause the npc to have a mission marker over their head
	--- Return false to show to unavailable marker and true to show the available marker.
	--- This is only called on the client.
	--- @param npcEntity Entity
	--- @return boolean?
	function NPC:ClientGetAvailable(npcEntity)
		return PLUGIN.MISSION_3_TRACKER:IsCompleted()
			and not PLUGIN.MISSION_4_TRACKER:IsCompleted()
	end
end
