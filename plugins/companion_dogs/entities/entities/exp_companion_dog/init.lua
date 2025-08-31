local PLUGIN = PLUGIN

include("shared.lua")
AddCSLuaFile("shared.lua")

DEFINE_BASECLASS("exp_companion_base")

function ENT:SetupAttackHandles()
	self:ClearAttackHandles()

	local headMuzzleBone = self:LookupBone("Bip01 Head Muzzle")

	if (headMuzzleBone) then
		self:CreateAttackHandle("head_muzzle", headMuzzleBone, Vector(0, 0, 0), 8)
	end
end

function ENT:SetupVoiceSounds()
	self:SetTypedVoiceSet("Idle", {
		"npc/dog/dog_idle_pant01.mp3",
		"npc/dog/dog_idle_pant02.mp3",
		"npc/dog/dog_idle_pant03.mp3",
		"npc/dog/dog_idle_pant04.mp3",
	})
	self:SetTypedVoiceSet("Pain", {
		"npc/dog/dog_injured01.mp3",
		"npc/dog/dog_injured02.mp3",
		"npc/dog/dog_injured03.mp3",
		"npc/dog/dog_injured04.mp3",
	})
	self:SetTypedVoiceSet("Die", {
		"npc/dog/dog_death01.mp3",
		"npc/dog/dog_death02.mp3",
		"npc/dog/dog_death03.mp3",
		"npc/dog/dog_death04.mp3",
	})
	self:SetTypedVoiceSet("Alert", {
		"npc/dog/dog_growl01.mp3",
		"npc/dog/dog_growl02.mp3",
		"npc/dog/dog_growl03.mp3",
		"npc/dog/dog_growl04.mp3",
	})
	self:SetTypedVoiceSet("Chase", {
		"npc/dog/dog_barkrun01.mp3",
		"npc/dog/dog_barkrun02.mp3",
		"npc/dog/dog_barkrun03.mp3",
		"npc/dog/dog_barkrun04.mp3",
	})
	self:SetTypedVoiceSet("Lost", {
		"npc/dog/dog_bark01.mp3",
		"npc/dog/dog_bark02.mp3",
		"npc/dog/dog_bark03.mp3",
	})
	self:SetTypedVoiceSet("Attack", {
		"npc/dog/dog_attackforward01.mp3",
		"npc/dog/dog_attackforward02.mp3",
	})
	self:SetTypedVoiceSet("AttackMiss", {
		"npc/dog/dog_attackforward05.mp3",
		"npc/dog/dog_attackforward06.mp3",
	})
	self:SetTypedVoiceSet("AttackHit", {
		"npc/dog/dog_attackforward03.mp3",
		"npc/dog/dog_attackforward04.mp3",
	})

	self:SetTypedVoiceSet("Victory", {
		"npc/dog/dog_bark04.mp3"
	})
	self:SetTypedVoiceSet("Footstep", {
		"npc/dog/foot/dog_foot01.mp3",
		"npc/dog/foot/dog_foot02.mp3",
		"npc/dog/foot/dog_foot03.mp3",
		"npc/dog/foot/dog_foot04.mp3",
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
