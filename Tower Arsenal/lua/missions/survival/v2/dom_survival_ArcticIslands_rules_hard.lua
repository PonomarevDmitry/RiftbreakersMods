return function()
    local rules = require("lua/missions/survival/v2/dom_survival_ArcticIslands_rules_default.lua")()

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
		420,  -- difficulty level 1
		420,  -- difficulty level 2
		420,  -- difficulty level 3
		420,  -- difficulty level 4	
		420,  -- difficulty level 5	
		420,  -- difficulty level 6	
		420,  -- difficulty level 7
		420,  -- difficulty level 8	
		420,  -- difficulty level 9	
	}

	rules.maxAttackCountPerDifficulty = 
	{			
		3,  -- difficulty level 1
		3,  -- difficulty level 2
		4,  -- difficulty level 3		
		4,  -- difficulty level 4
		4,  -- difficulty level 5
		5,  -- difficulty level 6
		5,  -- difficulty level 7
		6,  -- difficulty level 8
		6,  -- difficulty level 9
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
		{ name = "logic/objectives/kill_cosmic_arachnoid_elite.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/kill_cosmic_magmoth_ultra_boss_elite.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/kill_cosmic_phirian_boss_elite.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/kill_cosmic_gnerot_boss_elite.logic", minDifficultyLevel = 2 },
		{ name = "logic/objectives/destroy_cosmic_crystal_creeper.logic", minDifficultyLevel = 2 },
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
	
	rules.waves = 
	{
		["default"] =
		{
			 -- difficulty level 1		
			{ 
			"logic/missions/survival/attack_level_1_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_1_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_1_id_2_ArcticIslands.logic",
		},
	
		 -- difficulty level 2
		{ 			
			"logic/missions/survival/attack_level_2_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_2_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_2_id_2_ArcticIslands.logic",
		},

		 -- difficulty level 3
		{ 
			"logic/missions/survival/attack_level_3_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_3_id_2_ArcticIslands.logic",
			"logic/missions/survival/attack_level_3_id_3_ArcticIslands.logic",
		},

		 -- difficulty level 4
		{ 			
			"logic/missions/survival/attack_level_4_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_4_id_2_ArcticIslands.logic",
			"logic/missions/survival/attack_level_4_id_3_ArcticIslands.logic",
		},

		 -- difficulty level 5
		{ 
			"logic/missions/survival/attack_level_5_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_5_id_2_ArcticIslands.logic",
			"logic/missions/survival/attack_level_5_id_3_ArcticIslands.logic",
		},

		 -- difficulty level 6
		{ 
			"logic/missions/survival/attack_level_6_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_6_id_2_ArcticIslands.logic",
			"logic/missions/survival/attack_level_6_id_3_ArcticIslands.logic",
		},

		 -- difficulty level 7
		{ 
			"logic/missions/survival/attack_level_7_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_7_id_2_ArcticIslands.logic",
			"logic/missions/survival/attack_level_7_id_3_ArcticIslands.logic",
		},

		 -- difficulty level 8
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_3_ArcticIslands.logic",
		},

		 -- difficulty level 9
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_3_ArcticIslands.logic",
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
			"logic/missions/survival/attack_level_4_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_4_id_2_ArcticIslands.logic",
		},
	
		 -- difficulty level 5
		{ 
			"logic/missions/survival/attack_level_5_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_5_id_2_ArcticIslands.logic",
			"logic/missions/survival/attack_level_5_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_5_id_2_ArcticIslands.logic",	
		},
	
		 -- difficulty level 6
		{ 
			"logic/missions/survival/attack_level_6_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_6_id_2_ArcticIslands.logic",
			"logic/missions/survival/attack_level_6_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_6_id_2_ArcticIslands.logic",		
		},
	
		 -- difficulty level 7
		{ 
			"logic/missions/survival/attack_level_7_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_7_id_2_ArcticIslands.logic",
			"logic/missions/survival/attack_level_7_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_7_id_2_ArcticIslands.logic",		
		},
	
		 -- difficulty level 8
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands.logic",		
		},
	
		 -- difficulty level 9
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands.logic",
		},
	}

    return rules;
end