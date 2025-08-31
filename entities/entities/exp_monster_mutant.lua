DEFINE_BASECLASS("exp_monster_base")

if (SERVER) then
	AddCSLuaFile()
end

ENT.Base = "exp_monster_base"
ENT.PrintName = "Experiment Mutant"
ENT.Author = "Experiment Redux"
ENT.Category = "Experiment Redux"

ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:GetDisplayName()
	return "Mutant"
end

if (not SERVER) then
	MONSTER_SCIENTIST_MODELS = {
		"models/player/apsci_cohrt.mdl",
		"models/player/apsci_male_01.mdl",
		"models/player/apsci_male_02.mdl",
		"models/player/apsci_male_03.mdl",
		"models/player/apsci_male_04.mdl",
		"models/player/apsci_male_05.mdl",
		"models/player/apsci_male_06.mdl",
		"models/player/apsci_male_07.mdl",
		"models/player/apsci_male_08.mdl",
		"models/player/apsci_male_09.mdl",
	}

	function ENT:GetPacData()
		local headBoneTransform = nil
		local crookedHead = {
			["children"] = {},
			["self"] = {
				["FollowAnglesOnly"] = false,
				["DrawOrder"] = 0,
				["InvertHideMesh"] = false,
				["TargetEntityUID"] = "",
				["AimPartName"] = "",
				["FollowPartUID"] = "",
				["Bone"] = "head",
				["ScaleChildren"] = false,
				["UniqueID"] = pac.Hash(),
				["MoveChildrenToOrigin"] = false,
				["Position"] = Vector(0, 0, 0),
				["AimPartUID"] = "",
				["Angles"] = Angle(0, 0, 0),
				["Hide"] = false,
				["Name"] = "",
				["Scale"] = Vector(1, 1, 1),
				["EditorExpand"] = false,
				["ClassName"] = "bone3",
				["Size"] = 1,
				["PositionOffset"] = Vector(0, 0, 0),
				["IsDisturbing"] = false,
				["AngleOffset"] = Angle(math.Rand(-64, 64), math.Rand(-8, 8), math.Rand(-8, 8)),
				["EyeAngles"] = false,
				["HideMesh"] = false,
			}
		}

		self.expCharacterModel = self.expCharacterModel
			or MONSTER_SCIENTIST_MODELS[math.random(#MONSTER_SCIENTIST_MODELS)]

		if (self.expHasNoHead or math.random() < 0.3) then
			self.expHasNoHead = true

			headBoneTransform = {
				["children"] = {
				},
				["self"] = {
					["FollowAnglesOnly"] = false,
					["DrawOrder"] = 0,
					["InvertHideMesh"] = false,
					["TargetEntityUID"] = "",
					["AimPartName"] = "",
					["FollowPartUID"] = "",
					["Bone"] = "head",
					["ScaleChildren"] = true,
					["UniqueID"] = pac.Hash(),
					["MoveChildrenToOrigin"] = false,
					["Position"] = Vector(0, 0, 0),
					["AimPartUID"] = "",
					["Angles"] = Angle(0, 0, 0),
					["Hide"] = false,
					["Name"] = "",
					["Scale"] = Vector(0, 0, 0),
					["EditorExpand"] = false,
					["ClassName"] = "bone3",
					["Size"] = 1,
					["PositionOffset"] = Vector(0, 0, 0),
					["IsDisturbing"] = false,
					["AngleOffset"] = Angle(0, 0, 0),
					["EyeAngles"] = false,
					["HideMesh"] = false,
				},
			}
		end

		local wonkyArmChildren = nil
		local wonkyArmReplacement = nil

		if (not self.expHasNoHead and self.expHasWonkyArm or math.random() < 0.4) then
			self.expHasWonkyArm = true

			wonkyArmChildren = {
				[1] = {
					["children"] = {
					},
					["self"] = {
						["FollowAnglesOnly"] = false,
						["DrawOrder"] = 0,
						["InvertHideMesh"] = false,
						["TargetEntityUID"] = "",
						["AimPartName"] = "",
						["FollowPartUID"] = "",
						["Bone"] = "left elbow",
						["ScaleChildren"] = false,
						["UniqueID"] = pac.Hash(),
						["MoveChildrenToOrigin"] = false,
						["Position"] = Vector(0, 0, 0),
						["AimPartUID"] = "",
						["Angles"] = Angle(0, 0, 0),
						["Hide"] = false,
						["Name"] = "",
						["Scale"] = Vector(1, 1, 1),
						["EditorExpand"] = true,
						["ClassName"] = "bone3",
						["Size"] = 0,
						["PositionOffset"] = Vector(0, 0, 0),
						["IsDisturbing"] = false,
						["AngleOffset"] = Angle(0, 0, 0),
						["EyeAngles"] = false,
						["HideMesh"] = true,
					},
				},
				[2] = {
					["children"] = {
					},
					["self"] = {
						["FollowAnglesOnly"] = false,
						["DrawOrder"] = 0,
						["InvertHideMesh"] = false,
						["TargetEntityUID"] = "",
						["AimPartName"] = "",
						["FollowPartUID"] = "",
						["Bone"] = "left wrist",
						["ScaleChildren"] = false,
						["UniqueID"] = pac.Hash(),
						["MoveChildrenToOrigin"] = false,
						["Position"] = Vector(0, 0, 0),
						["AimPartUID"] = "",
						["Angles"] = Angle(0, 0, 0),
						["Hide"] = false,
						["Name"] = "",
						["Scale"] = Vector(1, 1, 1),
						["EditorExpand"] = true,
						["ClassName"] = "bone3",
						["Size"] = 1,
						["PositionOffset"] = Vector(0, 0, 0),
						["IsDisturbing"] = false,
						["AngleOffset"] = Angle(0, 0, 0),
						["EyeAngles"] = false,
						["HideMesh"] = true,
					},
				},
				[3] = {
					["children"] = {
					},
					["self"] = {
						["FollowAnglesOnly"] = false,
						["DrawOrder"] = 0,
						["InvertHideMesh"] = false,
						["TargetEntityUID"] = "",
						["AimPartName"] = "",
						["FollowPartUID"] = "",
						["Bone"] = "left forearm",
						["ScaleChildren"] = false,
						["UniqueID"] = pac.Hash(),
						["MoveChildrenToOrigin"] = false,
						["Position"] = Vector(0, 0, 0),
						["AimPartUID"] = "",
						["Angles"] = Angle(0, 0, 0),
						["Hide"] = false,
						["Name"] = "",
						["Scale"] = Vector(1, 1, 1),
						["EditorExpand"] = false,
						["ClassName"] = "bone3",
						["Size"] = 0,
						["PositionOffset"] = Vector(0, 0, 0),
						["IsDisturbing"] = false,
						["AngleOffset"] = Angle(0, 0, 0),
						["EyeAngles"] = false,
						["HideMesh"] = true,
					},
				},
				[4] = {
					["children"] = {
					},
					["self"] = {
						["FollowAnglesOnly"] = false,
						["DrawOrder"] = 0,
						["InvertHideMesh"] = false,
						["TargetEntityUID"] = "",
						["AimPartName"] = "",
						["FollowPartUID"] = "",
						["Bone"] = "left bicep",
						["ScaleChildren"] = false,
						["UniqueID"] = pac.Hash(),
						["MoveChildrenToOrigin"] = false,
						["Position"] = Vector(0, 0, 0),
						["AimPartUID"] = "",
						["Angles"] = Angle(0, 0, 0),
						["Hide"] = false,
						["Name"] = "",
						["Scale"] = Vector(1, 1, 1),
						["EditorExpand"] = true,
						["ClassName"] = "bone3",
						["Size"] = 0,
						["PositionOffset"] = Vector(0, 0, 0),
						["IsDisturbing"] = false,
						["AngleOffset"] = Angle(0, 0, 0),
						["EyeAngles"] = false,
						["HideMesh"] = true,
					},
				},
				[5] = {
					["children"] = {
					},
					["self"] = {
						["FollowAnglesOnly"] = false,
						["DrawOrder"] = 0,
						["InvertHideMesh"] = false,
						["TargetEntityUID"] = "",
						["AimPartName"] = "",
						["FollowPartUID"] = "",
						["Bone"] = "left hand",
						["ScaleChildren"] = true,
						["UniqueID"] = pac.Hash(),
						["MoveChildrenToOrigin"] = false,
						["Position"] = Vector(0, 0, 0),
						["AimPartUID"] = "",
						["Angles"] = Angle(0, 0, 0),
						["Hide"] = false,
						["Name"] = "",
						["Scale"] = Vector(1, 1, 1),
						["EditorExpand"] = false,
						["ClassName"] = "bone3",
						["Size"] = 0,
						["PositionOffset"] = Vector(0, 0, 0),
						["IsDisturbing"] = false,
						["AngleOffset"] = Angle(0, 0, 0),
						["EyeAngles"] = false,
						["HideMesh"] = true,
					},
				},
				[6] = crookedHead
			}

			wonkyArmReplacement = {
				["children"] = {
					[1] = {
						["children"] = {
						},
						["self"] = {
							["FollowAnglesOnly"] = false,
							["DrawOrder"] = 0,
							["InvertHideMesh"] = false,
							["TargetEntityUID"] = "",
							["AimPartName"] = "",
							["FollowPartUID"] = "",
							["Bone"] = "spine 2",
							["ScaleChildren"] = false,
							["UniqueID"] = pac.Hash(),
							["MoveChildrenToOrigin"] = false,
							["Position"] = Vector(0, 0, 0),
							["AimPartUID"] = "",
							["Angles"] = Angle(0, 0, 0),
							["Hide"] = false,
							["Name"] = "",
							["Scale"] = Vector(1, 1, 1),
							["EditorExpand"] = false,
							["ClassName"] = "bone3",
							["Size"] = 0.725,
							["PositionOffset"] = Vector(-0.69999998807907, -1.7000000476837, 0),
							["IsDisturbing"] = false,
							["AngleOffset"] = Angle(0, 0, 0),
							["EyeAngles"] = false,
							["HideMesh"] = false,
						},
					},
					[2] = {
						["children"] = {
						},
						["self"] = {
							["FollowAnglesOnly"] = false,
							["DrawOrder"] = 0,
							["InvertHideMesh"] = false,
							["TargetEntityUID"] = "",
							["AimPartName"] = "",
							["FollowPartUID"] = "",
							["Bone"] = "left forearm",
							["ScaleChildren"] = false,
							["UniqueID"] = pac.Hash(),
							["MoveChildrenToOrigin"] = false,
							["Position"] = Vector(0, 0, 0),
							["AimPartUID"] = "",
							["Angles"] = Angle(0, 0, 0),
							["Hide"] = false,
							["Name"] = "",
							["Scale"] = Vector(1, 1, 1),
							["EditorExpand"] = false,
							["ClassName"] = "bone3",
							["Size"] = 2.175,
							["PositionOffset"] = Vector(0, 0, 0),
							["IsDisturbing"] = false,
							["AngleOffset"] = Angle(0, 0, 0),
							["EyeAngles"] = false,
							["HideMesh"] = false,
						},
					},
					[3] = {
						["children"] = {
						},
						["self"] = {
							["FollowAnglesOnly"] = false,
							["DrawOrder"] = 0,
							["InvertHideMesh"] = false,
							["TargetEntityUID"] = "",
							["AimPartName"] = "",
							["FollowPartUID"] = "",
							["Bone"] = "left clavicle",
							["ScaleChildren"] = false,
							["UniqueID"] = pac.Hash(),
							["MoveChildrenToOrigin"] = false,
							["Position"] = Vector(0, 0, 0),
							["AimPartUID"] = "",
							["Angles"] = Angle(0, 0, 0),
							["Hide"] = false,
							["Name"] = "",
							["Scale"] = Vector(1, 1, 1),
							["EditorExpand"] = false,
							["ClassName"] = "bone3",
							["Size"] = 1,
							["PositionOffset"] = Vector(0, 0, 0),
							["IsDisturbing"] = false,
							["AngleOffset"] = Angle(0, 0, 0),
							["EyeAngles"] = false,
							["HideMesh"] = false,
						},
					},
					[4] = {
						["children"] = {
						},
						["self"] = {
							["FollowAnglesOnly"] = false,
							["DrawOrder"] = 0,
							["InvertHideMesh"] = false,
							["TargetEntityUID"] = "",
							["AimPartName"] = "",
							["FollowPartUID"] = "",
							["Bone"] = "spine 2",
							["ScaleChildren"] = false,
							["UniqueID"] = pac.Hash(),
							["MoveChildrenToOrigin"] = false,
							["Position"] = Vector(0.0001220703125, 6.103515625e-05, -4.056396484375),
							["AimPartUID"] = "",
							["Angles"] = Angle(0, 0, 0),
							["Hide"] = false,
							["Name"] = "",
							["Scale"] = Vector(1, 1, 1),
							["EditorExpand"] = false,
							["ClassName"] = "bone3",
							["Size"] = 1,
							["PositionOffset"] = Vector(3.9000000953674, 4.5, 11.60000038147),
							["IsDisturbing"] = false,
							["AngleOffset"] = Angle(-21.200000762939, 1.8999999761581, 0),
							["EyeAngles"] = false,
							["HideMesh"] = false,
						},
					},
				},
				["self"] = {
					["Skin"] = 0,
					["UniqueID"] = pac.Hash(),
					["NoLighting"] = false,
					["AimPartName"] = "",
					["IgnoreZ"] = false,
					["AimPartUID"] = "",
					["Materials"] = "",
					["Name"] = "",
					["LevelOfDetail"] = 0,
					["NoTextureFiltering"] = false,
					["PositionOffset"] = Vector(0, 0, 0),
					["IsDisturbing"] = false,
					["EyeAngles"] = false,
					["DrawOrder"] = 0,
					["TargetEntityUID"] = "",
					["Alpha"] = 1,
					["Material"] = "",
					["Invert"] = false,
					["ForceObjUrl"] = false,
					["Bone"] = "head",
					["Angles"] = Angle(0, 0, 0),
					["AngleOffset"] = Angle(0, 0, 0),
					["BoneMerge"] = true,
					["Color"] = Vector(1, 1, 1),
					["Position"] = Vector(-2.288818359375e-05, 0, 0),
					["ClassName"] = "model2",
					["Brightness"] = 1,
					["Hide"] = false,
					["NoCulling"] = false,
					["Scale"] = Vector(1, 1, 1),
					["LegacyTransform"] = false,
					["EditorExpand"] = true,
					["Size"] = 1,
					["ModelModifiers"] = "",
					["Translucent"] = false,
					["BlendMode"] = "",
					["EyeTargetUID"] = "",
					["Model"] = "models/gibs/fast_zombie_torso.mdl",
				},
			}
		else
			headBoneTransform = crookedHead
		end

		return {
			[1] = {
				["children"] = {
					[1] = {
						["children"] = wonkyArmChildren or {
							[1] = headBoneTransform
						},
						["self"] = {
							["Skin"] = 0,
							["UniqueID"] = pac.Hash(),
							["NoLighting"] = false,
							["AimPartName"] = "",
							["IgnoreZ"] = false,
							["AimPartUID"] = "",
							["Materials"] = "models/experiment-redux/characters/guardian_scientist_sheet_bloody" ..
								math.random(1, 3) .. ";;;;;;;;",
							["Name"] = "replacement",
							["LevelOfDetail"] = 0,
							["NoTextureFiltering"] = false,
							["PositionOffset"] = Vector(0, 0, 0),
							["IsDisturbing"] = false,
							["EyeAngles"] = false,
							["DrawOrder"] = -0.1,
							["TargetEntityUID"] = "",
							["Alpha"] = 1,
							["Material"] = "",
							["Invert"] = false,
							["ForceObjUrl"] = false,
							["Bone"] = "head",
							["Angles"] = Angle(0, 0, 0),
							["AngleOffset"] = Angle(-0.10000000149012, 0, 0),
							["BoneMerge"] = true,
							["Color"] = Vector(1, 1, 1),
							["Position"] = Vector(-0.0001220703125, -25.66455078125, -3.0517578125e-05),
							["ClassName"] = "model2",
							["Brightness"] = 1,
							["Hide"] = false,
							["NoCulling"] = false,
							["Scale"] = Vector(0.89999997615814, 1, 1),
							["LegacyTransform"] = false,
							["EditorExpand"] = true,
							["Size"] = 1,
							["ModelModifiers"] = "",
							["Translucent"] = false,
							["BlendMode"] = "",
							["EyeTargetUID"] = "",
							["Model"] = self.expCharacterModel,
						},
					},
					[2] = wonkyArmReplacement,
				},
				["self"] = {
					["DrawOrder"] = 0,
					["UniqueID"] = pac.Hash(),
					["Hide"] = false,
					["TargetEntityUID"] = "",
					["EditorExpand"] = true,
					["OwnerName"] = "self",
					["IsDisturbing"] = false,
					["Name"] = "my outfit",
					["Duplicate"] = false,
					["ClassName"] = "group",
				},
			},
		}
	end

	return
end

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:SetModel("models/zombie/classic.mdl")
	self:SetHealth(900)
	self:SetMaxHealth(900)
	self:Activate()

	self:SetAttackMeleeRange(45) -- Must be right up against the target, otherwise their hands wont reach the target

	-- Override target priorities if needed
	self.customTargetPriorities = {
		player = 100,
		door = 30, -- Lower than default since mutants are slower
		npc = 20
	}
end

-- Override attack schedules for different behavior
function ENT:SetupSchedules()
	BaseClass.SetupSchedules(self)

	-- Add a heavy attack for mutants
	local heavyAttack = ai_schedule.New("expHeavyAttack")
	heavyAttack:EngTask("TASK_STOP_MOVING", 0)
	heavyAttack:EngTask("TASK_FACE_ENEMY", 0)
	heavyAttack:EngTask("TASK_MELEE_ATTACK1", 0)
	heavyAttack:EngTask("TASK_WAIT_FOR_MOVEMENT", 0)
	heavyAttack:EngTask("TASK_WAIT", 1.0) -- Longer recovery
	heavyAttack.expAttackData = {
		range = self:GetAttackMeleeRange(),
		damage = 25, -- More damage
		damageType = DMG_SLASH,
		force = 400, -- More knockback
		interval = 1.5 -- Longer cooldown
	}

	self.expSchedules.Attacks[#self.expSchedules.Attacks + 1] = heavyAttack

	self.expHeavyAttack = heavyAttack
end

-- Override target priority system for this monster type
function ENT:GetTargetPriority(entity)
	if self.customTargetPriorities then
		if entity:IsPlayer() then
			return self.customTargetPriorities.player or 100
		elseif entity:IsDoor() then
			return self.customTargetPriorities.door or 50
		else
			return self.customTargetPriorities.npc or 10
		end
	end

	return BaseClass.GetTargetPriority(self, entity)
end

function ENT:IsValidTarget(entity)
	-- Call base validation first
	if not BaseClass.IsValidTarget(self, entity) then
		return false
	end

	-- Add custom logic for mutants
	if entity:IsPlayer() then
		-- Mutants are more aggressive toward injured players
		local healthRatio = entity:Health() / entity:GetMaxHealth()
		if healthRatio < 0.5 then
			-- Make sure we prioritize injured players
			return true
		end
	end

	return true
end

function ENT:GetAttackSchedule(target)
	-- Mutants use heavy attacks on healthy players
	if target:IsPlayer() and target:Health() > target:GetMaxHealth() * 0.7 then
		return self.expHeavyAttack
	end

	-- Fall back to random attack
	return BaseClass.GetAttackSchedule(self, target)
end

function ENT:SetupVoiceSounds()
	self:SetTypedVoiceSet("Idle", {
		"Zombie.Idle"
	})

	self:SetTypedVoiceSet("Pain", {
		"Zombie.Pain"
	})

	self:SetTypedVoiceSet("Die", {
		"Zombie.Die"
	})

	self:SetTypedVoiceSet("Alert", {
		"Zombie.Alert"
	})

	self:SetTypedVoiceSet("Chase", {
		-- "npc/zombie/moan_loop1.wav",
	})

	self:SetTypedVoiceSet("Lost", {
		-- "npc/zombie/zo_attack1.wav"
	})

	self:SetTypedVoiceSet("Attack", {
		"Zombie.Attack"
	})

	self:SetTypedVoiceSet("AttackMiss", {
		"Zombie.AttackMiss"
	})

	self:SetTypedVoiceSet("AttackHit", {
		"Zombie.AttackHit"
	})

	self:SetTypedVoiceSet("AttackHitDoor", {
		"NPC_BaseZombie.PoundDoor"
	})

	self:SetTypedVoiceSet("Victory", {
		-- "npc/fast_zombie/leap1.wav"
	})

	self:SetTypedVoiceSet("ScuffLeft", {
		"Zombie.ScuffLeft"
	})

	self:SetTypedVoiceSet("ScuffRight", {
		"Zombie.ScuffRight"
	})

	self:SetTypedVoiceSet("FootstepLeft", {
		"Zombie.FootstepLeft"
	})

	self:SetTypedVoiceSet("FootstepRight", {
		"Zombie.FootstepRight"
	})
end

function ENT:HandleAnimEvent(event, eventTime, cycle, type, options)
	local isFootstep = event == self:AnimEventID("AE_ZOMBIE_STEP_RIGHT") or
		event == self:AnimEventID("AE_ZOMBIE_STEP_LEFT")

	if (isFootstep) then
		return self:HandleAnimEventFootsteps(event, eventTime, cycle, type, options)
	end

	if (event == self:AnimEventID("AE_ZOMBIE_SCUFF_LEFT")) then
		self:SpeakFromTypedVoiceSet("ScuffLeft")
		return true
	elseif (event == self:AnimEventID("AE_ZOMBIE_SCUFF_RIGHT")) then
		self:SpeakFromTypedVoiceSet("ScuffRight")
		return true
	end

	local isAttack = event == self:AnimEventID("AE_ZOMBIE_ATTACK_RIGHT")
		or event == self:AnimEventID("AE_ZOMBIE_ATTACK_LEFT")
		or event == self:AnimEventID("AE_ZOMBIE_ATTACK_BOTH")

	if (isAttack) then
		return self:HandleAnimEventAttack(event, eventTime, cycle, type, options)
	end

	if (event == self:AnimEventID("AE_ZOMBIE_ATTACK_SCREAM")) then
		self:SpeakFromTypedVoiceSet("Alert", 5)
		return true
	end

	-- print(self, "Unhandled animation event", event, eventTime, cycle, type, options)
end

function ENT:HandleAnimEventFootsteps(event, eventTime, cycle, type, options)
	local footstepType = "Footstep"
	local footstepSide = event == self:AnimEventID("AE_ZOMBIE_STEP_RIGHT") and "Right" or "Left"
	local sound = footstepType .. footstepSide

	if (self:HasTypedVoiceSet(sound)) then
		self:SpeakFromTypedVoiceSet(sound)
		return true
	end
end

function ENT:HandleAnimEventAttack(event, eventTime, cycle, type, options)
	-- Only play the monster attack, we play attack sounds when the attack is performed
	self:SpeakFromTypedVoiceSet("Attack", 5)
	return true
end
