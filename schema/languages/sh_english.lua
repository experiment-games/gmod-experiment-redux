LANGUAGE = {
	schemaName = "Experiment Redux",

	theBusiness = "The Business",
	missionTracker = "Mission Tracker",

	optShowTutorial = "Show Tutorial",
	optdShowTutorial = "Show the tutorial hints, intended for new players.",
	optAccessibilityFont = "Enable more readable font",
	optdAccessibilityFont =
	"Enables a more readable font for those who have trouble reading the default font.",
	optAccessibilityFontScale = "Font scaling",
	optdAccessibilityFontScale = "Scales the font to be larger for those who think it's too big or small.",

	random = "Random",
	attribPointsDesc =
	"These enhance your character's abilities. You get %d points to distribute now and can train to get more later.",
	attribPointsHint = "Hover over an attribute to see what it affects.",
	dTitleOwned = "Owned Door",
	dHintManage = "Press %s to manage doors.",
	pickupProtector = "Pick Up Door Protector",
	pickupProtectorNotAllowed = "Cannot pick up the door protector because you are not the owner of the door.",

	disconnectPenaltyAllItems = "Disconnecting now will result in you losing all your inventory items.",
	disconnectPenalty = "Disconnecting now will result in you possibly losing some of your inventory items.",

	achievements = "Achievements",
	alliance = "Alliance",
	alliances = "Alliances",
	buffs = "Nano Buffs",
	perks = "Perks",
	scoreboard = "Player List",
	skills = "Attributes",
	chooseSkills = "Distribute your attribute points.",

	categories = "Categories",
	searchResults = "Search Results",
	noSearchResults = "No search results found.",
	searchClear = "Clear search",
	filter = "Filter",
	wallet = "Wallet",
	confirmPurchase = "Do you want to purchase this item for %s?",
	confirmPurchaseShipment = "Do you want to purchase this shipment of %s items for %s?",
	completePurchase = "Purchase",

	grenades = "Grenades",
	income = "Income",
	moderation = "Moderation",
	scavenging = "Scavenging",

	noBuffs = "No active nano buffs.",

	upgrade = "Upgrade '%s' (-%s)",
	withdraw = "Withdraw (+%s)",
	generatorOwnerName = "%s's Generator",
	generatorOwnerSelf = "Your Generator",

	generator = "Generator",
	generatorDesc = "A generator that produces energy.",
	generatorHealth = "Health: %s",
	generatorPower = "Power: ",

	generatorRecharge = "Recharge",
	generatorRecharged = "You have successfully recharged the generator with %d scrap.",

	pickup = "Pick Up",
	pickingUpGenerator = "Picking up generator...",

	turnOn = "Turn On",
	turnOff = "Turn Off",

	frequency = "Frequency: %s",

	stationaryRadio = "Stationary Radio",
	radioTurnedOn = "Turned On",
	radioTurnedOff = "Turned Off",
	setFrequency = "Set Frequency",
	setFrequencyDesc = "Enter the frequency you would like to set this radio to.",
	radioNoLongerThere = "The radio is no longer there.",

	plyNotValid = "You are not looking at a valid character!",

	tying = "Tying...",
	unTying = "Untying...",
	untie = "Untie",
	searchTied = "Search",
	isTied = "Tied",
	fTiedUp = "You have been tied up.",
	fBeingTied = "You are being tied up.",
	tiedUp = "They have been tied up.",
	fUntied = "You have been untied.",
	beingTied = "They are being tied up.",
	beingUntied = "They are being untied.",

	tiedBreakFreeStart = "Press %s to attempt to break free.",
	tiedBreakingFree = "Struggling to break free.",
	tiedBreakingFreeMe = "starts struggling to break free from their restraints...",

	chloroforming = "Chloroforming...",
	fBeingChloroformed = "You are being chloroformed.",
	beingChloroformed = "They are being chloroformed.",
	fChloroformed = "You have been chloroformed.",
	chloroformed = "They have been chloroformed.",

	searchCorpse = "Search corpse",
	searchingCorpse = "Searching corpse...",
	resurrectingCorpse = "Resurrecting corpse...",
	corpseOwnerName = "Corpse of %s",
	corpseOwnerSelf = "Your Corpse",
	corpseDeceased = "Deceased",

	mutilateCorpse = "Mutilate corpse",
	mutilatingCorpse = "Mutilating corpse...",
	mutilatedCorpse = "You have mutilated the corpse.",

	radioNotOn = "Your radio isn't on!",
	radioRequired = "You need a radio to do this.",
	radioAlreadyOn = "You already have a radio that is turned on!",

	economy = "Economy",

	broadcaster = "Broadcaster",
	broadcasterBroadcasting = "Broadcasting...",
	broadcasterTurnedOff = "Turned Off...",

	chatRadioing = "Radioing...",

	rareItem = "Rare Item",

	cashback = "Cashback",
	cashbackConfirmation = "Are you sure you want to sell this item for %s?",

	bloodBondRequest = "Request Blood Bond",
	bloodBondRequestSent = "You have sent a blood bond request to %s.",
	bloodBondRequested = "%s has requested a blood bond with you.",
	bloodBondAccept = "Accept Blood Bond",
	bloodBondActivated =
	"You have blood bonded with %s. You can't hurt each other. When you're near them your generators output 10%% more.",
	bloodBondCannotTie = "You can't tie someone you're blood bonded with.",
	bloodBondCannotChloroform = "You can't chloroform someone you're blood bonded with.",
	bloodBondCannotMutilate = "You can't mutilate someone you're blood bonded with.",

	--[[
		Bind button names
		Source: https://developer.valvesoftware.com/wiki/Bind#Special_Keys
	]]
	-- System Commands
	bind_f1 = "F1",
	bind_f2 = "F2",
	bind_f3 = "F3",
	bind_f4 = "F4",
	bind_f5 = "F5",
	bind_f6 = "F6",
	bind_f7 = "F7",
	bind_f8 = "F8",
	bind_f9 = "F9",
	bind_f10 = "F10",
	bind_f11 = "F11",
	bind_f12 = "F12",
	bind_escape = "Escape",
	bind_tab = "Tab",
	bind_capslock = "Caps Lock",
	bind_shift = "Left Shift",
	bind_rshift = "Right Shift",
	bind_ctrl = "Left Ctrl",
	bind_rctrl = "Right Ctrl",
	bind_alt = "Left Alt",
	bind_ralt = "Right Alt",
	bind_space = "Spacebar",
	bind_backspace = "Backspace",
	bind_enter = "Enter",
	bind_semicolon = "Semicolon",
	bind_lwin = "Left Win",
	bind_rwin = "Right Win",
	bind_apps = "Menu",
	bind_numlock = "Num Lock",
	bind_scrolllock = "Scroll Lock",

	-- Navigation Keys
	bind_uparrow = "Up Arrow",
	bind_downarrow = "Down Arrow",
	bind_leftarrow = "Left Arrow",
	bind_rightarrow = "Right Arrow",
	bind_ins = "Insert",
	bind_del = "Delete",
	bind_pgdn = "Page Down",
	bind_pgup = "Page Up",
	bind_home = "Home",
	bind_end = "End",
	bind_pause = "Pause/Break",

	-- Number Pad
	bind_kp_end = "Keypad 1",
	bind_kp_downarrow = "Keypad 2",
	bind_kp_pgdn = "Keypad 3",
	bind_kp_leftarrow = "Keypad 4",
	bind_kp_5 = "Keypad 5",
	bind_kp_rightarrow = "Keypad 6",
	bind_kp_home = "Keypad 7",
	bind_kp_uparrow = "Keypad 8",
	bind_kp_pgup = "Keypad 9",
	bind_kp_enter = "Keypad Enter",
	bind_kp_ins = "Keypad 0",
	bind_kp_del = "Keypad .",
	bind_kp_slash = "Keypad /",
	bind_kp_multiply = "Keypad *",
	bind_kp_minus = "Keypad -",
	bind_kp_plus = "Keypad +",

	-- Mouse Buttons
	bind_mwheeldown = "Scroll Mousewheel Down",
	bind_mwheelup = "Scroll Mousewheel Up",
	bind_mouse1 = "Left Mouse Button",
	bind_mouse2 = "Right Mouse Button",
	bind_mouse3 = "Middle Mouse Button",
	bind_mouse4 = "Mouse Button 4",
	bind_mouse5 = "Mouse Button 5",
}
