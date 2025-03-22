return function()
    local rules = {}

	rules.maxObjectivesAtOnce = 1
	rules.eventsPerIdleState = 1
	rules.eventsPerPrepareState = 1 -- [0,1]

	rules.gameEvents = 
	{
		{ action = "shegret_attack", type = "NEGATIVE", gameStates="IDLE|STREAMING", minEventLevel = 2, logicFile="logic/event/shegret_attack.logic", weight = 1 },
		{ action = "shegret_attack", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/event/shegret_attack.logic", weight = 1 },
		{ action = "cosmic_kermon_attack", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, maxEventLevel = 5, logicFile="logic/event/cosmic_kermon_attack.logic", weight = 2 },
		{ action = "cosmic_kermon_attack", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, maxEventLevel = 5, logicFile="logic/event/cosmic_kermon_attack.logic", weight = 2 },
		{ action = "cosmic_phirian_attack", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, maxEventLevel = 5, logicFile="logic/event/cosmic_phirian_attack.logic", weight = 3 },
		{ action = "cosmic_phirian_attack", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, maxEventLevel = 5, logicFile="logic/event/cosmic_phirian_attack.logic", weight = 3 },
		{ action = "spawn_comet_boss_cosmic_hedroner", type = "NEGATIVE", gameStates = "ATTACK|IDLE|STREAMING", minEventLevel = 1, logicFile="logic/event/comet_boss_cosmic_hedroner", weight = 2 },
		{ action = "spawn_comet_boss_cosmic_hedroner", type = "NEGATIVE", gameStates = "IDLE|NO_STREAMING", minEventLevel = 1, logicFile="logic/event/comet_boss_cosmic_hedroner", weight = 2 },
		{ action = "spawn_cosmic_meteor_shower", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/comsic_meteor_shower.logic", minTime = 30, maxTime = 60, weight = 2 },
		{ action = "spawn_cosmic_meteor_shower", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/cosmic_meteor_shower.logic", minTime = 30, maxTime = 60, weight = 2 },
		{ action = "spawn_cosmic_tornado_near_player", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 1, maxEventLevel = 2, logicFile="logic/weather/cosmic_tornado_near_player.logic", weight = 0.5 },
		{ action = "spawn_cosmic_tornado_near_player", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 1, maxEventLevel = 2, logicFile="logic/weather/cosmic_tornado_near_player.logic", weight = 0.5 },
		{ action = "spawn_cosmic_tornado_near_base", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/cosmic_tornado_near_base.logic", minTime = 30, maxTime = 60, weight = 0.5 },
		{ action = "spawn_cosmic_tornado_near_base", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/cosmic_tornado_near_base.logic", minTime = 30, maxTime = 60, weight = 0.5 },
		{ action = "spawn_cryogenic_tornado_near_player", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 1, maxEventLevel = 2, logicFile="logic/weather/cryogenic_tornado_near_player.logic", weight = 2 },
		{ action = "spawn_cryogenic_tornado_near_player", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 1, maxEventLevel = 2, logicFile="logic/weather/cryogenic_tornado_near_player.logic", weight = 2 },
		{ action = "spawn_cryogenic_tornado_near_base", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/cryogenic_tornado_near_base.logic", minTime = 15, maxTime = 30, weight = 0.5 },
		{ action = "spawn_cryogenic_tornado_near_base", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/cryogenic_tornado_near_base.logic", minTime = 15, maxTime = 30, weight = 0.5 },
		--{ action = "spawn_fog", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 1, logicFile="logic/weather/fog.logic", minTime = 60, maxTime = 120 },
		--{ action = "spawn_fog", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 1, logicFile="logic/weather/fog.logic", minTime = 60, maxTime = 120 },
		{ action = "spawn_thunderstorm", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 2, logicFile="logic/weather/thunderstorm.logic", minTime = 60, maxTime = 120 },
		{ action = "spawn_thunderstorm", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 2, logicFile="logic/weather/thunderstorm.logic", minTime = 60, maxTime = 120 },
		{ action = "spawn_cosmic_rock_rain", type = "NEGATIVE", gameStates="ATTACK|IDLE|STREAMING", minEventLevel = 1, logicFile="logic/weather/cosmic_rock_rain.logic", minTime = 15, maxTime = 30, weight = 1 },
		{ action = "spawn_cosmic_rock_rain", type = "NEGATIVE", gameStates="IDLE|NO_STREAMING", minEventLevel = 1, logicFile="logic/weather/cosmic_rock_rain.logic", minTime = 15, maxTime = 30, weight = 1 },
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