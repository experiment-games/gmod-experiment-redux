-- TODO: For some reason the `.loco` member is not initialized if we declare this entity
-- TODO: inside a plugin.
ENT.Base = "base_nextbot"
ENT.Spawnable = true

ENT.BotState = {
	IDLE = "idle",
	GOING_HOME = "going_home",
	AT_HOME = "at_home",
	GOING_TO_TASK = "going_to_task",
	AT_TASK = "at_task",
	COMBAT = "combat",
	RETURNING_HOME = "returning_home"
}

ENT.CombatMode = {
	DEFENSIVE = "defensive",
	AGGRESSIVE = "aggressive"
}

ENT.TaskUrgency = {
	LOW = "low",
	NORMAL = "normal",
	HIGH = "high",
	URGENT = "urgent"
}

ENT.AnimationState = {
	IDLE = "idle",
	WALKING = "walking",
	RUNNING = "running",
	JUMPING = "jumping",
	ATTACKING = "attacking",
	ALERT = "alert"
}

ENT.AnimationRequest = {
	NONE = "none",
	ATTACK = "attack",
	JUMP = "jump",
	SEQUENCE = "sequence"
}

ENT.WeaponState = {
	UNARMED = "unarmed",
	ARMED = "armed",
	SWITCHING = "switching"
}
