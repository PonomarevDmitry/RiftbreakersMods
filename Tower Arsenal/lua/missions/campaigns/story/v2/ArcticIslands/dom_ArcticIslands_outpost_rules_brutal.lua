return function()
    local rules = require("lua/missions/campaigns/story/v2/ArcticIslands/dom_ArcticIslands_outpost_rules_default.lua")()
	
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
		{ level = 4, minLevel = 7, prepareTime = 300, entryLogic = "logic/dom/major_attack_1_entry.logic", exitLogic = "logic/dom/major_attack_1_exit.logic" },     
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
				{ name = "logic/missions/survival/attack_level_1_id_1_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=350.0},
				{ name = "logic/missions/survival/attack_level_1_id_1_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=350.0},				
				{ name = "logic/missions/survival/attack_level_1_id_2_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=350.0},
				{ name = "logic/missions/survival/attack_level_1_id_2_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=350.0},
			},
	
			 -- difficulty level 2
			{
				{ name = "logic/missions/survival/attack_level_2_id_1_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=384.0},
				{ name = "logic/missions/survival/attack_level_2_id_1_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=384.0},			
				{ name = "logic/missions/survival/attack_level_2_id_2_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=384.0},
				{ name = "logic/missions/survival/attack_level_2_id_2_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=384.0},
			},

			 -- difficulty level 3
			{ 				
				{ name = "logic/missions/survival/attack_level_3_id_1_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=420.0},
				{ name = "logic/missions/survival/attack_level_3_id_1_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=420.0},				
				{ name = "logic/missions/survival/attack_level_3_id_2_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=420.0},
				{ name = "logic/missions/survival/attack_level_3_id_2_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=420.0},
			},

			 -- difficulty level 4
			{	
				{ name = "logic/missions/survival/attack_level_4_id_1_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=500.0},
				{ name = "logic/missions/survival/attack_level_4_id_1_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=500.0},			
				{ name = "logic/missions/survival/attack_level_4_id_2_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=500.0},
				{ name = "logic/missions/survival/attack_level_4_id_2_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=500.0},				
				{ name = "logic/missions/survival/attack_level_4_id_4_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=500.0},
				{ name = "logic/missions/survival/attack_level_4_id_4_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=500.0},
			},

			 -- difficulty level 5
			{ 				
				{ name = "logic/missions/survival/attack_level_5_id_1_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},
				{ name = "logic/missions/survival/attack_level_5_id_1_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},				
				{ name = "logic/missions/survival/attack_level_5_id_2_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},			
				{ name = "logic/missions/survival/attack_level_5_id_2_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},					
				{ name = "logic/missions/survival/attack_level_4_id_3_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},
				{ name = "logic/missions/survival/attack_level_4_id_3_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},							
				{ name = "logic/missions/survival/attack_level_5_id_4_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},
				{ name = "logic/missions/survival/attack_level_5_id_4_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=600.0},			
			},

			 -- difficulty level 6
			{
				{ name = "logic/missions/survival/attack_level_6_id_1_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},
				{ name = "logic/missions/survival/attack_level_6_id_1_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},
				{ name = "logic/missions/survival/attack_level_6_id_1_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},			
				{ name = "logic/missions/survival/attack_level_6_id_2_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},			
				{ name = "logic/missions/survival/attack_level_6_id_2_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},			
				{ name = "logic/missions/survival/attack_level_6_id_2_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},					
				{ name = "logic/missions/survival/attack_level_5_id_3_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},			
				{ name = "logic/missions/survival/attack_level_5_id_3_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},			
				{ name = "logic/missions/survival/attack_level_5_id_3_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},					
				{ name = "logic/missions/survival/attack_level_6_id_4_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},			
				{ name = "logic/missions/survival/attack_level_6_id_4_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},			
				{ name = "logic/missions/survival/attack_level_6_id_4_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},					
				{ name = "logic/missions/survival/attack_level_6_id_5_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},			
				{ name = "logic/missions/survival/attack_level_6_id_5_ArcticIslands_alpha.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},			
				{ name = "logic/missions/survival/attack_level_6_id_5_ArcticIslands_ultra.logic", spawn_type="RandomBorderInDistance", spawn_type_value=nil, target_type="Type", target_type_value="headquarters", target_min_radius=180.0, target_max_radius=700.0},				
			},

			 -- difficulty level 7
			{ 
				--"logic/missions/survival/attack_level_7_id_1_ArcticIslands.logic",
				--"logic/missions/survival/attack_level_7_id_1_ArcticIslands.logic",
				--"logic/missions/survival/attack_level_7_id_1_ArcticIslands.logic",
				"logic/missions/survival/attack_level_7_id_1_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_7_id_1_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_7_id_1_ArcticIslands_ultra.logic",
				--"logic/missions/survival/attack_level_7_id_2_ArcticIslands.logic",
				--"logic/missions/survival/attack_level_7_id_2_ArcticIslands.logic",
				--"logic/missions/survival/attack_level_7_id_2_ArcticIslands.logic",
				"logic/missions/survival/attack_level_7_id_2_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_7_id_2_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_7_id_2_ArcticIslands_ultra.logic",
				--"logic/missions/survival/attack_level_6_id_3_ArcticIslands.logic",
				--"logic/missions/survival/attack_level_6_id_3_ArcticIslands.logic",
				--"logic/missions/survival/attack_level_6_id_3_ArcticIslands.logic",
				"logic/missions/survival/attack_level_6_id_3_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_6_id_3_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_6_id_3_ArcticIslands_ultra.logic",
				--"logic/missions/survival/attack_level_7_id_4_ArcticIslands.logic",
				--"logic/missions/survival/attack_level_7_id_4_ArcticIslands.logic",
				--"logic/missions/survival/attack_level_7_id_4_ArcticIslands.logic",
				"logic/missions/survival/attack_level_7_id_4_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_7_id_4_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_7_id_4_ArcticIslands_ultra.logic",
				--"logic/missions/survival/attack_level_7_id_5_ArcticIslands.logic",
				--"logic/missions/survival/attack_level_7_id_5_ArcticIslands.logic",
				--"logic/missions/survival/attack_level_7_id_5_ArcticIslands.logic",
				"logic/missions/survival/attack_level_7_id_5_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_7_id_5_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_7_id_5_ArcticIslands_ultra.logic",
			},

			 -- difficulty level 8
			{ 
				--"logic/missions/survival/attack_level_8_id_1_ArcticIslands.logic",
				--"logic/missions/survival/attack_level_8_id_1_ArcticIslands.logic",
				--"logic/missions/survival/attack_level_8_id_1_ArcticIslands.logic",
				"logic/missions/survival/attack_level_8_id_1_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_ArcticIslands_ultra.logic",
				--"logic/missions/survival/attack_level_8_id_2.logic",
				--"logic/missions/survival/attack_level_8_id_2.logic",
				--"logic/missions/survival/attack_level_8_id_2.logic",
				"logic/missions/survival/attack_level_8_id_2_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_ArcticIslands_ultra.logic",
				--"logic/missions/survival/attack_level_7_id_3.logic",
				--"logic/missions/survival/attack_level_7_id_3.logic",
				--"logic/missions/survival/attack_level_7_id_3.logic",
				"logic/missions/survival/attack_level_7_id_3_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_7_id_3_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_7_id_3_ArcticIslands_ultra.logic",
				--"logic/missions/survival/attack_level_8_id_4.logic",
				--"logic/missions/survival/attack_level_8_id_4.logic",
				--"logic/missions/survival/attack_level_8_id_4.logic",
				"logic/missions/survival/attack_level_8_id_4_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_4_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_4_ArcticIslands_ultra.logic",
				--"logic/missions/survival/attack_level_8_id_5.logic",
				--"logic/missions/survival/attack_level_8_id_5.logic",
				--"logic/missions/survival/attack_level_8_id_5.logic",
				"logic/missions/survival/attack_level_8_id_5_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_5_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_5_ArcticIslands_ultra.logic",
			},

			 -- difficulty level 9
			{ 
				--"logic/missions/survival/attack_level_8_id_1.logic",
				--"logic/missions/survival/attack_level_8_id_1.logic",
				--"logic/missions/survival/attack_level_8_id_1.logic",
				--"logic/missions/survival/attack_level_8_id_1.logic",
				"logic/missions/survival/attack_level_8_id_1_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_1_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_8_id_1_ArcticIslands_ultra.logic",
				--"logic/missions/survival/attack_level_8_id_2.logic",
				--"logic/missions/survival/attack_level_8_id_2.logic",
				--"logic/missions/survival/attack_level_8_id_2.logic",
				--"logic/missions/survival/attack_level_8_id_2.logic",
				"logic/missions/survival/attack_level_8_id_2_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_2_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_8_id_2_ArcticIslands_ultra.logic",
				--"logic/missions/survival/attack_level_8_id_3.logic",
				--"logic/missions/survival/attack_level_8_id_3.logic",
				--"logic/missions/survival/attack_level_8_id_3.logic",
				--"logic/missions/survival/attack_level_8_id_3.logic",
				"logic/missions/survival/attack_level_8_id_3_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_3_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_3_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_3_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_8_id_3_ArcticIslands_ultra.logic",
				--"logic/missions/survival/attack_level_8_id_4.logic",
				--"logic/missions/survival/attack_level_8_id_4.logic",
				--"logic/missions/survival/attack_level_8_id_4.logic",
				--"logic/missions/survival/attack_level_8_id_4.logic",
				"logic/missions/survival/attack_level_8_id_4_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_4_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_4_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_4_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_8_id_4_ArcticIslands_ultra.logic",
				--"logic/missions/survival/attack_level_8_id_5.logic",
				--"logic/missions/survival/attack_level_8_id_5.logic",
				--"logic/missions/survival/attack_level_8_id_5.logic",
				--"logic/missions/survival/attack_level_8_id_5.logic",
				"logic/missions/survival/attack_level_8_id_5_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_5_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_5_ArcticIslands_alpha.logic",
				"logic/missions/survival/attack_level_8_id_5_ArcticIslands_ultra.logic",
				"logic/missions/survival/attack_level_8_id_5_ArcticIslands_ultra.logic",
			},
		},
		
	}

	rules.extraWaves = 
	{
		 -- difficulty level 1		
		{ 
			"logic/missions/survival/attack_level_1_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_1_id_2_ArcticIslands_ultra.logic",
		},
	
		 -- difficulty level 2
		{ 			
			"logic/missions/survival/attack_level_2_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_2_id_2_ArcticIslands_ultra.logic",
		},
	
		 -- difficulty level 3
		{ 
			"logic/missions/survival/attack_level_3_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_3_id_2_ArcticIslands_ultra.logic",
		},
	
		 -- difficulty level 4
		{ 			
			"logic/missions/survival/attack_level_4_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_4_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_4_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_4_id_2_ArcticIslands_ultra.logic",
		},
	
		 -- difficulty level 5
		{ 
			"logic/missions/survival/attack_level_5_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_5_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_5_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_5_id_2_ArcticIslands_ultra.logic",
		},
	
		 -- difficulty level 6
		{ 
			"logic/missions/survival/attack_level_6_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_6_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_6_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_6_id_2_ArcticIslands_ultra.logic",
		},
	
		 -- difficulty level 7
		{ 
			"logic/missions/survival/attack_level_7_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_7_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_7_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_7_id_2_ArcticIslands_ultra.logic",
		},
	
		 -- difficulty level 8
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands_ultra.logic",
		},
	
		 -- difficulty level 9
		{ 
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_8_id_1_ArcticIslands_ultra.logic",
			"logic/missions/survival/attack_level_8_id_2_ArcticIslands_ultra.logic",
		},
	}

	rules.bosses = 
	{
		 -- difficulty level 1		
		{ 
			additionalWaves = 0,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},
	
		 -- difficulty level 2
		{ 
			additionalWaves = 0,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},
		 -- difficulty level 3
		{ 
			additionalWaves = 0,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},

		 -- difficulty level 4
		{ 
			additionalWaves = 0,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},

		 -- difficulty level 5
		{ 
			additionalWaves = 0,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},

		 -- difficulty level 6
		{ 
			additionalWaves = 0,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},

		 -- difficulty level 7
		{ 
			additionalWaves = 0,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},

		 -- difficulty level 8
		{ 
			additionalWaves = 1,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},

		 -- difficulty level 9
		{ 
			additionalWaves = 1,
			waves = 
			{
			"logic/missions/survival/attack_cosmic_boss_dynamic.logic",
			}
		},
	}

    return rules;
end