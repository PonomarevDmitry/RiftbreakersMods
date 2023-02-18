return function()
    local rules = require("lua/missions/campaigns/story/dom_headquarters_rules_default.lua")()
	
	rules.idleTimeBetweenAttacks = 
	{			
		1200,  -- difficulty level 1
		1200,  -- difficulty level 2
		1200,  -- difficulty level 3
		1200,  -- difficulty level 4	
		1200,  -- difficulty level 5	
		1200,  -- difficulty level 6	
		1200,  -- difficulty level 7
		1200,  -- difficulty level 8	
		1200,  -- difficulty level 9	
	}
	
	rules.timeToNextDifficultyLevel = 
	{			
		1200, -- difficulty level 1
		1200, -- difficulty level 2
		1200, -- difficulty level 3	
		2400, -- difficulty level 4
		2400, -- difficulty level 5
		2400, -- difficulty level 6
		2400, -- difficulty level 7
		2400, -- difficulty level 8
		2400, -- difficulty level 9
	}
	
	rules.maxAttackCountPerDifficulty = 
	{			
		1,  -- difficulty level 1
		1,  -- difficulty level 2
		1,  -- difficulty level 3		
		1,  -- difficulty level 4
		1,  -- difficulty level 5
		2,  -- difficulty level 6
		2,  -- difficulty level 7
		2,  -- difficulty level 8
		2,  -- difficulty level 9
	}

	rules.buildingsUpgradeStartsLogic = 
	{			
		{ name = "headquarters_lvl_2", logic = "logic/hq_upgrade/upgrade_lvl1_easy.logic" },   
		{ name = "headquarters_lvl_3", logic = "logic/hq_upgrade/upgrade_lvl2_easy.logic" },   
		{ name = "headquarters_lvl_4", logic = "logic/hq_upgrade/upgrade_lvl2.logic" },   
		{ name = "headquarters_lvl_5", logic = "logic/hq_upgrade/upgrade_lvl3_easy.logic" },   
		{ name = "headquarters_lvl_6", logic = "logic/hq_upgrade/upgrade_lvl3.logic" },   
		{ name = "headquarters_lvl_7", logic = "logic/hq_upgrade/upgrade_lvl3.logic" },   
	}

    return rules;
end