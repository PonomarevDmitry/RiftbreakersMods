return function()
    local rules = require("lua/missions/campaigns/story/v2/ice/dom_template_ice_resource_rules_default.lua")()
	
	rules.idleTime = 
	{			
		600,  -- difficulty level 1
		720,  -- difficulty level 2
		720,  -- difficulty level 3
		720,  -- difficulty level 4	
		780,  -- difficulty level 5	
		780,  -- difficulty level 6	
		900,  -- difficulty level 7
		900,  -- difficulty level 8	
		900,  -- difficulty level 9	
	}
	
	rules.timeToNextDifficultyLevel = 
	{			
		200, -- difficulty level 1
		450, -- difficulty level 2
		450, -- difficulty level 3	
		450, -- difficulty level 4
		600, -- difficulty level 5
		600, -- difficulty level 6
		600, -- difficulty level 7
		600, -- difficulty level 8
		600, -- difficulty level 9
	}
	
	rules.maxAttackCountPerDifficulty = 
	{			
		1,  -- difficulty level 1
		1,  -- difficulty level 2
		2,  -- difficulty level 3		
		2,  -- difficulty level 4
		2,  -- difficulty level 5
		2,  -- difficulty level 6
		2,  -- difficulty level 7
		2,  -- difficulty level 8
		3,  -- difficulty level 9
	}
	
	rules.objectivesLogic = 
	{
		{ name = "logic/objectives/kill_elite_dynamic.logic", minDifficultyLevel = 5 },
		{ name = "logic/objectives/destroy_nest_granan_ice_single.logic", minDifficultyLevel = 4, maxDifficultyLevel = 6 }, 
		{ name = "logic/objectives/destroy_nest_granan_ice_multiple.logic", minDifficultyLevel = 6 },		
		{ name = "logic/objectives/destroy_nest_kermon_ice_single.logic", minDifficultyLevel = 5, maxDifficultyLevel = 7 }, 
		{ name = "logic/objectives/destroy_nest_kermon_ice_multiple.logic", minDifficultyLevel = 7 },		
		{ name = "logic/objectives/destroy_nest_plutrodon_ice_single.logic", minDifficultyLevel = 6, maxDifficultyLevel = 8 }, 
		{ name = "logic/objectives/destroy_nest_plutrodon_ice_multiple.logic", minDifficultyLevel = 8 },		
	}

    return rules;
end