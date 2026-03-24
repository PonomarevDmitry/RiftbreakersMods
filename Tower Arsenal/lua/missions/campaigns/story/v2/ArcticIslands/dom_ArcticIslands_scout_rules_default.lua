return function()
    local rules = {}

	rules.maxObjectivesAtOnce = 2
	rules.eventsPerIdleState = 1
	rules.eventsPerPrepareState = 1 -- [0,1]
	rules.pauseAttacks = true
	rules.prepareAttacks = true

	rules.gameEvents = 
	{
		{ action = "new_objective", type = "POSITIVE", gameStates="IDLE|STREAMING", minEventLevel = 3 }, -- new_objective is only an option in the streaming mode; do not try to pass it as NO_STREAMING
		{ action = "change_time_of_day", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 3 },
		{ action = "add_resource", type = "POSITIVE", gameStates = "ATTACK|IDLE|STREAMING", minEventLevel = 1, basePercentage = 30 },
		{ action = "remove_resource", type = "NEGATIVE", gameStates = "ATTACK|IDLE|STREAMING", minEventLevel = 1, basePercentage = 20 },
		{ action = "stronger_attack", type = "NEGATIVE", gameStates = "ATTACK|STREAMING", minEventLevel = 1, amount = 2 },
		{ action = "cancel_the_attack", type = "POSITIVE", gameStates = "ATTACK|STREAMING", minEventLevel = 1 },
		{ action = "unlock_research", type = "POSITIVE", gameStates = "ATTACK|IDLE|STREAMING", minEventLevel = 1 },
		{ action = "full_ammo", type = "POSITIVE", gameStates = "ATTACK|STREAMING", minEventLevel = 2 },
		{ action = "remove_ammo", type = "NEGATIVE", gameStates = "ATTACK|STREAMING", minEventLevel = 2 },
		{ action = "boss_attack", type = "NEGATIVE", gameStates = "ATTACK|STREAMING", minEventLevel = 4 },
		{ action = "shegret_attack", type = "NEGATIVE", gameStates="IDLE|STREAMING", minEventLevel = 4, maxEventLevel = 5, logicFile="logic/event/shegret_attack.logic", weight = 5, bindingParams = { attack_strength = "normal" } },
		{ action = "shegret_attack", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 4, maxEventLevel = 5, logicFile="logic/event/shegret_attack.logic", weight = 5, bindingParams = { attack_strength = "normal" } },
		{ action = "shegret_attack_hard", type = "NEGATIVE", gameStates="IDLE|STREAMING", minEventLevel = 6, maxEventLevel = 7, logicFile="logic/event/shegret_attack.logic", weight = 5, bindingParams = { attack_strength = "hard" } },
		{ action = "shegret_attack_hard", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 6, maxEventLevel = 7, logicFile="logic/event/shegret_attack.logic", weight = 5, bindingParams = { attack_strength = "hard" } },
		{ action = "shegret_attack_very_hard", type = "NEGATIVE", gameStates="IDLE|STREAMING", minEventLevel = 8, maxEventLevel = 9, logicFile="logic/event/shegret_attack.logic", weight = 5, bindingParams = { attack_strength = "very_hard" } },
		{ action = "shegret_attack_very_hard", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 8, maxEventLevel = 9, logicFile="logic/event/shegret_attack.logic", weight = 5, bindingParams = { attack_strength = "very_hard" } },
		{ action = "spawn_arctic_fog", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 4, logicFile="logic/weather/arctic_fog.logic", minTime = 60, maxTime = 120, weight = 3 },
		{ action = "spawn_arctic_fog", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 4, logicFile="logic/weather/arctic_fog.logic", minTime = 60, maxTime = 120, weight = 3 },
		{ action = "spawn_arctic_heavy_hail", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 4, logicFile="logic/weather/arctic_heavy_hail.logic", minTime = 60, maxTime = 120, weight = 6 },
		{ action = "spawn_arctic_heavy_hail", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 4, logicFile="logic/weather/arctic_heavy_hail.logic", minTime = 60, maxTime = 120, weight = 6 },
		{ action = "spawn_arctic_blizzard", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 1, logicFile="logic/weather/arctic_blizzard.logic", minTime = 60, maxTime = 120, weight = 0.2 },
		{ action = "spawn_arctic_blizzard", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 1, logicFile="logic/weather/arctic_blizzard.logic", minTime = 60, maxTime = 120, weight = 0.2 },
		{ action = "spawn_arctic_heavy_snow", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 1, logicFile="logic/weather/arctic_heavy_snow.logic", minTime = 60, maxTime = 120, weight = 0.8 },
		{ action = "spawn_arctic_heavy_snow", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 1, logicFile="logic/weather/arctic_heavy_snow.logic", minTime = 60, maxTime = 120, weight = 0.8 },		
		{ action = "spawn_arctic_rock_rain", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 4, logicFile="logic/weather/arctic_rock_rain.logic", minTime = 30, maxTime = 60, weight = 0.3 },
		{ action = "spawn_arctic_rock_rain", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 4, logicFile="logic/weather/arctic_rock_rain.logic", minTime = 30, maxTime = 60, weight = 0.3 },
		{ action = "spawn_cryogenic_tornado_near_player", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 4, logicFile="logic/weather/cryogenic_tornado_near_player.logic", weight = 2 },
		{ action = "spawn_cryogenic_tornado_near_player", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 4, logicFile="logic/weather/cryogenic_tornado_near_player.logic", weight = 2 },
		{ action = "spawn_cryogenic_tornado_near_base", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 4, logicFile="logic/weather/cryogenic_tornado_near_base.logic", weight = 0.25 },
		{ action = "spawn_cryogenic_tornado_near_base", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 4, logicFile="logic/weather/cryogenic_tornado_near_base.logic", weight = 0.25 },
		--{ action = "spawn_comet_boss_random_ta", type = "NEGATIVE", gameStates = "IDLE|STREAMING", minEventLevel = 8, logicFile="logic/event/comet_boss_random_ta.logic"  },
		--{ action = "spawn_comet_boss_random_ta", type = "NEGATIVE", gameStates = "IDLE|NO_STREAMING", minEventLevel = 8, logicFile="logic/event/comet_boss_random_ta.logic"  },
	}

	rules.addResourcesOnRunOut = 
	{

	}

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
		60,  -- difficulty level 1
		60,  -- difficulty level 2
		60,  -- difficulty level 3
		60,  -- difficulty level 4	
		60,  -- difficulty level 5	
		60,  -- difficulty level 6	
		60,  -- difficulty level 7
		60,  -- difficulty level 8	
		60,  -- difficulty level 9	
	}

	rules.buildingsUpgradeStartsLogic = 
	{			
  
	}

	rules.objectivesLogic = 
	{
	
	}

	rules.cooldownAfterAttacks = 
	{			
		0,  -- difficulty level 1
		0,  -- difficulty level 2
		0,  -- difficulty level 3
		0,  -- difficulty level 4	
		0,  -- difficulty level 5	
		0,  -- difficulty level 6	
		0,  -- difficulty level 7
		0,  -- difficulty level 8	
		0,  -- difficulty level 9	
	}

	rules.idleTime = 
	{			
		300,  -- difficulty level 1
		300,  -- difficulty level 2
		300,  -- difficulty level 3
		300,  -- difficulty level 4	
		300,  -- difficulty level 5	
		300,  -- difficulty level 6	
		300,  -- difficulty level 7
		300,  -- difficulty level 8	
		300,  -- difficulty level 9	
	}

	rules.maxAttackCountPerDifficulty = 
	{			
		0,  -- difficulty level 1
		0,  -- difficulty level 2
		0,  -- difficulty level 3		
		0,  -- difficulty level 4
		0,  -- difficulty level 5
		0,  -- difficulty level 6
		0,  -- difficulty level 7
		0,  -- difficulty level 8
		0,  -- difficulty level 9
	}
	
	rules.wavesEntryDefinitions =
	{
	}

	rules.waves = 
	{
		["default"] =
		{			
		},
	}

	rules.extraWaves = 
	{
	
	}

	rules.bosses = 
	{

	}

    return rules;
end