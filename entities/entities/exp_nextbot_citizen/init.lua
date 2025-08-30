AddCSLuaFile("shared.lua")
include("shared.lua")

include("sv_ai.lua")
include("sv_combat.lua")
include("sv_animation.lua")
include("sv_movement.lua")
include("sv_states.lua")

function ENT:Initialize()
	self:SetModel("models/hl2rp/citizens/male_02.mdl")

	-- Initialize all components
	self:InitializeAI()
	self:InitializeCombat()
	self:InitializeAnimation()
	self:InitializeMovement()
	self:InitializeStates()
end

function ENT:RunBehaviour()
	while (true) do
		self:UpdateAI()
		coroutine.wait(0.1)
	end
end

function ENT:BodyUpdate()
	self:UpdateAnimation()
	self:FrameAdvance()
end

function ENT:OnTakeDamage(damageInfo)
	self:HandleDamage(damageInfo)
end
