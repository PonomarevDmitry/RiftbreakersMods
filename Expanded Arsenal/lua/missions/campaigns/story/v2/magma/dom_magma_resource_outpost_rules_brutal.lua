return function()
    local rules = require("lua/missions/campaigns/story/v2/magma/dom_magma_resource_outpost_rules_default.lua")()
	
	rules.idleTime = 
	{			
		300,  -- difficulty level 1
		420,  -- difficulty level 2
		480,  -- difficulty level 3
		480,  -- difficulty level 4	
		480,  -- difficulty level 5	
		480,  -- difficulty level 6	
		540,  -- difficulty level 7
		540,  -- difficulty level 8	
		540,  -- difficulty level 9	
	}
	
	rules.timeToNextDifficultyLevel = 
	{			
		200, -- difficulty level 1
		480, -- difficulty level 2
		480, -- difficulty level 3	
		480, -- difficulty level 4
		480, -- difficulty level 5
		480, -- difficulty level 6
		540, -- difficulty level 7
		540, -- difficulty level 8
		540, -- difficulty level 9
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
		4,  -- difficulty level 8
		4,  -- difficulty level 9
	}
	
	rules.majorAttackLogic =
	{			
		{ level = 2, minLevel = 7, prepareTime = 300, entryLogic = "logic/dom/major_attack_1_entry.logic", exitLogic = "logic/dom/major_attack_1_exit.logic" },     
	}
	
	rules.waves = 
	{
		["default"] =
		{
			 -- difficulty level 1		
			{
				"logic/missions/survival/attack_level_1_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_1_id_1_magma_ultra.logic",
				"logic/missions/survival/attack_level_1_id_2_magma_alpha.logic",
				"logic/missions/survival/attack_level_1_id_2_magma_ultra.logic",
			},
	
			 -- difficulty level 2
			{ 			
				"logic/missions/survival/attack_level_2_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_2_id_1_magma_ultra.logic",
				"logic/missions/survival/attack_level_2_id_2_magma_alpha.logic",
				"logic/missions/survival/attack_level_2_id_2_magma_ultra.logic",
			},

			 -- difficulty level 3
			{ 
				"logic/missions/survival/attack_level_3_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_3_id_1_magma_ultra.logic",
				"logic/missions/survival/attack_level_3_id_2_magma_alpha.logic",
				"logic/missions/survival/attack_level_3_id_2_magma_ultra.logic",
			},

			 -- difficulty level 4
			{ 			
				"logic/missions/survival/attack_level_4_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_4_id_1_magma_ultra.logic",
				"logic/missions/survival/attack_level_4_id_2_magma_alpha.logic",
				"logic/missions/survival/attack_level_4_id_2_magma_ultra.logic",
			},

			 -- difficulty level 5
			{ 
				"logic/missions/survival/attack_level_5_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_5_id_1_magma_ultra.logic",	
				"logic/missions/survival/attack_level_5_id_2_magma_alpha.logic",			
				"logic/missions/survival/attack_level_5_id_2_magma_ultra.logic",	
			},

			 -- difficulty level 6
			{ 
				"logic/missions/survival/attack_level_6_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_6_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_6_id_1_magma_ultra.logic",			
				"logic/missions/survival/attack_level_6_id_2_magma_alpha.logic",			
				"logic/missions/survival/attack_level_6_id_2_magma_alpha.logic",			
				"logic/missions/survival/attack_level_6_id_2_magma_ultra.logic",			
			},

			 -- difficulty level 7
			{ 
				"logic/missions/survival/attack_level_7_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_7_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_7_id_1_magma_ultra.logic",
				"logic/missions/survival/attack_level_7_id_2_magma_alpha.logic",
				"logic/missions/survival/attack_level_7_id_2_magma_alpha.logic",
				"logic/missions/survival/attack_level_7_id_2_magma_ultra.logic",
			},

			 -- difficulty level 8
			{ 
				"logic/missions/survival/attack_level_8_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_magma_ultra.logic",
				"logic/missions/survival/attack_level_8_id_2_magma_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_magma_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_magma_ultra.logic",
			},

			 -- difficulty level 9
			{ 
				"logic/missions/survival/attack_level_8_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_magma_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_magma_ultra.logic",
				"logic/missions/survival/attack_level_8_id_1_magma_ultra.logic",
				"logic/missions/survival/attack_level_8_id_2_magma_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_magma_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_magma_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_magma_ultra.logic",
				"logic/missions/survival/attack_level_8_id_2_magma_ultra.logic",
			},
		},
	}

	rules.extraWaves = 
	{
		 -- difficulty level 1		
		{ 
			"logic/missions/survival/attack_level_1_id_1_magma_alpha.logic",
			"logic/missions/survival/attack_level_1_id_2_magma_alpha.logic",
		},
	
		 -- difficulty level 2
		{ 			
			"logic/missions/survival/attack_level_2_id_1_magma_alpha.logic",
			"logic/missions/survival/attack_level_2_id_2_magma_alpha.logic",
		},

		 -- difficulty level 3
		{ 
			"logic/missions/survival/attack_level_3_id_1_magma_alpha.logic",
			"logic/missions/survival/attack_level_3_id_2_magma_alpha.logic",
		},

		 -- difficulty level 4
		{ 			
			"logic/missions/survival/attack_level_4_id_1_magma_alpha.logic",
			"logic/missions/survival/attack_level_4_id_2_magma_alpha.logic",
			"logic/missions/survival/attack_level_4_id_3_alpha.logic",
		},

		 -- difficulty level 5
		{ 
			"logic/missions/survival/attack_level_5_id_1_magma_alpha.logic",
			"logic/missions/survival/attack_level_5_id_2_magma_alpha.logic",	
			"logic/missions/survival/attack_level_5_id_3_alpha.logic",	
			"logic/missions/survival/attack_level_5_id_4_magma_alpha.logic",
			"logic/missions/survival/attack_boss_magmoth.logic",			
		},

		 -- difficulty level 6
		{ 
			"logic/missions/survival/attack_level_6_id_1_magma_alpha.logic",
			"logic/missions/survival/attack_level_6_id_2_magma_alpha.logic",		
			"logic/missions/survival/attack_level_6_id_3_alpha.logic",		
			"logic/missions/survival/attack_level_6_id_4_magma_alpha.logic",
			"logic/missions/survival/attack_level_6_id_5_magma_alpha.logic",
			"logic/missions/survival/attack_boss_krocoon.logic",
		},

		 -- difficulty level 7
		{ 
			"logic/missions/survival/attack_level_7_id_1_magma_alpha.logic",
			"logic/missions/survival/attack_level_7_id_2_magma_alpha.logic",		
			"logic/missions/survival/attack_level_7_id_3_alpha.logic",		
			"logic/missions/survival/attack_level_7_id_4_magma_alpha.logic",	
			"logic/missions/survival/attack_level_7_id_5_magma_alpha.logic",	
			"logic/missions/survival/attack_boss_magmoth.logic",
		},

		 -- difficulty level 8
		{ 
			"logic/missions/survival/attack_level_8_id_1_magma_alpha.logic",
			"logic/missions/survival/attack_level_8_id_2_magma_alpha.logic",		
			"logic/missions/survival/attack_level_8_id_3_alpha.logic",		
			"logic/missions/survival/attack_level_8_id_4_magma_alpha.logic",	
			"logic/missions/survival/attack_level_8_id_5_magma_alpha.logic",	
			"logic/missions/survival/attack_boss_gnerot.logic",
		},

		 -- difficulty level 9
		{ 
			"logic/missions/survival/attack_level_8_id_1_magma_alpha.logic",
			"logic/missions/survival/attack_level_8_id_2_magma_alpha.logic",
			"logic/missions/survival/attack_level_8_id_3_alpha.logic",
			"logic/missions/survival/attack_level_8_id_4_magma_alpha.logic",
			"logic/missions/survival/attack_level_8_id_5_magma_alpha.logic",
			"logic/missions/survival/attack_boss_gnerot.logic",
		},
	}

    return rules;
end