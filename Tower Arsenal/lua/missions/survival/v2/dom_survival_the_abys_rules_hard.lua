return function()
    local rules = require("lua/missions/survival/v2/dom_survival_the_abys_rules_default.lua")()

	rules.timeToNextDifficultyLevel = 
	{			
		500, -- difficulty level 1
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
		2,  -- difficulty level 1
		2,  -- difficulty level 2
		3,  -- difficulty level 3
		3,  -- difficulty level 4
		4,  -- difficulty level 5
		4,  -- difficulty level 6
		5,  -- difficulty level 7
		5,  -- difficulty level 8
		6,  -- difficulty level 9
	}
	
	rules.buildingsUpgradeStartsLogic = 
	{			
		{ name = "headquarters_lvl_2", level = 1, prepareTime = 130, entryLogic = "logic/dom/hq_upgrade_level_1_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_1_exit.logic" },   
		{ name = "headquarters_lvl_3", level = 1, prepareTime = 130, entryLogic = "logic/dom/hq_upgrade_level_2_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_2_exit.logic" },   
		{ name = "headquarters_lvl_4", level = 1, prepareTime = 130, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
		{ name = "headquarters_lvl_5", level = 2, prepareTime = 130, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
		{ name = "headquarters_lvl_6", level = 2, prepareTime = 130, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
		{ name = "headquarters_lvl_7", level = 2, prepareTime = 130, entryLogic = "logic/dom/hq_upgrade_level_3_entry.logic", exitLogic = "logic/dom/hq_upgrade_level_3_exit.logic" },   
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

	rules.multiplayerWaves = 
	{
		 -- difficulty level 1		
		{ 
			additionalWaves = -1, -- Additional Waves count = 1 + additionalWaves - regardless of player number. Multiplayer Additional waves are disabled in single player mode. Check dom_mananger:GetMultiplayerAttackCount for actual code
			waves = 
			{
				{ name="logic/missions/survival/attack_boss_ArcticIslands.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=350.0},
			}
		},
	
		 -- difficulty level 2
		{ 
			additionalWaves = 0,
			waves = 
			{
				{ name="logic/missions/survival/attack_boss_ArcticIslands.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=384.0},
			}
		},
		 -- difficulty level 3
		{ 
			additionalWaves = 0,
			waves = 
			{
				{ name="logic/missions/survival/attack_boss_ArcticIslands.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=420.0},
			}
		},

		 -- difficulty level 4
		{ 
			additionalWaves = 0,
			waves = 
			{
				{ name="logic/missions/survival/attack_boss_ArcticIslands.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=500.0},
			}
		},

		 -- difficulty level 5
		{ 
			additionalWaves = 1,
			waves = 
			{
				{ name="logic/missions/survival/attack_boss_ArcticIslands.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},
			}
		},

		 -- difficulty level 6
		{ 
			additionalWaves = 1,
			waves = 
			{
				{ name="logic/missions/survival/attack_boss_ArcticIslands.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},
			}
		},

		 -- difficulty level 7
		{ 
			additionalWaves = 1,
			waves = 
			{
				"logic/missions/survival/attack_boss_ArcticIslands.logic"
			}
		},

		 -- difficulty level 8
		{ 
			additionalWaves = 1,
			waves = 
			{
				"logic/missions/survival/attack_boss_ArcticIslands.logic"
			}
		},

		 -- difficulty level 9
		{ 
			additionalWaves = 1,
			waves = 
			{
				"logic/missions/survival/attack_boss_ArcticIslands.logic"
			}
		},
	}
	
	rules.waves = 
	{
		["default"] =
		{
			-- difficulty level 1		
			{ 
				{ name="logic/missions/survival/arctic/attack_level_1_id_1_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=350.0},
				{ name="logic/missions/survival/arctic/attack_level_1_id_1_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=350.0},
				{ name="logic/missions/survival/arctic/attack_level_1_id_2_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=350.0},
				{ name="logic/missions/survival/arctic/attack_level_1_id_2_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=350.0},
			},
	
			 -- difficulty level 2
			{ 			
				{ name="logic/missions/survival/arctic/attack_level_2_id_1_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=384.0},
				{ name="logic/missions/survival/arctic/attack_level_2_id_1_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=384.0},
				{ name="logic/missions/survival/arctic/attack_level_2_id_2_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=384.0},
				{ name="logic/missions/survival/arctic/attack_level_2_id_2_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=384.0},
			},

			 -- difficulty level 3
			{ 
				{ name="logic/missions/survival/arctic/attack_level_3_id_1_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=420.0},
				{ name="logic/missions/survival/arctic/attack_level_3_id_1_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=420.0},
				{ name="logic/missions/survival/arctic/attack_level_3_id_2_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=420.0},				
				{ name="logic/missions/survival/arctic/attack_level_3_id_2_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=420.0},				
			},

			 -- difficulty level 4
			{ 			
				{ name="logic/missions/survival/arctic/attack_level_4_id_1_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=500.0},
				{ name="logic/missions/survival/arctic/attack_level_4_id_1_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=500.0},
				{ name="logic/missions/survival/arctic/attack_level_4_id_2_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=500.0},
				{ name="logic/missions/survival/arctic/attack_level_4_id_2_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=500.0},
				{ name="logic/missions/survival/arctic/attack_level_4_id_3_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=500.0},				
				{ name="logic/missions/survival/arctic/attack_level_4_id_3_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=500.0},				
			},

			 -- difficulty level 5
			{ 
				{ name="logic/missions/survival/arctic/attack_level_5_id_1_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},
				{ name="logic/missions/survival/arctic/attack_level_5_id_1_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},
				{ name="logic/missions/survival/arctic/attack_level_5_id_2_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},
				{ name="logic/missions/survival/arctic/attack_level_5_id_2_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},
				{ name="logic/missions/survival/arctic/attack_level_5_id_3_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},							
				{ name="logic/missions/survival/arctic/attack_level_5_id_3_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},							
			},

			 -- difficulty level 6
			{ 
				{ name="logic/missions/survival/arctic/attack_level_6_id_1_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=0, target_max_radius=700.0},
				{ name="logic/missions/survival/arctic/attack_level_6_id_1_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=0, target_max_radius=700.0},
				{ name="logic/missions/survival/arctic/attack_level_6_id_1_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=0, target_max_radius=700.0},
				{ name="logic/missions/survival/arctic/attack_level_6_id_2_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=0, target_max_radius=700.0},
				{ name="logic/missions/survival/arctic/attack_level_6_id_2_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=0, target_max_radius=700.0},
				{ name="logic/missions/survival/arctic/attack_level_6_id_2_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=0, target_max_radius=700.0},
				{ name="logic/missions/survival/arctic/attack_level_6_id_3_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=0, target_max_radius=700.0},							
				{ name="logic/missions/survival/arctic/attack_level_6_id_3_arctic.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=0, target_max_radius=700.0},							
				{ name="logic/missions/survival/arctic/attack_level_6_id_3_arctic_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=0, target_max_radius=700.0},							
			},

			 -- difficulty level 7
			{ 
				"logic/missions/survival/arctic/attack_level_7_id_1_arctic.logic",
				"logic/missions/survival/arctic/attack_level_7_id_1_arctic.logic",
				"logic/missions/survival/arctic/attack_level_7_id_1_arctic_alpha.logic",
				"logic/missions/survival/arctic/attack_level_7_id_2_arctic.logic",
				"logic/missions/survival/arctic/attack_level_7_id_2_arctic.logic",
				"logic/missions/survival/arctic/attack_level_7_id_2_arctic_alpha.logic",
				"logic/missions/survival/arctic/attack_level_7_id_3_arctic.logic",			
				"logic/missions/survival/arctic/attack_level_7_id_3_arctic.logic",			
				"logic/missions/survival/arctic/attack_level_7_id_3_arctic_alpha.logic",			
			},

			 -- difficulty level 8
			{ 
				"logic/missions/survival/arctic/attack_level_8_id_1_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_1_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_1_arctic_alpha.logic",
				"logic/missions/survival/arctic/attack_level_8_id_2_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_2_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_2_arctic_alpha.logic",
				"logic/missions/survival/arctic/attack_level_8_id_3_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_3_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_3_arctic_alpha.logic",
			},

			 -- difficulty level 9
			{ 
				"logic/missions/survival/arctic/attack_level_8_id_1_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_1_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_1_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_1_arctic_alpha.logic",
				"logic/missions/survival/arctic/attack_level_8_id_1_arctic_alpha.logic",
				"logic/missions/survival/arctic/attack_level_8_id_1_arctic_ultra.logic",
				"logic/missions/survival/arctic/attack_level_8_id_2_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_2_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_2_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_3_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_3_arctic.logic",
				"logic/missions/survival/arctic/attack_level_8_id_2_arctic_alpha.logic",
				"logic/missions/survival/arctic/attack_level_8_id_2_arctic_alpha.logic",
				"logic/missions/survival/arctic/attack_level_8_id_3_arctic_alpha.logic",
				"logic/missions/survival/arctic/attack_level_8_id_3_arctic_alpha.logic",
				"logic/missions/survival/arctic/attack_level_8_id_2_arctic_ultra.logic",
				"logic/missions/survival/arctic/attack_level_8_id_3_arctic_ultra.logic",
			},
		},
	}
	
	rules.extraWaves = 
	{
		 -- difficulty level 1		
		{ 
			"logic/missions/survival/attack_level_1_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_1_id_2_ArcticIslands_alpha.logic",
		},
	
		 -- difficulty level 2
		{ 			
			"logic/missions/survival/attack_level_2_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_2_id_2_ArcticIslands_alpha.logic",
		},
	
		 -- difficulty level 3
		{ 
			"logic/missions/survival/attack_level_3_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_3_id_2_ArcticIslands_alpha.logic",
		},
	
		 -- difficulty level 4
		{ 			
			"logic/missions/survival/attack_level_4_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_4_id_2_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_4_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_4_id_2_ArcticIslands_alpha.logic",
		},
	
		 -- difficulty level 5
		{ 
			"logic/missions/survival/attack_level_5_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_5_id_2_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_5_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_5_id_2_ArcticIslands_alpha.logic",
		},
	
		 -- difficulty level 6
		{ 
			"logic/missions/survival/attack_level_6_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_6_id_2_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_6_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_6_id_2_ArcticIslands_alpha.logic",
		},
	
		 -- difficulty level 7
		{ 
			"logic/missions/survival/attack_level_7_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_7_id_2_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_7_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_7_id_2_ArcticIslands_alpha.logic",
		},
	
		 -- difficulty level 8
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands_alpha.logic",
		},
	
		 -- difficulty level 9
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands_alpha.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands_alpha.logic",
		},
	}

	rules.bosses = 
	{
		 -- difficulty level 1		
		{ 
			additionalWaves = 1,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},
	
		 -- difficulty level 2
		{ 
			additionalWaves = 1,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},
		 -- difficulty level 3
		{ 
			additionalWaves = 1,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},

		 -- difficulty level 4
		{ 
			additionalWaves = 1,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},

		 -- difficulty level 5
		{ 
			additionalWaves = 1,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},

		 -- difficulty level 6
		{ 
			additionalWaves = 1,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},

		 -- difficulty level 7
		{ 
			additionalWaves = 1,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},

		 -- difficulty level 8
		{ 
			additionalWaves = 2,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},

		 -- difficulty level 9
		{ 
			additionalWaves = 2,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},
	}

    return rules;
end