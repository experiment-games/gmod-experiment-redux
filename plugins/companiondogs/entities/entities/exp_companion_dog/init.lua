local PLUGIN = PLUGIN

include("shared.lua")
AddCSLuaFile("shared.lua")

DEFINE_BASECLASS("exp_companion_base")

-- Called when the entity initializes.
function ENT:Initialize()
	BaseClass.Initialize(self)
end

function ENT:SetupVoiceSounds()
	-- self:SetTypedVoiceSet("Idle", {
	-- 	"forpnpcs/dog/npc_dog_growl_01.wav",
	-- 	"forpnpcs/dog/npc_dog_growl_02.wav",
	-- 	"forpnpcs/dog/npc_dog_growl_03.wav",
	-- })

	self:SetTypedVoiceSet("Pain", {
		"forpnpcs/dog/npc_dog_injured_01.wav",
		"forpnpcs/dog/npc_dog_injured_02.wav",
		"forpnpcs/dog/npc_dog_injured_03.wav",
		"forpnpcs/dog/npc_dog_injured_04.wav",

	})

	self:SetTypedVoiceSet("Die", {
		"forpnpcs/dog/npc_dog_injured_05.wav",
		"forpnpcs/dog/npc_dog_injured_06.wav",
	})

	self:SetTypedVoiceSet("Alert", {
		"forpnpcs/dog/npc_dog_growl_01.wav",
		"forpnpcs/dog/npc_dog_growl_02.wav",
		"forpnpcs/dog/npc_dog_growl_03.wav",
		"forpnpcs/dog/npc_dog_growl_04.wav",
		"forpnpcs/dog/npc_dog_growl_05.wav",
		"forpnpcs/dog/npc_dog_growl_06.wav",
		"forpnpcs/dog/npc_dog_growl_07.wav",
	})

	self:SetTypedVoiceSet("Chase", {
		"forpnpcs/dog/npc_dog_bark_04.wav",
		"forpnpcs/dog/npc_dog_bark_05.wav",
		"forpnpcs/dog/npc_dog_bark_06.wav",
		"forpnpcs/dog/npc_dog_bark_07.wav",
	})

	self:SetTypedVoiceSet("Lost", {
		"forpnpcs/dog/npc_dog_bark_08.wav",
		"forpnpcs/dog/npc_dog_bark_09.wav",
	})

	self:SetTypedVoiceSet("Attack", {
		"forpnpcs/dog/npc_dog_attackforward_01.wav",
		"forpnpcs/dog/npc_dog_attackforward_02.wav",
	})

	self:SetTypedVoiceSet("AttackMiss", {
		"forpnpcs/dog/npc_dog_attackforward_05.wav",
		"forpnpcs/dog/npc_dog_attackforward_06.wav",
	})

	self:SetTypedVoiceSet("AttackHit", {
		"forpnpcs/dog/npc_dog_attackforward_03.wav",
		"forpnpcs/dog/npc_dog_attackforward_04.wav",
	})

	-- self:SetTypedVoiceSet("AttackHitDoor", {
	-- 	"NPC_BaseZombie.PoundDoor"
	-- })

	self:SetTypedVoiceSet("Victory", {
		"forpnpcs/dog/npc_dog_bark_04.wav"
	})

	self:SetTypedVoiceSet("Footstep", {
		"forpnpcs/dog/npc_dog_foot_1.wav",
		"forpnpcs/dog/npc_dog_foot_2.wav",
		"forpnpcs/dog/npc_dog_foot_3.wav",
		"forpnpcs/dog/npc_dog_foot_04.wav",
		"forpnpcs/dog/npc_dog_foot_05.wav",
		"forpnpcs/dog/npc_dog_foot_06.wav",
	})
end

function ENT:HandleAnimEvent(event, eventTime, cycle, type, options)
	if (options == "event_emit Foot") then
		return self:HandleAnimEventFootsteps(event, eventTime, cycle, type, options)
	end

	if (options == "event_play SitUp") then
		self:SpeakFromTypedVoiceSet("Chase", 5)
		return true
	end

	-- print("Unhandled animation event", event, eventTime, cycle, type, options)
end

function ENT:HandleAnimEventFootsteps(event, eventTime, cycle, type, options)
	local sound = "Footstep"

	if (self:HasTypedVoiceSet(sound)) then
		self:SpeakFromTypedVoiceSet(sound, nil, nil, 0.2)
		return true
	end
end

function ENT:HandleAnimEventAttack(event, eventTime, cycle, type, options)
	-- Only play the monster attack, we play attack sounds when the attack is performed
	self:SpeakFromTypedVoiceSet("Attack", 5)
	return true
end
