require("lua/utils/table_utils.lua")

local anoryxian_boss_base = require("lua/units/ground/anoryxian_boss_base.lua")
class 'anoryxian_boss_ultra' ( anoryxian_boss_base )

function anoryxian_boss_ultra:__init()
	anoryxian_boss_base.__init(self, self)
end

function anoryxian_boss_ultra:HealthSetup()
	self.healthSetup = 
	{
		--[[
			This table defines the maximum health values for the boss
			based on creature difficulty (rows) and player count (columns).

			Format: healthSetup[difficulty][playerCount]
			- 'difficulty' ranges from 1 to 10 (table rows)
			- 'playerCount' ranges from 1 to 4 (table columns)

			For example:
				healthSetup[3][2] returns 88000,
				which means for difficulty level 3 and 2 players, the boss will have 88000 HP.
		]]
		[1] = {105000, 135000, 165000, 265000},
		[2] = {114000, 146000, 179000, 279000},
		[3] = {123000, 158000, 193000, 293000},
		[4] = {131000, 169000, 206000, 306000},
		[5] = {140000, 180000, 220000, 320000},
		[6] = {149000, 191000, 234000, 334000},
		[7] = {158000, 203000, 248000, 348000},
		[8] = {166000, 214000, 261000, 361000},
		[9] = {175000, 225000, 275000, 375000},
		[10] = {184000, 236000, 289000, 389000}
	}
end

function anoryxian_boss_ultra:_OnInit()

	self.config = 
	{
		spawnPointGroupName			= "Boss",
		unitSpawnerSpawnName		= "unit_spawner",
		interactiveSpawnName		= "boss_interactive",
		shieldSpawnName				= "boss_shield",
		towerSpawnName				= "boss_tower",		
		introLogicFile				= "logic/missions/campaigns/dlc_2/the_abys_boss_intro.logic",
		fightLogicFile				= "logic/missions/campaigns/dlc_2/caverns_boss_fight.logic",
		outroLogicFile				= "logic/missions/campaigns/story/the_abys_boss_ultra_outro.logic",
		cameraDistance              = 45
	}

	self.specialAttackCooldown = 
	{
		{ name = self.SPECIAL_ATTACK_AVALANCHE, cooldown = 45 },
		{ name = self.SPECIAL_ATTACK_EGGS, cooldown = 35 },
		{ name = self.SPECIAL_ATTACK_HEAL, cooldown = 60 },
		{ name = self.SPECIAL_ATTACK_WAVE, cooldown = 40 },
	}

	self.fightConfig = 
	{
		{
			hpMax = 1,
			hpMin = 0.85,
			endPhaseLogicFile = "logic/missions/campaigns/dlc_2/caverns_boss_end_phase_1.logic",

			[self.SPECIAL_ATTACK_TOWER]      = { blueprint = "units/ground/anoryxian_boss_ultra_tower", count = 1, duration = 6 },
			[self.SPECIAL_ATTACK_FIREWALL]   = { blueprint = "units/ground/anoryxian_boss_ultra/firewall", count = 25, spread = 3 },
			[self.SPECIAL_ATTACK_PROJECTILE] = { count = 1, spread = 1 },
			
			--[self.SPECIAL_ATTACK_HEAL]       = { heal_when_min_health = 0.45, heal_percentage = 50000, heal_speed_in_sec = 5000 },
			[self.SPECIAL_ATTACK_WAVE] = 
			{ 
				count = 1,	
			
				["attacks"] = 
				{
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_1.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_2.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_3.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_crawlog.logic",
				}
			}
		},
		
		{
			hpMax = 0.85,
			hpMin = 0.60,
			endPhaseLogicFile = "logic/missions/campaigns/dlc_2/caverns_boss_end_phase_2.logic",

			[self.SPECIAL_ATTACK_TOWER]      = { blueprint = "units/ground/anoryxian_boss_ultra_tower", count = 1, duration = 6 },
			[self.SPECIAL_ATTACK_FIREWALL]   = { blueprint = "units/ground/anoryxian_boss_ultra/firewall", count = 25, spread = 3 },
			[self.SPECIAL_ATTACK_PROJECTILE] = { count = 1, spread = 1 },
			
			--[self.SPECIAL_ATTACK_HEAL]       = { heal_when_min_health = 0.45, heal_percentage = 50000, heal_speed_in_sec = 5000 },
			[self.SPECIAL_ATTACK_EGGS]       = { blueprint = "units/ground/egg_anoryxian_boss", count = 3, distanceBetween = 1, randomOffset = 10 },
			[self.SPECIAL_ATTACK_WAVE] = 
			{ 
				count = 1,	
			
				["attacks"] = 
				{
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_3.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_4.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_3.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_4.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_crawlog.logic",
				}
			}
		},

		{
			hpMax = 0.60,
			hpMin = 0.25,
			endPhaseLogicFile = "logic/missions/campaigns/dlc_2/caverns_boss_end_phase_3.logic",

			[self.SPECIAL_ATTACK_TOWER]      = { blueprint = "units/ground/anoryxian_boss_ultra_tower", count = 2, duration = 6 },
			[self.SPECIAL_ATTACK_FIREWALL]   = { blueprint = "units/ground/anoryxian_boss_ultra/firewall", count = 35, spread = 3 },
			[self.SPECIAL_ATTACK_PROJECTILE] = { count = 2, spread = 3 },
			
			--[self.SPECIAL_ATTACK_HEAL]       = { heal_when_min_health = 0.55, heal_percentage = 50000, heal_speed_in_sec = 5000 },
			[self.SPECIAL_ATTACK_AVALANCHE]  = { blueprint = "weather/stalactite_anoryxian", duration = 10, radius = 1, spawnTime = 1 },			
			[self.SPECIAL_ATTACK_EGGS]       = { blueprint = "units/ground/egg_anoryxian_boss", count = 3, distanceBetween = 1, randomOffset = 10 },
			[self.SPECIAL_ATTACK_WAVE] = 
			{ 
				count = 3,	

				["attacks"] = 
				{
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_4.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_3.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_4.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_3.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_4.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_crawlog.logic",
				}
			}
		},

		{
			hpMax = 0.25,
			hpMin = 0,

			[self.SPECIAL_ATTACK_TOWER]      = { blueprint = "units/ground/anoryxian_boss_ultra_tower", count = 3, duration = 6 },
			[self.SPECIAL_ATTACK_FIREWALL]   = { blueprint = "units/ground/anoryxian_boss_ultra/firewall", count = 45, spread = 3 },
			[self.SPECIAL_ATTACK_PROJECTILE] = { count = 3, spread = 3 },
			
			[self.SPECIAL_ATTACK_HEAL]       = { heal_when_min_health = 0.55, heal_percentage = 50000, heal_speed_in_sec = 5000 },
			[self.SPECIAL_ATTACK_AVALANCHE]  = { blueprint = "weather/stalactite_anoryxian", duration = 10, radius = 1, spawnTime = 0.75 },
			[self.SPECIAL_ATTACK_EGGS]       = { blueprint = "units/ground/egg_anoryxian_boss", count = 4, distanceBetween = 1, randomOffset = 10 },
			[self.SPECIAL_ATTACK_WAVE] = 
			{ 
				count = 3,	

				["attacks"] = 
				{
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_3.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_4.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_3.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_4.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_5.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_crawlog.logic",
				}
			}
		},
	}

end

return anoryxian_boss_ultra
