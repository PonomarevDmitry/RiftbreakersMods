return function()
    local rules = require("lua/missions/survival/dom_survival_acid_rules_default.lua")()

	rules.timeToNextDifficultyLevel = 
	{			
		200, -- difficulty level 1
		500, -- difficulty level 2
		500, -- difficulty level 3	
		500, -- difficulty level 4
		500, -- difficulty level 5
		500, -- difficulty level 6
		500, -- difficulty level 7
		500, -- difficulty level 8
		500, -- difficulty level 9
	}

	rules.nextSpawnIntervalOnDifficultyLevel = 
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
		2,  -- difficulty level 1
		2,  -- difficulty level 2
		2,  -- difficulty level 3		
		3,  -- difficulty level 4
		3,  -- difficulty level 5
		3,  -- difficulty level 6
		3,  -- difficulty level 7
		3,  -- difficulty level 8
		4,  -- difficulty level 9
	}
	
	--rules.buildingsUpgradeStartsLogic = 
	--{			
	--	{ name = "headquarters_lvl_2", logic = "logic/hq_upgrade/upgrade_lvl1_brutal.logic" },   
	--	{ name = "headquarters_lvl_3", logic = "logic/hq_upgrade/upgrade_lvl2_brutal.logic" },   
	--	{ name = "headquarters_lvl_4", logic = "logic/hq_upgrade/upgrade_lvl3_brutal.logic" },   
	--}
	
	--rules.waves = 
	--{
	--	 -- difficulty level 1		
	--	{ 
	--		"logic/missions/survival/attack_level_1_id_1.logic",
	--		"logic/missions/survival/attack_level_1_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_1_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_1_id_2.logic",
	--		"logic/missions/survival/attack_level_1_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_1_id_2_ultra.logic",
	--	},
	--
	--	 -- difficulty level 2
	--	{ 			
	--		"logic/missions/survival/attack_level_2_id_1.logic",
	--		"logic/missions/survival/attack_level_2_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_2_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_2_id_2.logic",
	--		"logic/missions/survival/attack_level_2_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_2_id_2_ultra.logic",
	--	},
	--
	--	 -- difficulty level 3
	--	{ 
	--		"logic/missions/survival/attack_level_3_id_1.logic",
	--		"logic/missions/survival/attack_level_3_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_3_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_3_id_2.logic",
	--		"logic/missions/survival/attack_level_3_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_3_id_2_ultra.logic",
	--	},
	--
	--	 -- difficulty level 4
	--	{ 			
	--		"logic/missions/survival/attack_level_4_id_1.logic",
	--		"logic/missions/survival/attack_level_4_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_4_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_4_id_2.logic",
	--		"logic/missions/survival/attack_level_4_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_4_id_2_ultra.logic",
	--	},
	--
	--	 -- difficulty level 5
	--	{ 
	--		"logic/missions/survival/attack_level_5_id_1.logic",
	--		"logic/missions/survival/attack_level_5_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_5_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_5_id_2.logic",			
	--		"logic/missions/survival/attack_level_5_id_2_alpha.logic",			
	--		"logic/missions/survival/attack_level_5_id_2_ultra.logic",			
	--	},
	--
	--	 -- difficulty level 6
	--	{ 
	--		"logic/missions/survival/attack_level_6_id_1.logic",
	--		"logic/missions/survival/attack_level_6_id_1.logic",
	--		"logic/missions/survival/attack_level_6_id_1.logic",
	--		"logic/missions/survival/attack_level_6_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_6_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_6_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_6_id_2.logic",			
	--		"logic/missions/survival/attack_level_6_id_2.logic",			
	--		"logic/missions/survival/attack_level_6_id_2.logic",			
	--		"logic/missions/survival/attack_level_6_id_2_alpha.logic",			
	--		"logic/missions/survival/attack_level_6_id_2_alpha.logic",			
	--		"logic/missions/survival/attack_level_6_id_2_ultra.logic",			
	--	},
	--
	--	 -- difficulty level 7
	--	{ 
	--		"logic/missions/survival/attack_level_7_id_1.logic",
	--		"logic/missions/survival/attack_level_7_id_1.logic",
	--		"logic/missions/survival/attack_level_7_id_1.logic",
	--		"logic/missions/survival/attack_level_7_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_7_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_7_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_7_id_2.logic",
	--		"logic/missions/survival/attack_level_7_id_2.logic",
	--		"logic/missions/survival/attack_level_7_id_2.logic",
	--		"logic/missions/survival/attack_level_7_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_7_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_7_id_2_ultra.logic",
	--	},
	--
	--	 -- difficulty level 8
	--	{ 
	--		"logic/missions/survival/attack_level_8_id_1.logic",
	--		"logic/missions/survival/attack_level_8_id_1.logic",
	--		"logic/missions/survival/attack_level_8_id_1.logic",
	--		"logic/missions/survival/attack_level_8_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_8_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_8_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_8_id_2.logic",
	--		"logic/missions/survival/attack_level_8_id_2.logic",
	--		"logic/missions/survival/attack_level_8_id_2.logic",
	--		"logic/missions/survival/attack_level_8_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_8_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_8_id_2_ultra.logic",
	--	},
	--
	--	 -- difficulty level 9
	--	{ 
	--		"logic/missions/survival/attack_level_8_id_1.logic",
	--		"logic/missions/survival/attack_level_8_id_1.logic",
	--		"logic/missions/survival/attack_level_8_id_1.logic",
	--		"logic/missions/survival/attack_level_8_id_1.logic",
	--		"logic/missions/survival/attack_level_8_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_8_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_8_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_8_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_8_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_8_id_2.logic",
	--		"logic/missions/survival/attack_level_8_id_2.logic",
	--		"logic/missions/survival/attack_level_8_id_2.logic",
	--		"logic/missions/survival/attack_level_8_id_2.logic",
	--		"logic/missions/survival/attack_level_8_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_8_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_8_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_8_id_2_ultra.logic",
	--		"logic/missions/survival/attack_level_8_id_2_ultra.logic",
	--	},
	--}

	--rules.extraWaves = 
	--{
	--	 -- difficulty level 1		
	--	{ 
	--		"logic/missions/survival/attack_level_1_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_1_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_1_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_1_id_2_ultra.logic",
	--	},
	--
	--	 -- difficulty level 2
	--	{ 			
	--		"logic/missions/survival/attack_level_2_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_2_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_2_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_2_id_2_ultra.logic",
	--	},
	--
	--	 -- difficulty level 3
	--	{ 
	--		"logic/missions/survival/attack_level_3_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_3_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_3_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_3_id_2_ultra.logic",
	--	},
	--
	--	 -- difficulty level 4
	--	{ 			
	--		"logic/missions/survival/attack_level_4_id_1_alpha.logic",
	--		"logic/missions/survival/attack_level_4_id_2_alpha.logic",
	--		"logic/missions/survival/attack_level_4_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_4_id_2_ultra.logic",
	--	},
	--
	--	 -- difficulty level 5
	--	{ 
	--		"logic/missions/survival/attack_level_5_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_5_id_2_ultra.logic",	
	--	},
	--
	--	 -- difficulty level 6
	--	{ 
	--		"logic/missions/survival/attack_level_6_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_6_id_2_ultra.logic",		
	--	},
	--
	--	 -- difficulty level 7
	--	{ 
	--		"logic/missions/survival/attack_level_7_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_7_id_2_ultra.logic",		
	--	},
	--
	--	 -- difficulty level 8
	--	{ 
	--		"logic/missions/survival/attack_level_8_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_8_id_2_ultra.logic",		
	--	},
	--
	--	 -- difficulty level 9
	--	{ 
	--		"logic/missions/survival/attack_level_8_id_1_ultra.logic",
	--		"logic/missions/survival/attack_level_8_id_2_ultra.logic",
	--	},
	--}

    return rules;
end