return function()
    local rules = require("lua/missions/survival/v2/dom_survival_ArcticIslands_rules_default.lua")()

	rules.timeToNextDifficultyLevel = 
	{			
		300, -- difficulty level 1
		300, -- difficulty level 2
		300, -- difficulty level 3	
		300, -- difficulty level 4
		300, -- difficulty level 5
		300, -- difficulty level 6
		300, -- difficulty level 7
		300, -- difficulty level 8
		300, -- difficulty level 9
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

	rules.maxAttackCountPerDifficulty = 
	{			
		3,  -- difficulty level 1
		4,  -- difficulty level 2
		4,  -- difficulty level 3		
		5,  -- difficulty level 4
		5,  -- difficulty level 5
		6,  -- difficulty level 6
		6,  -- difficulty level 7
		7,  -- difficulty level 8
		7,  -- difficulty level 9
	}
	
	rules.buildingsUpgradeStartsLogic = 
	{			
		{ name = "headquarters_lvl_2", level = 1, prepareTime = 180, entryLogic = "logic/dom/hq_upgrade_level_1_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_1_exit.logic" },   
		{ name = "headquarters_lvl_3", level = 1, prepareTime = 180, entryLogic = "logic/dom/hq_upgrade_level_2_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_2_exit.logic" },   
		{ name = "headquarters_lvl_4", level = 1, prepareTime = 180, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
		{ name = "headquarters_lvl_5", level = 1, prepareTime = 180, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
		{ name = "headquarters_lvl_6", level = 1, prepareTime = 180, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
		{ name = "headquarters_lvl_7", level = 1, prepareTime = 180, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
	}
	
	rules.objectivesLogic = 
	{
		{ name = "logic/objectives/kill_elite_random_bosses.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/destroy_cosmic_crystal_creeper.logic", minDifficultyLevel = 3 },
		{ name = "logic/objectives/destroy_nest_cosmic_canoptrix_single.logic", minDifficultyLevel = 2, maxDifficultyLevel = 3 }, 
		{ name = "logic/objectives/destroy_nest_cosmic_canoptrix_multiple.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/destroy_nest_cosmic_morirot_single.logic", minDifficultyLevel = 2, maxDifficultyLevel = 3 }, 
		{ name = "logic/objectives/destroy_nest_cosmic_morirot_multiple.logic", minDifficultyLevel = 4 },
		{ name = "logic/objectives/destroy_nest_arctic_boss.logic", minDifficultyLevel = 4, maxDifficultyLevel = 5 }, 
	}

	rules.waves = 
	{
		["default"] =
		{
			-- difficulty level 1		
			{ 
				"logic/missions/survival/attack_level_1_id_1_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_1_id_2_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			},
		
			-- difficulty level 2
			{ 
				"logic/missions/survival/attack_level_2_id_1_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_2_id_2_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			},
	
			-- difficulty level 3
			{ 
				"logic/missions/survival/attack_level_3_id_1_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_3_id_2_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			},
	
			-- difficulty level 4
			{ 
				"logic/missions/survival/attack_level_4_id_1_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_4_id_2_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_4_id_3_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			},
	
			-- difficulty level 5
			{ 
				"logic/missions/survival/attack_level_5_id_1_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_5_id_2_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_5_id_3_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_5_id_4_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			},
	
			-- difficulty level 6
			{ 
				"logic/missions/survival/attack_level_6_id_1_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_6_id_2_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_6_id_3_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_6_id_4_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_6_id_5_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			},
	
			-- difficulty level 7
			{ 
				"logic/missions/survival/attack_level_7_id_1_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_7_id_2_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_7_id_3_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_7_id_4_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_7_id_5_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			},
	
			-- difficulty level 8
			{ 
				"logic/missions/survival/attack_level_8_id_1_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_8_id_2_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_8_id_3_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_8_id_4_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_8_id_5_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			},
	
			-- difficulty level 9
			{ 
				"logic/missions/survival/attack_level_8_id_1_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_8_id_2_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_8_id_3_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_8_id_4_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_8_id_5_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			},
		}
	}

	rules.extraWaves = 
	{
		 -- difficulty level 1		
		{ 
			"logic/missions/survival/attack_level_1_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_1_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
		},
	
		 -- difficulty level 2
		{ 			
			"logic/missions/survival/attack_level_2_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_2_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
		},
	
		 -- difficulty level 3
		{ 
			"logic/missions/survival/attack_level_3_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_3_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
		},
	
		 -- difficulty level 4
		{ 			
			"logic/missions/survival/attack_level_4_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_4_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_4_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_4_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
		},
	
		 -- difficulty level 5
		{ 
			"logic/missions/survival/attack_level_5_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_5_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_5_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_5_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
		},
	
		 -- difficulty level 6
		{ 
			"logic/missions/survival/attack_level_6_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_6_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_6_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_6_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
		},
	
		 -- difficulty level 7
		{ 
			"logic/missions/survival/attack_level_7_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_7_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_7_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_7_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
		},
	
		 -- difficulty level 8
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
		},
	
		 -- difficulty level 9
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
		},
	}

    return rules;
end