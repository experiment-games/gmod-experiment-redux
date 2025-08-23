local PLUGIN = PLUGIN
local BUFF = BUFF

BUFF.name = "Newbie"
BUFF.foregroundImage = {
	spritesheet = "experiment-redux/flatmsicons32.png",
	x = 14,
	y = 1,
	size = 32,
}
BUFF.durationInSeconds = 30 * 60
BUFF.persistThroughDeath = true
BUFF.attributeBoosts = {
	["endurance"] = 5,
}
BUFF.description = "You're a newbie, but you're learning quickly. Your endurance is temporarily boosted."
