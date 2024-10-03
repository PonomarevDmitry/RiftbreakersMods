return function()
    local rules = {}

	rules.maxObjectivesAtOnce = 2
	rules.eventsPerIdleState = 0
	rules.eventsPerPrepareState = 1 -- [0,1]
	rules.pauseAttacks = false
	rules.prepareAttacks = false

	rules.gameEvents = 
	{
		{ action = "new_objective", type = "POSITIVE", gameStates="IDLE|STREAMING", minEventLevel = 3 }, -- new_objective is only an option in the streaming mode; do not try to pass it as NO_STREAMING
		{ action = "change_time_of_day", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 3 },
		{ action = "add_resource", type = "POSITIVE", gameStates = "ATTACK|IDLE|STREAMING", minEventLevel = 1, basePercentage = 30 },
		{ action = "remove_resource", type = "NEGATIVE", gameStates = "ATTACK|IDLE|STREAMING", minEventLevel = 1, basePercentage = 20 },
		{ action = "stronger_attack", type = "NEGATIVE", gameStates = "ATTACK|STREAMING", minEventLevel = 1, amount = 2 },
		{ action = "cancel_the_attack", type = "POSITIVE", gameStates = "ATTACK|STREAMING", minEventLevel = 1 },
		{ action = "unlock_research", type = "POSITIVE", gameStates = "ATTACK|IDLE|STREAMING", minEventLevel = 1 },
		{ action = "full_ammo", type = "POSITIVE", gameStates = "ATTACK|STREAMING", minEventLevel = 2 },
		{ action = "remove_ammo", type = "NEGATIVE", gameStates = "ATTACK|STREAMING", minEventLevel = 2 },
		{ action = "boss_attack", type = "NEGATIVE", gameStates = "ATTACK|STREAMING", minEventLevel = 4 },
		{ action = "shegret_attack", type = "NEGATIVE", gameStates="IDLE|STREAMING", minEventLevel = 2, logicFile="logic/event/shegret_attack.logic", weight = 3 },
		{ action = "shegret_attack", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/event/shegret_attack.logic", weight = 3 },
		{ action = "cosmic_kermon_attack", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, maxEventLevel = 5, logicFile="logic/event/cosmic_kermon_attack.logic", weight = 3 },
		{ action = "cosmic_kermon_attack", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, maxEventLevel = 5, logicFile="logic/event/cosmic_kermon_attack.logic", weight = 3 },
		{ action = "cosmic_phirian_attack", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, maxEventLevel = 5, logicFile="logic/event/cosmic_phirian_attack.logic", weight = 3 },
		{ action = "cosmic_phirian_attack", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, maxEventLevel = 5, logicFile="logic/event/cosmic_phirian_attack.logic", weight = 3 },
		{ action = "spawn_invasion_easy", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/invasion_easy.logic", minTime = 30, maxTime = 60, weight = 0.5 },
		{ action = "spawn_invasion_easy", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/invasion_easy.logic", minTime = 30, maxTime = 60, weight = 0.5 },
		{ action = "spawn_comet_boss_cosmic_hedroner", type = "NEGATIVE", gameStates = "ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/event/comet_boss_cosmic_hedroner", minTime = 30, maxTime = 60, weight = 0.5 },
		{ action = "spawn_comet_boss_cosmic_hedroner", type = "NEGATIVE", gameStates = "IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/event/comet_boss_cosmic_hedroner", minTime = 30, maxTime = 60, weight = 0.5 },
		{ action = "spawn_cosmic_meteor_shower", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/comsic_meteor_shower.logic", minTime = 30, maxTime = 60, weight = 2 },
		{ action = "spawn_cosmic_meteor_shower", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/cosmic_meteor_shower.logic", minTime = 30, maxTime = 60, weight = 2 },
		{ action = "spawn_cosmic_creeper", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/cosmic_creeper.logic", minTime = 30, maxTime = 60, weight = 3 },
		{ action = "spawn_cosmic_creeper", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/cosmic_creeper.logic", minTime = 30, maxTime = 60, weight = 3 },
		{ action = "spawn_cosmic_tornado_near_player", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 1, maxEventLevel = 2, logicFile="logic/weather/cosmic_tornado_near_player.logic", weight = 0.5 },
		{ action = "spawn_cosmic_tornado_near_player", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 1, maxEventLevel = 2, logicFile="logic/weather/cosmic_tornado_near_player.logic", weight = 0.5 },
		{ action = "spawn_cosmic_tornado_near_base", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/cosmic_tornado_near_base.logic", minTime = 30, maxTime = 60, weight = 0.5 },
		{ action = "spawn_cosmic_tornado_near_base", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/cosmic_tornado_near_base.logic", minTime = 30, maxTime = 60, weight = 0.5 },
		{ action = "spawn_earthquake", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 3, logicFile="logic/weather/earthquake.logic", minTime = 60, maxTime = 60, weight = 0.5 },
		{ action = "spawn_fog", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 1, logicFile="logic/weather/fog.logic", minTime = 60, maxTime = 120 },
		{ action = "spawn_fog", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 1, logicFile="logic/weather/fog.logic", minTime = 60, maxTime = 120 },
		{ action = "spawn_thunderstorm", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/thunderstorm.logic", minTime = 60, maxTime = 120 },
		{ action = "spawn_thunderstorm", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/thunderstorm.logic", minTime = 60, maxTime = 120 },
		{ action = "spawn_super_moon", type = "POSITIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 3, logicFile="logic/weather/super_moon.logic", minTime = 60, maxTime = 120, weight = 0.5 },
		{ action = "spawn_wind_weak", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/wind_weak.logic", minTime = 60, maxTime = 120, weight = 0.5 },
		{ action = "spawn_wind_weak", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/wind_weak.logic", minTime = 60, maxTime = 120, weight = 0.5 },
		{ action = "spawn_wind_strong", type = "POSITIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/wind_strong.logic", minTime = 60, maxTime = 120, weight = 0.5 },
		{ action = "spawn_wind_strong", type = "POSITIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/wind_strong.logic", minTime = 60, maxTime = 120, weight = 0.5 },
		{ action = "spawn_wind_none", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 3, logicFile="logic/weather/wind_none.logic", minTime = 60, maxTime = 120, weight = 0.5 },
		{ action = "spawn_wind_none", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 3, logicFile="logic/weather/wind_none.logic", minTime = 60, maxTime = 120, weight = 0.5 },
		{ action = "spawn_blooming_air", type = "POSITIVE", gameStates="IDLE|STREAMING", minEventLevel = 1, logicFile="logic/weather/blooming_air.logic", minTime = 120, maxTime = 180 },
		{ action = "spawn_blooming_air", type = "POSITIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 1, logicFile="logic/weather/blooming_air.logic", minTime = 120, maxTime = 180 },		
		{ action = "spawn_monsoon", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/monsoon.logic", minTime = 60, maxTime = 120, weight = 2 },
		{ action = "spawn_monsoon", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/monsoon.logic", minTime = 60, maxTime = 120, weight = 2 },
	}

	rules.addResourcesOnRunOut = 
	{

	}

	rules.timeToNextDifficultyLevel = 
	{
		200, -- difficulty level 1
		600, -- difficulty level 2
		600, -- difficulty level 3
		600, -- difficulty level 4
		600, -- difficulty level 5
		600, -- difficulty level 6
		600, -- difficulty level 7
		600, -- difficulty level 8
		600, -- difficulty level 9
	}

	rules.prepareSpawnTime = 
	{
		360,  -- difficulty level 1
		360,  -- difficulty level 2
		360,  -- difficulty level 3
		360,  -- difficulty level 4
		360,  -- difficulty level 5
		360,  -- difficulty level 6
		360,  -- difficulty level 7
		360,  -- difficulty level 8
		360,  -- difficulty level 9
	}

	rules.buildingsUpgradeStartsLogic = 
	{			
		{ name = "headquarters_lvl_2", level = 1, prepareTime = 120, entryLogic = "logic/dom/hq_upgrade_level_1_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_1_exit.logic" },   
		{ name = "headquarters_lvl_3", level = 1, prepareTime = 120, entryLogic = "logic/dom/hq_upgrade_level_2_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_2_exit.logic" },   
		{ name = "headquarters_lvl_4", level = 1, prepareTime = 120, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
		{ name = "headquarters_lvl_5", level = 2, prepareTime = 120, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
		{ name = "headquarters_lvl_6", level = 2, prepareTime = 120, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
		{ name = "headquarters_lvl_7", level = 2, prepareTime = 120, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
	}

	rules.objectivesLogic =
	{
		{ name = "logic/objectives/kill_cosmic_arachnoid_elite.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/kill_cosmic_magmoth_ultra_boss_elite.logic", minDifficultyLevel = 5 },
		{ name = "logic/objectives/kill_cosmic_phirian_boss_elite.logic", minDifficultyLevel = 5 },
		{ name = "logic/objectives/kill_cosmic_gnerot_boss_elite.logic", minDifficultyLevel = 5 },
		{ name = "logic/objectives/destroy_cosmic_crystal_creeper.logic", minDifficultyLevel = 5 },
		{ name = "logic/objectives/destroy_nest_cosmic_canoptrix_single.logic", minDifficultyLevel = 2, maxDifficultyLevel = 3 }, 
		{ name = "logic/objectives/destroy_nest_cosmic_canoptrix_multiple.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/destroy_nest_cosmic_kermon_multiple.logic", minDifficultyLevel = 5 },
		{ name = "logic/objectives/destroy_nest_cosmic_morirot_single.logic", minDifficultyLevel = 2, maxDifficultyLevel = 3 }, 
		{ name = "logic/objectives/destroy_nest_cosmic_morirot_multiple.logic", minDifficultyLevel = 5 },
		{ name = "logic/objectives/destroy_nest_cosmic_baxmoth_multiple.logic", minDifficultyLevel = 5 },
		{ name = "logic/objectives/destroy_nest_cosmic_lesigian_multiple.logic", minDifficultyLevel = 5 },
		{ name = "logic/objectives/destroy_nest_cosmic_phirian_multiple.logic", minDifficultyLevel = 5 },
		{ name = "logic/objectives/destroy_nest_cosmic_hedroner_multiple.logic", minDifficultyLevel = 5 },
		{ name = "logic/objectives/destroy_nest_cosmic_gnerot_multiple.logic", minDifficultyLevel = 5 },
		{ name = "logic/objectives/destroy_nest_cosmic_magmoth_ultra_multiple.logic", minDifficultyLevel = 5 },
	}

	rules.cooldownAfterAttacks = 
	{			
		60,  -- difficulty level 1
		90,  -- difficulty level 2
		120,  -- difficulty level 3
		180,  -- difficulty level 4	
		180,  -- difficulty level 5	
		180,  -- difficulty level 6	
		240,  -- difficulty level 7
		240,  -- difficulty level 8	
		240,  -- difficulty level 9	
	}

	rules.idleTime = 
	{			
		0,  -- difficulty level 1
		0,  -- difficulty level 2
		0,  -- difficulty level 3
		0,  -- difficulty level 4	
		0,  -- difficulty level 5	
		0,  -- difficulty level 6	
		0,  -- difficulty level 7
		0,  -- difficulty level 8	
		0,  -- difficulty level 9	
	}

	rules.maxAttackCountPerDifficulty = 
	{			
		1,  -- difficulty level 1
		2,  -- difficulty level 2
		2,  -- difficulty level 3		
		3,  -- difficulty level 4
		3,  -- difficulty level 5
		3,  -- difficulty level 6
		3,  -- difficulty level 7
		3,  -- difficulty level 8
		4,  -- difficulty level 9
	}
	
	rules.wavesEntryDefinitions =
	{
		 -- difficulty level 1
			"logic/missions/survival/attack_level_1_entry.logic",
		 -- difficulty level 2
			"logic/missions/survival/attack_level_2_entry.logic",
		 -- difficulty level 3		
			"logic/missions/survival/attack_level_2_entry.logic",
		 -- difficulty level 4		
			"logic/missions/survival/attack_level_2_entry.logic",
		 -- difficulty level 5		
			"logic/missions/survival/attack_level_2_entry.logic",
		 -- difficulty level 6		
			"logic/missions/survival/attack_level_2_entry.logic",
		 -- difficulty level 7		
			"logic/missions/survival/attack_level_2_entry.logic",
		 -- difficulty level 8		
			"logic/missions/survival/attack_level_2_entry.logic",
		 -- difficulty level 9		
			"logic/missions/survival/attack_level_2_entry.logic",		
	}

	rules.waves = 
	{
		["default"] =
		{
			-- difficulty level 1
			{
			"logic/missions/survival/attack_level_1_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_1_id_2_ArcticIslands.logic",
		},
	
		 -- difficulty level 2
		{ 			
			"logic/missions/survival/attack_level_2_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_2_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 3
		{ 
			"logic/missions/survival/attack_level_3_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_3_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 4
		{ 			
			"logic/missions/survival/attack_level_4_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_4_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 5
		{ 
			"logic/missions/survival/attack_level_5_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_5_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 6
		{ 
			"logic/missions/survival/attack_level_6_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_6_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 7
		{ 
			"logic/missions/survival/attack_level_7_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_7_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 8
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 9
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands.logic",
			},
		},
	}

	rules.extraWaves = 
	{
		 -- difficulty level 1
		{
			"logic/missions/survival/attack_level_1_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_1_id_2_ArcticIslands.logic",
		},
	
		 -- difficulty level 2
		{ 			
			"logic/missions/survival/attack_level_2_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_2_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 3
		{ 
			"logic/missions/survival/attack_level_3_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_3_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 4
		{ 			
			"logic/missions/survival/attack_level_4_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_4_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 5
		{ 
			"logic/missions/survival/attack_level_5_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_5_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 6
		{ 
			"logic/missions/survival/attack_level_6_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_6_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 7
		{ 
			"logic/missions/survival/attack_level_7_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_7_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 8
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 9
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands.logic",
		},
	}

	rules.bosses = 
	{
		 -- difficulty level 1
		{
			"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
		},
	
		 -- difficulty level 2
		{
			"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
		},
	
		 -- difficulty level 3
		{
			"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
		},
	
		 -- difficulty level 4
		{
			"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
		},
	
		 -- difficulty level 5
		{
			"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
		},
	
		 -- difficulty level 6
		{
			"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
		},
	
		 -- difficulty level 7
		{
			"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
		},
	
		 -- difficulty level 8
		{
			"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
		},
	
		 -- difficulty level 9
		{
			"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
			"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
		},
	}

	rules.multiplayerWaves = 
	{
		 -- difficulty level 1		
		{ 
			additionalWaves = 0, -- Additional Waves count = NumberOfPlayers + (additionalWaves -1(const)). E.g. 2 players + 0 -1 = 1 additional multiplayer wave for 2 players. Multiplayer Additional waves are disabled in single player mode. Check dom_mananger:GetMultiplayerAttackCount for actual code
			waves = 
			{
				"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
			}
		},
	
		 -- difficulty level 2
		{ 
			additionalWaves = 0,
			waves = 
			{
				"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
			}
		},
		 -- difficulty level 3
		{ 
			additionalWaves = 0,
			waves = 
			{
				"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
			}
		},

		 -- difficulty level 4
		{ 
			additionalWaves = 0,
			waves = 
			{
				"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
			}
		},

		 -- difficulty level 5
		{ 
			additionalWaves = 0,
			waves = 
			{
				"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
			}
		},

		 -- difficulty level 6
		{ 
			additionalWaves = 0,
			waves = 
			{
				"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
			}
		},

		 -- difficulty level 7
		{ 
			additionalWaves = 1,
			waves = 
			{
				"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
			}
		},

		 -- difficulty level 8
		{ 
			additionalWaves = 2,
			waves = 
			{
				"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
			}
		},

		 -- difficulty level 9
		{ 
			additionalWaves = 2,
			waves = 
			{
				"logic/missions/survival/attack_boss_cosmic_arachnoid_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_magmoth_boss.logic",
				"logic/missions/survival/attack_boss_cosmic_hedroner_boss.logic",
			}
		},
	}

    return rules;
end