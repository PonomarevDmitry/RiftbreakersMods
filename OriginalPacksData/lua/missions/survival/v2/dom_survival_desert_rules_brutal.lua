return function()
    local rules = require("lua/missions/survival/v2/dom_survival_desert_rules_default.lua")()

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
	
	rules.buildingsUpgradeStartsLogic = 
	{			
		{ name = "headquarters_lvl_2", level = 1, prepareTime = 120, entryLogic = "logic/dom/hq_upgrade_level_1_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_1_exit.logic" },   
		{ name = "headquarters_lvl_3", level = 1, prepareTime = 120, entryLogic = "logic/dom/hq_upgrade_level_2_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_2_exit.logic" },   
		{ name = "headquarters_lvl_4", level = 1, prepareTime = 120, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
		{ name = "headquarters_lvl_5", level = 1, prepareTime = 120, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
		{ name = "headquarters_lvl_6", level = 1, prepareTime = 120, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
		{ name = "headquarters_lvl_7", level = 1, prepareTime = 120, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
	}
	
	rules.waves = 
	{
		["default"] =
		{
			 -- difficulty level 1		
			{ 				
				"logic/missions/survival/attack_level_1_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_1_id_1_desert_ultra.logic",				
				"logic/missions/survival/attack_level_1_id_2_desert_alpha.logic",
				"logic/missions/survival/attack_level_1_id_2_desert_ultra.logic",
			},
	
			 -- difficulty level 2
			{ 			
				
				"logic/missions/survival/attack_level_2_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_2_id_1_desert_ultra.logic",				
				"logic/missions/survival/attack_level_2_id_2_desert_alpha.logic",
				"logic/missions/survival/attack_level_2_id_2_desert_ultra.logic",
			},

			 -- difficulty level 3
			{ 				
				"logic/missions/survival/attack_level_3_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_3_id_1_desert_ultra.logic",				
				"logic/missions/survival/attack_level_3_id_2_desert_alpha.logic",
				"logic/missions/survival/attack_level_3_id_2_desert_ultra.logic",								
			},

			 -- difficulty level 4
			{				
				"logic/missions/survival/attack_level_4_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_4_id_1_desert_ultra.logic",			
				"logic/missions/survival/attack_level_4_id_2_desert_alpha.logic",
				"logic/missions/survival/attack_level_4_id_2_desert_ultra.logic",												
			},

			 -- difficulty level 5
			{ 				
				"logic/missions/survival/attack_level_5_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_5_id_1_desert_ultra.logic",				
				"logic/missions/survival/attack_level_5_id_2_desert_alpha.logic",			
				"logic/missions/survival/attack_level_5_id_2_desert_ultra.logic",									
			},

			 -- difficulty level 6
			{ 				
				"logic/missions/survival/attack_level_6_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_6_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_6_id_1_desert_ultra.logic",				
				"logic/missions/survival/attack_level_6_id_2_desert_alpha.logic",			
				"logic/missions/survival/attack_level_6_id_2_desert_alpha.logic",			
				"logic/missions/survival/attack_level_6_id_2_desert_ultra.logic",													
			},

			 -- difficulty level 7
			{ 				
				"logic/missions/survival/attack_level_7_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_7_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_7_id_1_desert_ultra.logic",				
				"logic/missions/survival/attack_level_7_id_2_desert_alpha.logic",
				"logic/missions/survival/attack_level_7_id_2_desert_alpha.logic",
				"logic/missions/survival/attack_level_7_id_2_desert_ultra.logic",												
			},

			 -- difficulty level 8
			{ 				
				"logic/missions/survival/attack_level_8_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_desert_ultra.logic",				
				"logic/missions/survival/attack_level_8_id_2_desert_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_desert_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_desert_ultra.logic",												
			},

			 -- difficulty level 9
			{ 				
				"logic/missions/survival/attack_level_8_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_desert_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_desert_ultra.logic",
				"logic/missions/survival/attack_level_8_id_1_desert_ultra.logic",				
				"logic/missions/survival/attack_level_8_id_2_desert_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_desert_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_desert_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_desert_ultra.logic",
				"logic/missions/survival/attack_level_8_id_2_desert_ultra.logic",												
			},
		},
	}

    return rules;
end