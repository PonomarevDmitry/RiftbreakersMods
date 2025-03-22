return function()
    local rules = {}

	rules.maxObjectivesAtOnce = 2
	rules.eventsPerIdleState = 2
	rules.eventsPerPrepareState = 0 -- [0,1]
	rules.pauseAttacks = false
	rules.prepareAttacks = true
	rules.baseTimeBetweenObjectives = 2400

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
		{ action = "cosmic_kermon_attack", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 4, maxEventLevel = 5, logicFile="logic/event/cosmic_kermon_attack.logic", weight = 3 },
		{ action = "cosmic_kermon_attack", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 4, maxEventLevel = 5, logicFile="logic/event/cosmic_kermon_attack.logic", weight = 3 },
		{ action = "cosmic_phirian_attack", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 4, maxEventLevel = 5, logicFile="logic/event/cosmic_phirian_attack.logic", weight = 3 },
		{ action = "cosmic_phirian_attack", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 4, maxEventLevel = 5, logicFile="logic/event/cosmic_phirian_attack.logic", weight = 3 },
		{ action = "spawn_invasion_easy", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 5, logicFile="logic/weather/invasion_easy.logic", minTime = 30, maxTime = 60, weight = 0.5 },
		{ action = "spawn_invasion_easy", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 5, logicFile="logic/weather/invasion_easy.logic", minTime = 30, maxTime = 60, weight = 0.5 },
		--{ action = "spawn_comet_boss_cosmic_hedroner", type = "NEGATIVE", gameStates = "ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/event/comet_boss_cosmic_hedroner", minTime = 30, maxTime = 60, weight = 0.5 },
		--{ action = "spawn_comet_boss_cosmic_hedroner", type = "NEGATIVE", gameStates = "IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/event/comet_boss_cosmic_hedroner", minTime = 30, maxTime = 60, weight = 0.5 },
		{ action = "spawn_cosmic_meteor_shower", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/comsic_meteor_shower.logic", minTime = 5, maxTime = 10, weight = 2 },
		{ action = "spawn_cosmic_meteor_shower", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/cosmic_meteor_shower.logic", minTime = 5, maxTime = 10, weight = 2 },
		{ action = "spawn_cosmic_tornado_near_player", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 1, maxEventLevel = 2, logicFile="logic/weather/cosmic_tornado_near_player.logic", weight = 0.5 },
		{ action = "spawn_cosmic_tornado_near_player", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 1, maxEventLevel = 2, logicFile="logic/weather/cosmic_tornado_near_player.logic", weight = 0.5 },
		{ action = "spawn_cosmic_tornado_near_base", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/cosmic_tornado_near_base.logic", minTime = 30, maxTime = 60, weight = 0.5 },
		{ action = "spawn_cosmic_tornado_near_base", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/cosmic_tornado_near_base.logic", minTime = 30, maxTime = 60, weight = 0.5 },
		{ action = "spawn_cosmic_moon", type = "NEGATIVE", gameStates="IDLE|STREAMING", minEventLevel = 1, logicFile="logic/weather/cosmic_moon.logic", weight = 2 },
		{ action = "spawn_cosmic_moon", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 1, logicFile="logic/weather/cosmic_moon.logic", weight = 2 },
		{ action = "spawn_cryogenic_tornado_near_player", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 1, maxEventLevel = 2, logicFile="logic/weather/cryogenic_tornado_near_player.logic", weight = 2 },
		{ action = "spawn_cryogenic_tornado_near_player", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 1, maxEventLevel = 2, logicFile="logic/weather/cryogenic_tornado_near_player.logic", weight = 2 },
		{ action = "spawn_cryogenic_tornado_near_base", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/cryogenic_tornado_near_base.logic", minTime = 120, maxTime = 140, weight = 3 },
		{ action = "spawn_cryogenic_tornado_near_base", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/cryogenic_tornado_near_base.logic", minTime = 120, maxTime = 140, weight = 3 },
	}

	rules.addResourcesOnRunOut = 
	{
		{ name = "cosmonite_ore_vein", runOutPercentageOnMap = 30, minToSpawn = 10000, maxToSpawn = 20000 },
	}

	rules.majorAttackLogic =
	{			
		{ level = 2, minLevel = 5, prepareTime = 300, entryLogic = "logic/dom/major_attack_1_entry.logic", exitLogic = "logic/dom/major_attack_1_exit.logic" },     
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
		120,  -- difficulty level 1
		120,  -- difficulty level 2
		120,  -- difficulty level 3
		120,  -- difficulty level 4	
		120,  -- difficulty level 5	
		120,  -- difficulty level 6	
		120,  -- difficulty level 7
		120,  -- difficulty level 8	
		120,  -- difficulty level 9	
	}

	rules.buildingsUpgradeStartsLogic = 
	{			
 
	}

	rules.objectivesLogic =
	{
		{ name = "logic/objectives/kill_cosmic_arachnoid_elite.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/destroy_nest_arctic_boss.logic", minDifficultyLevel = 3, maxDifficultyLevel = 5 },
		{ name = "logic/objectives/destroy_nest_cosmic_canoptrix_single.logic", minDifficultyLevel = 2, maxDifficultyLevel = 3 },
		{ name = "logic/objectives/destroy_nest_cosmic_canoptrix_multiple.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/destroy_nest_cosmic_kermon_multiple.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/destroy_nest_cosmic_morirot_single.logic", minDifficultyLevel = 2, maxDifficultyLevel = 3 },
		{ name = "logic/objectives/destroy_nest_cosmic_morirot_multiple.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/destroy_nest_cosmic_baxmoth_multiple.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/destroy_nest_cosmic_lesigian_multiple.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/destroy_nest_cosmic_phirian_multiple.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/destroy_nest_cosmic_hedroner_multiple.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/destroy_nest_cosmic_gnerot_multiple.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/destroy_nest_cosmic_magmoth_ultra_multiple.logic", minDifficultyLevel = 2 },
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
		450,  -- difficulty level 1
		600,  -- difficulty level 2
		660,  -- difficulty level 3
		720,  -- difficulty level 4	
		780,  -- difficulty level 5	
		840,  -- difficulty level 6	
		900,  -- difficulty level 7
		900,  -- difficulty level 8	
		900,  -- difficulty level 9	
	}

	rules.maxAttackCountPerDifficulty = 
	{			
		1,  -- difficulty level 1
		1,  -- difficulty level 2
		2,  -- difficulty level 3		
		2,  -- difficulty level 4
		2,  -- difficulty level 5
		2,  -- difficulty level 6
		3,  -- difficulty level 7
		3,  -- difficulty level 8
		4,  -- difficulty level 9
	}
	
	rules.prepareAttackDefinitions =
	{
		 -- difficulty level 1
			"logic/dom/attack_level_1_prepare.logic",
		 -- difficulty level 2
			"logic/dom/attack_level_1_prepare.logic",
		 -- difficulty level 3		
			"logic/dom/attack_level_1_prepare.logic",
		 -- difficulty level 4		
			"logic/dom/attack_level_1_prepare.logic",
		 -- difficulty level 5		
			"logic/dom/attack_level_1_prepare.logic",
		 -- difficulty level 6		
			"logic/dom/attack_level_1_prepare.logic",
		 -- difficulty level 7		
			"logic/dom/attack_level_1_prepare.logic",
		 -- difficulty level 8		
			"logic/dom/attack_level_1_prepare.logic",
		 -- difficulty level 9		
			"logic/dom/attack_level_1_prepare.logic",		
	}

	rules.wavesEntryDefinitions =
	{
		 -- difficulty level 1
			"logic/dom/attack_level_1_entry.logic",
		 -- difficulty level 2
			"logic/dom/attack_level_2_entry.logic",
		 -- difficulty level 3		
			"logic/dom/attack_level_2_entry.logic",
		 -- difficulty level 4		
			"logic/dom/attack_level_2_entry.logic",
		 -- difficulty level 5		
			"logic/dom/attack_level_2_entry.logic",
		 -- difficulty level 6		
			"logic/dom/attack_level_2_entry.logic",
		 -- difficulty level 7		
			"logic/dom/attack_level_2_entry.logic",
		 -- difficulty level 8		
			"logic/dom/attack_level_2_entry.logic",
		 -- difficulty level 9		
			"logic/dom/attack_level_2_entry.logic",		
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