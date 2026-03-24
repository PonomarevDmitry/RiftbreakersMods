require("lua/utils/table_utils.lua")

local anoryxian_boss_base = require("lua/units/ground/anoryxian_boss_base.lua")
class 'anoryxian_boss_omega' ( anoryxian_boss_base )

function anoryxian_boss_omega:__init()
	anoryxian_boss_base.__init(self, self)
end

function anoryxian_boss_omega:HealthSetup()
	self.healthSetup = 
	{
		--[[
			This table defines the maximum health values for the boss
			based on creature difficulty (rows) and player count (columns).

			Format: healthSetup[difficulty][playerCount]
			- 'difficulty' ranges from 1 to 10 (table rows)
			- 'playerCount' ranges from 1 to 4 (table columns)

			For example:
				healthSetup[3][2] returns 123000,
				which means for difficulty level 3 and 2 players, the boss will have 123000 HP.
		]]
		[1]  = {205000, 235000, 265000, 365000},
		[2]  = {214000, 246000, 279000, 379000},
		[3]  = {223000, 258000, 293000, 393000},
		[4]  = {231000, 269000, 306000, 406000},
		[5]  = {240000, 280000, 320000, 420000},
		[6]  = {249000, 291000, 334000, 434000},
		[7]  = {258000, 303000, 348000, 448000},
		[8]  = {266000, 314000, 361000, 461000},
		[9]  = {275000, 325000, 375000, 475000},
		[10] = {284000, 336000, 389000, 489000}
	}
end

function anoryxian_boss_omega:_OnInit()

	self.config = 
	{
		spawnPointGroupName			= "Boss",
		unitSpawnerSpawnName		= "unit_spawner",
		interactiveSpawnName		= "boss_interactive",
		shieldSpawnName				= "boss_shield",
		towerSpawnName				= "boss_tower",		
		introLogicFile				= "logic/missions/campaigns/dlc_2/the_abys_boss_omega_intro.logic",
		fightLogicFile				= "logic/missions/campaigns/dlc_2/caverns_boss_fight.logic",
		outroLogicFile				= "logic/missions/campaigns/story/the_abys_boss_omega_outro.logic",
		--extraHealPercentageOnPhase  = 20,
		cameraDistance              = 45
	}

	self.specialAttackCooldown = 
	{
		{ name = self.SPECIAL_ATTACK_AVALANCHE, cooldown = 45 },
		{ name = self.SPECIAL_ATTACK_EGGS, cooldown = 35 },
		{ name = self.SPECIAL_ATTACK_HEAL, cooldown = 10 },
		{ name = self.SPECIAL_ATTACK_WAVE, cooldown = 30 },
	}

	self.fightConfig = 
	{
		{
			hpMax = 1,
			hpMin = 0.66,
			endPhaseLogicFile = "logic/missions/campaigns/dlc_2/caverns_boss_end_phase_1.logic",

			[self.SPECIAL_ATTACK_TOWER]      = { blueprint = "units/ground/anoryxian_boss_omega_tower", count = 3, duration = 6 },
			[self.SPECIAL_ATTACK_FIREWALL]   = { blueprint = "units/ground/anoryxian_boss_omega/firewall", count = 45, spread = 3 },
			[self.SPECIAL_ATTACK_PROJECTILE] = { count = 3, spread = 3 },
			
			[self.SPECIAL_ATTACK_HEAL]       = { heal_when_min_health = 0.35, heal_percentage = 500000, heal_speed_in_sec = 10000 },
			[self.SPECIAL_ATTACK_AVALANCHE]  = { blueprint = "weather/stalactite_anoryxian", duration = 4, radius = 1, spawnTime = 0.75 },
			[self.SPECIAL_ATTACK_EGGS]       = { blueprint = "units/ground/egg_anoryxian_boss", count = 3, distanceBetween = 1, randomOffset = 10 },
			[self.SPECIAL_ATTACK_WAVE] = 
			{ 
				count = 2,	

				["attacks"] = 
				{
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_3.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_crawlog.logic",
				}
			}
		},

		{
			hpMax = 0.66,
			hpMin = 0.33,
			endPhaseLogicFile = "logic/missions/campaigns/dlc_2/caverns_boss_end_phase_3.logic",

			[self.SPECIAL_ATTACK_TOWER]      = { blueprint = "units/ground/anoryxian_boss_omega_tower", count = 3, duration = 6 },
			[self.SPECIAL_ATTACK_FIREWALL]   = { blueprint = "units/ground/anoryxian_boss_omega/firewall", count = 45, spread = 3 },
			[self.SPECIAL_ATTACK_PROJECTILE] = { count = 3, spread = 3 },
			
			[self.SPECIAL_ATTACK_HEAL]       = { heal_when_min_health = 0.55, heal_percentage = 500000, heal_speed_in_sec = 10000 },
			[self.SPECIAL_ATTACK_AVALANCHE]  = { blueprint = "weather/stalactite_anoryxian", duration = 4, radius = 1, spawnTime = 0.75 },
			[self.SPECIAL_ATTACK_EGGS]       = { blueprint = "units/ground/egg_anoryxian_boss", count = 3, distanceBetween = 1, randomOffset = 10 },
			[self.SPECIAL_ATTACK_WAVE] = 
			{ 
				count = 2,	

				["attacks"] = 
				{
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_4.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_3.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_4.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_5.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_crawlog.logic",
				}
			}
		},

		{
			hpMax = 0.33,
			hpMin = 0,

			[self.SPECIAL_ATTACK_TOWER]      = { blueprint = "units/ground/anoryxian_boss_omega_tower", count = 3, duration = 6 },
			[self.SPECIAL_ATTACK_FIREWALL]   = { blueprint = "units/ground/anoryxian_boss_omega/firewall", count = 45, spread = 3 },
			[self.SPECIAL_ATTACK_PROJECTILE] = { count = 3, spread = 3 },
			
			[self.SPECIAL_ATTACK_HEAL]       = { heal_when_min_health = 0.55, heal_percentage = 500000, heal_speed_in_sec = 10000 },
			[self.SPECIAL_ATTACK_AVALANCHE]  = { blueprint = "weather/stalactite_anoryxian", duration = 4, radius = 1, spawnTime = 0.75 },
			[self.SPECIAL_ATTACK_EGGS]       = { blueprint = "units/ground/egg_anoryxian_boss", count = 4, distanceBetween = 1, randomOffset = 10 },
			[self.SPECIAL_ATTACK_WAVE] = 
			{ 
				count = 2,	

				["attacks"] = 
				{
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_4.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_3.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_4.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_5.logic",
					"logic/missions/campaigns/dlc_2/the_abys_boss_wave_crawlog.logic",
				}
			}
		},
	}
	self.overrideFSM = self:CreateStateMachine()
	self.overrideFSM:AddState( "override", { enter="OnEnterOverride", exit="OnExitOverride" } )
	self.overrideFSM:ChangeState( "override" )
end

function anoryxian_boss_omega:OnEnterOverride( state )
	state:SetDurationLimit( 1 )
end

function anoryxian_boss_omega:OnExitOverride( state )
	QueueEvent( "EmitStateMachineEventRequest", self.entity, "go_idle" )
end

return anoryxian_boss_omega
