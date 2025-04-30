
local INFORGED_TUNING = {

	INFORGE_INFERNALSTAFF = {
		DAMAGE          = 33,
		ALT_DAMAGE      = 200,
		ALT_CENTER_MULT = 0.25, --Damage increases as the targets get closer to the center
		ALT_RADIUS      = 4,--4.1, TODO double check then remove this comment
		COOLDOWN        = 24,
		SPEEDMULT       = 1.1,
		SPELL_TYPES     = {"damage",},
		DAMAGE_TYPE     = 2, -- Magic
		ALT_DAMAGE_TYPE = 2,
		STIMULI         = "fire",
		ALT_STIMULI     = "explosive",
		ITEM_TYPE       = "staves",
		ENTITY_TYPE     = "WEAPONS",
		ATTACK_RANGE    = 13,
		HIT_RANGE       = 20,
		WEIGHT          = 3,
		RET = {
			DATA   = {"aoehostiletarget", 0.7},
			TYPE   = "aoe",
			LENGTH = 7,
		},
	},
	
	INFORGE_BLACKSMITHSEDGE = {
		DAMAGE           = 30,
		HELMSPLIT_DAMAGE = 100, -- this is multiplied by the battlecry and any shieldbreak mult.
		PARRY_DURATION   = 10,
		COOLDOWN         = 12,
		DAMAGE_TYPE      = 1, -- Physical
		ITEM_TYPE        = "melees",
		ENTITY_TYPE      = "WEAPONS",
		WEIGHT           = 3,
		SPEEDMULT        = 1.2,
		MAX_HP           = 100,
		RET = {
			PREFAB      = "reticulearc",
			PING_PREFAB = "reticulearcping",
			TYPE        = "directional",
			LENGTH      = 6.5,
		},
	},

	ROACH_BEETLE = { 
		HEALTH        = 266,
		RUNSPEED      = 8,
		WALKSPEED     = 8, --This is for the placeholder, update this when final build is finished!
		DAMAGE        = 20,
		ATTACK_RANGE  = 2,
		HIT_RANGE     = 3,
		ATTACK_PERIOD = 2,
		ENTITY_TYPE   = "ENEMIES",
		WEIGHT        = 3,
		RADIUS        = 2,
		EXPLODE_DAMAGE= 266,
	},

	CH1_BOSS_BOARILLA = {
		HEALTH            = 20020,
		RUNSPEED          = 9, --Runner speed is 7.2 with +20 speed boost
		WALKSPEED         = 6,
		DAMAGE            = 150,
		ATTACK_RANGE      = 3,
		HIT_RANGE         = 3,
		AOE_HIT_RANGE     = 2.25, -- TODO used?
		FRONT_AOE_OFFSET  = 3,
		GUARD_TRIGGER_1   = 0.5,
		JUMP_ATTACK_RANGE = 8, -- TODO used?
		JUMP_HIT_RANGE    = 4, -- TODO used?
		ATTACK_PERIOD     = 3.33,
		SLAM_CD           = 10,
		SNIPER_DPS_CD     = 10,
		BATTLECRY_CD      = 20, -- TODO could be 10 or even 5 still hmmm
		FOSSIL_TIME       = 1, -- TODO adjust to real value
		ATTACK_KNOCKBACK  = 20, --was 25.
		ENTITY_TYPE       = "ENEMIES",
		WEIGHT            = 10,
	},
	
}

return INFORGED_TUNING
