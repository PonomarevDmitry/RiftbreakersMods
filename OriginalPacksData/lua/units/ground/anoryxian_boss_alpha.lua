require("lua/utils/table_utils.lua")

local anoryxian_boss_base = require("lua/units/ground/anoryxian_boss_base.lua")
class 'anoryxian_alpha' ( anoryxian_boss_base )

function anoryxian_alpha:__init()
	anoryxian_boss_base.__init(self, self)
end

function anoryxian_alpha:_OnInit()
	self.config = 
	{
		spawnPointGroupName			= "Boss",
		unitSpawnerSpawnName		= "unit_spawner",
		interactiveSpawnName		= "boss_interactive",
		shieldSpawnName				= "boss_shield",
		towerSpawnName				= "boss_tower",		
		introLogicFile				= "logic/missions/campaigns/dlc_2/caverns_boss_alpha_intro.logic",
		fightLogicFile				= "logic/missions/campaigns/dlc_2/caverns_boss_fight.logic",
		outroLogicFile				= "logic/missions/campaigns/dlc_2/caverns_boss_alpha_outro.logic",
		extraHealPercentageOnPhase  = 10,
		cameraDistance              = 45
	}

	self.specialAttackCooldown = 
	{
		{ name = self.SPECIAL_ATTACK_AVALANCHE, cooldown = 45 },
		{ name = self.SPECIAL_ATTACK_EGGS, cooldown = 35 },
		{ name = self.SPECIAL_ATTACK_HEAL, cooldown = 25 },
		{ name = self.SPECIAL_ATTACK_WAVE, cooldown = 30 },
	}

	self.fightConfig = 
	{
		{
			hpMax = 1,
			hpMin = 0.66,
			endPhaseLogicFile = "logic/missions/campaigns/dlc_2/caverns_boss_end_phase_1.logic",

			[self.SPECIAL_ATTACK_TOWER]      = { blueprint = "units/ground/anoryxian_boss_tower", count = 3, duration = 6 },
			[self.SPECIAL_ATTACK_FIREWALL]   = { blueprint = "units/ground/anoryxian_boss/firewall", count = 45, spread = 3 },
			[self.SPECIAL_ATTACK_PROJECTILE] = { count = 3, spread = 3 },
			
			[self.SPECIAL_ATTACK_HEAL]       = { heal_when_min_health = 0.35, heal_percentage = 20, heal_speed_in_sec = 400 },
			[self.SPECIAL_ATTACK_AVALANCHE]  = { blueprint = "weather/stalactite_anoryxian", duration = 10, radius = 1, spawnTime = 0.75 },
			[self.SPECIAL_ATTACK_EGGS]       = { blueprint = "units/ground/egg_anoryxian", count = 50, distanceBetween = 1, randomOffset = 10 },
			[self.SPECIAL_ATTACK_WAVE] = 
			{ 
				count = 2,	

				["attacks"] = 
				{
					"logic/missions/campaigns/dlc_2/caverns_boss_wave_crawlog.logic",
				}
			}
		},

		{
			hpMax = 0.66,
			hpMin = 0.33,
			endPhaseLogicFile = "logic/missions/campaigns/dlc_2/caverns_boss_end_phase_3.logic",

			[self.SPECIAL_ATTACK_TOWER]      = { blueprint = "units/ground/anoryxian_boss_tower", count = 3, duration = 6 },
			[self.SPECIAL_ATTACK_FIREWALL]   = { blueprint = "units/ground/anoryxian_boss/firewall", count = 45, spread = 3 },
			[self.SPECIAL_ATTACK_PROJECTILE] = { count = 3, spread = 3 },
			
			[self.SPECIAL_ATTACK_HEAL]       = { heal_when_min_health = 0.55, heal_percentage = 20, heal_speed_in_sec = 600 },
			[self.SPECIAL_ATTACK_AVALANCHE]  = { blueprint = "weather/stalactite_anoryxian", duration = 10, radius = 1, spawnTime = 0.75 },
			[self.SPECIAL_ATTACK_EGGS]       = { blueprint = "units/ground/egg_anoryxian", count = 50, distanceBetween = 1, randomOffset = 10 },
			[self.SPECIAL_ATTACK_WAVE] = 
			{ 
				count = 2,	

				["attacks"] = 
				{
					"logic/missions/campaigns/dlc_2/caverns_boss_wave_2.logic",
					"logic/missions/campaigns/dlc_2/caverns_boss_wave_3.logic",
					"logic/missions/campaigns/dlc_2/caverns_boss_wave_4.logic",
					"logic/missions/campaigns/dlc_2/caverns_boss_wave_5.logic",
					"logic/missions/campaigns/dlc_2/caverns_boss_wave_crawlog.logic",
				}
			}
		},

		{
			hpMax = 0.33,
			hpMin = 0,

			[self.SPECIAL_ATTACK_TOWER]      = { blueprint = "units/ground/anoryxian_boss_tower", count = 3, duration = 6 },
			[self.SPECIAL_ATTACK_FIREWALL]   = { blueprint = "units/ground/anoryxian_boss/firewall", count = 45, spread = 3 },
			[self.SPECIAL_ATTACK_PROJECTILE] = { count = 3, spread = 3 },
			
			[self.SPECIAL_ATTACK_HEAL]       = { heal_when_min_health = 0.55, heal_percentage = 20, heal_speed_in_sec = 600 },
			[self.SPECIAL_ATTACK_AVALANCHE]  = { blueprint = "weather/stalactite_anoryxian", duration = 10, radius = 1, spawnTime = 0.75 },
			[self.SPECIAL_ATTACK_EGGS]       = { blueprint = "units/ground/egg_anoryxian", count = 50, distanceBetween = 1, randomOffset = 10 },
			[self.SPECIAL_ATTACK_WAVE] = 
			{ 
				count = 2,	

				["attacks"] = 
				{
					"logic/missions/campaigns/dlc_2/caverns_boss_wave_2.logic",
					"logic/missions/campaigns/dlc_2/caverns_boss_wave_3.logic",
					"logic/missions/campaigns/dlc_2/caverns_boss_wave_4.logic",
					"logic/missions/campaigns/dlc_2/caverns_boss_wave_5.logic",
				}
			}
		},
	}
	self.overrideFSM = self:CreateStateMachine()
	self.overrideFSM:AddState( "override", { enter="OnEnterOverride", exit="OnExitOverride" } )
	self.overrideFSM:ChangeState( "override" )
end

function anoryxian_alpha:OnEnterOverride( state )
	state:SetDurationLimit( 1 )
end

function anoryxian_alpha:OnExitOverride( state )
	QueueEvent( "EmitStateMachineEventRequest", self.entity, "go_idle" )
end

return anoryxian_alpha
