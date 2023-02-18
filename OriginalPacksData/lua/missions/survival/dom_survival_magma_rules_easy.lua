return function()
    local rules = require("lua/missions/survival/dom_survival_magma_rules_default.lua")()

	rules.maxObjectivesAtOnce = 1

	rules.timeToNextDifficultyLevel = 
	{			
		300, -- difficulty level 1
		720, -- difficulty level 2
		720, -- difficulty level 3	
		720, -- difficulty level 4
		720, -- difficulty level 5
		720, -- difficulty level 6
		720, -- difficulty level 7
		720, -- difficulty level 8
		720, -- difficulty level 9
	}
	
	rules.nextSpawnIntervalOnDifficultyLevel = 
	{			
		480,  -- difficulty level 1
		480,  -- difficulty level 2
		480,  -- difficulty level 3
		480,  -- difficulty level 4	
		480,  -- difficulty level 5	
		480,  -- difficulty level 6	
		480,  -- difficulty level 7
		480,  -- difficulty level 8	
		480,  -- difficulty level 9	
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
	
	--rules.buildingsUpgradeStartsLogic = 
	--{			
	--	{ name = "headquarters_lvl_2", logic = "logic/hq_upgrade/upgrade_lvl1_easy.logic" },   
	--	{ name = "headquarters_lvl_3", logic = "logic/hq_upgrade/upgrade_lvl2_easy.logic" },   
	--	{ name = "headquarters_lvl_4", logic = "logic/hq_upgrade/upgrade_lvl3_easy.logic" },   
	--}

    return rules;
end