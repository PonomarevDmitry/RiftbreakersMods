require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'anoryxian_base' ( base_unit )

function anoryxian_base:__init()
	base_unit.__init(self, self)
end

function anoryxian_base:OnInit()

	-- const
	self.SPECIAL_ATTACK_FIREWALL	= "firewall"
	self.SPECIAL_ATTACK_AVALANCHE	= "avalanche"
	self.SPECIAL_ATTACK_EGGS		= "eggs"
	self.SPECIAL_ATTACK_WAVE		= "wave"
	self.SPECIAL_ATTACK_PROJECTILE  = "projectile"
	self.SPECIAL_ATTACK_HEAL		= "heal"
	self.SPECIAL_ATTACK_TOWER	    = "tower"

	-- EVENTS
	self.BossIntro				= "BossIntro"
	self.BossIntroDefenseDown	= "BossIntroDefenseDown"
	self.BossIntroShieldDown	= "BossIntroShieldDown"
	self.BossOutroShieldDown	= "BossOutroShieldDown"
	self.BossOutroShieldUp		= "BossOutroShieldUp"
	self.BossPlayOutroAnim		= "BossPlayOutroAnim"
	self.BossPlayOutroBadAnim	= "BossPlayOutroBadAnim"
	self.BossPlayOutroGoodAnim	= "BossPlayOutroGoodAnim"
	self.BossIntroFinished		= "intro_finished"
	self.BossPlayPhaseAnim		= "BossPlayPhaseAnim"
	self.BossPhaseAnimEnd		= "BossPhaseAnimEnd"
	self.BossBreakHeal			= "BossBreakHeal"
	self.BossHeal				= "BossHeal"
	self.BossHeartExposeStart	= "BossHeartExposeStart"
	self.BossHeartExposeEnd		= "BossHeartExposeEnd"

	self.healthSetup = 
	{

	}

	self.config = 
	{

	}

	self.specialAttackCooldown = 
	{

	}

	self.fightConfig = 
	{

	}
	----------------------------------------- DO NOT TOUCH -----------------------------------------

	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )
	self:RegisterHandler( self.entity, "HealStart",  "OnHealStart" )
	self:RegisterHandler( self.entity, "HealEnd",  "OnHealEnd" )
	self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
	self:RegisterHandler( event_sink, "MissionFlowDeactivatedEvent",   "OnMissionFlowDeactivatedEvent" )
	self:RegisterHandler( self.entity, "ShootArtilleryEvent",  "OnShootArtilleryEvent" )
	self:RegisterHandler( self.entity, "ShootLightningEvent",  "OnShootLightningEvent" )	

	self:UnregisterHandler( self.entity, "DestroyRequest",  "_OnDestroyRequest" )

	self.meteorFSM = self:CreateStateMachine()
	self.meteorFSM:AddState( "avalanche", { enter="OnEnterAvalanche", exit="OnExitAvalanche" } )

	self.eggFSM = self:CreateStateMachine()
	self.eggFSM:AddState( "eggs", { enter="OnEnterEggs", exit="OnExitEggs" } )

	self.firewallFSM = self:CreateStateMachine()
	self.firewallFSM:AddState( "firewall", { enter="OnEnterFirewall", exit="OnExitFirewall" } )

	self.towerFSM = self:CreateStateMachine()
	self.towerFSM:AddState( "tower_spawn", { enter="OnEnterTowerSpawn", exit="OnExitTowerSpawn" } )

	self.waveFSM = self:CreateStateMachine()
	self.waveFSM:AddState( "wave_spawn", { enter="OnEnterWaveSpawn", execute="OnExecuteWaveSpawn" } )

	self.healFSM = self:CreateStateMachine()
	self.healFSM:AddState( "heal", { enter="OnEnterHeal", execute="OnExecuteHeal", exit="OnExitHeal" } )
	self.healFSM:AddState( "heal_prepare", { enter="OnEnterHealPrepare" } )
	self.healFSM:AddState( "break_heal", { enter="OnEnterBreakHeal" } )

	self.fightFSM = self:CreateStateMachine()
	self.fightFSM:AddState( "fight", { enter="OnEnterFight", execute="OnExecuteFight" } )
	self.fightFSM:AddState( "change_phase", { enter="OnEnterChangePhase", exit="OnExitChangePhase" } )
	self.fightFSM:AddState( "dead", { enter="OnEnterDead"} )

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
	HealthService:SetImmortality( self.entity, true )

	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4

    local entities = FindService:FindEntitiesByBlueprint( "logic/spawn_enemy" );

	self.spawnPoints = {}

	self.bossIntroFile = "NONE"
	self.bossFightFile = "NONE"
	self.bossOutroFile = "NONE"
	self.bossPhaseFile = "NONE"

	self.attackList = 
	{
		self.SPECIAL_ATTACK_AVALANCHE,
		self.SPECIAL_ATTACK_FIREWALL,
		self.SPECIAL_ATTACK_EGGS,
		self.SPECIAL_ATTACK_WAVE,
		self.SPECIAL_ATTACK_PROJECTILE,
		self.SPECIAL_ATTACK_TOWER,
		self.SPECIAL_ATTACK_HEAL,
	}

	self.stateAttack = 
	{
		{ name = self.SPECIAL_ATTACK_FIREWALL, flag = "can_attack_fire" },
		{ name = self.SPECIAL_ATTACK_PROJECTILE, flag = "can_attack_projectile" },
		{ name = self.SPECIAL_ATTACK_TOWER, flag = "can_attack_tower" },
	}

	self.currentAttacks = {}

	self.currentPhase = 1
	self.maxPhase = #self.fightConfig

	self.spawnedAttacks = {} 
	self.avalancheEntity = INVALID_ID

	self.attackIsFinished = true
	self.isDead = false

	self.bossShield = INVALID_ID
	self.bossInteract = INVALID_ID
	self.bossInteractBeam = INVALID_ID

	self.wreck_type    = "wreck_big"
	self.wreckMinSpeed = 4
	self.isHealing = false
	self.healWasBreak = false
	UnitService:SetStateMachineParam( self.entity, "can_attack", 1 )

	self.towers = {}

	self.specialAttackCurrentCooldown = {}

	self:_OnInit()

    for entity in Iter( entities ) do	    

		local groupName = EntityService:GetGroup( entity );	

		if ( groupName == self.config.spawnPointGroupName ) then
			table.insert( self.spawnPoints, entity )		
		end

    end

	self:CreateShield( "is_shield_slow" )
end

function anoryxian_base:SetupDifficulty()

	self:HealthSetup()

	local creaturesDifficulty = CampaignService:GetCreaturesBaseDifficulty()

	local health = HealthService:GetMaxHealth( self.entity )
	local playersCount = #PlayerService:GetConnectedPlayers();

	LogService:Log( "anoryxian_base:SetupDifficulty() Current health : " .. health )
	LogService:Log( "anoryxian_base:SetupDifficulty() Creatures difficulty : " .. creaturesDifficulty )
	LogService:Log( "anoryxian_base:SetupDifficulty() Players count : " .. playersCount )

    local diff = math.max( 1, math.min( math.floor( creaturesDifficulty ), 10 ) )
    local players = math.max( 1, math.min( playersCount, 4 ) )

	local newHealth = self.healthSetup[diff][players]

	LogService:Log( "anoryxian_base:SetupDifficulty() Adjusted health : " .. newHealth )

	HealthService:SetMaxHealth( self.entity, newHealth )
	HealthService:SetHealth( self.entity, newHealth )
end

function anoryxian_base:OnLoad()

	LogService:Log( "anoryxian_base:OnLoad()" )
	
	if ( self.isDead == false ) then
		self:DisableBuildMode()
	end
end

function anoryxian_base:CreateSpecialAttackCooldown( attackName )

	LogService:Log( "anoryxian:CreateSpecialAttackCooldown() - " .. attackName )

	local cooldown = {}
	cooldown.name = attackName

	for i = 1, #self.specialAttackCooldown do
		if ( self.specialAttackCooldown[i].name == attackName ) then
			cooldown.timer = self.specialAttackCooldown[i].cooldown
		end
	end

	if ( cooldown.timer ~= nil ) then
		LogService:Log( "anoryxian:CreateSpecialAttackCooldown() - success" .. tostring( cooldown.timer ) )
		table.insert( self.specialAttackCurrentCooldown, cooldown )
	end
end

function anoryxian_base:PickSpecialAttack()
	if ( #self.currentAttacks == 0 ) then
		self:PrepareAttacks()
	end

	local index = RandInt( 1, #self.currentAttacks )
	local specialAttackName = self.currentAttacks[index]
	table.remove( self.currentAttacks, index )

	for i = 1, #self.specialAttackCurrentCooldown do
		if ( self.specialAttackCurrentCooldown[i].name == specialAttackName ) then
			LogService:Log( "anoryxian:PickSpecialAttack() - attack is on cooldown : " .. specialAttackName )
			specialAttackName = ""
			break
		end
	end

	--LogService:Log( "anoryxian:PickSpecialAttack() - " .. specialAttackName )

	if ( specialAttackName == self.SPECIAL_ATTACK_AVALANCHE ) then
		self.meteorFSM:ChangeState( "avalanche" )
	elseif ( specialAttackName == self.SPECIAL_ATTACK_EGGS ) then
		self.eggFSM:ChangeState( "eggs" )
	elseif ( specialAttackName == self.SPECIAL_ATTACK_WAVE ) then
		self.waveFSM:ChangeState( "wave_spawn" )
	elseif ( ( specialAttackName == self.SPECIAL_ATTACK_HEAL ) and ( self.isHealing == false ) ) then
		self.healFSM:ChangeState( "heal_prepare" )
	end
end

function anoryxian_base:PrepareAttacks()
	--LogService:Log( "anoryxian:PrepareAttacks()" )

	for i = 1, #self.stateAttack do
		UnitService:SetStateMachineParam( self.entity, self.stateAttack[i].flag, 0 )
	end

	for i = 1, #self.attackList do
		local attack = self.fightConfig[self.currentPhase][self.attackList[i]]

		local isCooldown = false

		for k = 1, #self.specialAttackCurrentCooldown do
			if ( self.specialAttackCurrentCooldown[k].name == self.attackList[i] ) then
				--LogService:Log( "anoryxian:PrepareAttacks() - attack is on cooldown : " .. self.attackList[i] )
				isCooldown = true
			end
		end

		if ( ( attack ~= nil ) and ( isCooldown == false ) ) then
			table.insert( self.currentAttacks, self.attackList[i] )

			--LogService:Log( self.attackList[i]  )

			for j = 1, #self.stateAttack do
				if ( self.attackList[i] == self.stateAttack[j].name ) then
					UnitService:SetStateMachineParam( self.entity, self.stateAttack[j].flag, 1 )
				end
			end

		end
	end 

end

function anoryxian_base:OnEnterDead( state )
	LogService:Log( "OnEnterDead" )

	local phase = self.fightConfig[self.currentPhase]
	MissionService:DeactivateMissionFlow( self.bossFightFile )
	self.bossOutroFile = MissionService:ActivateMissionFlow( "",  self.config.outroLogicFile , "default" )
	self.isDead = true

	local towersToDestroy = FindService:FindEntitiesByType( "tower" )
    for tower in Iter( towersToDestroy ) do
		if ( UnitService:IsOnArena( tower ) ) then
			EntityService:DissolveEntity( tower, 0.5 )
		end
    end

	self:ClearAfterDeath()
end

function anoryxian_base:OnEnterChangePhase( state )
	LogService:Log( "OnEnterChangePhase" )

	local phase = self.fightConfig[self.currentPhase]

	self.bossPhaseFile = MissionService:ActivateMissionFlow( "",  phase.endPhaseLogicFile , "default" )
	self.currentPhase = self.currentPhase + 1

	HealthService:SetImmortality( self.entity, true )
end

function anoryxian_base:OnExitChangePhase( state )
	LogService:Log( "OnExitChangePhase" )

end

function anoryxian_base:OnEnterWaveSpawn( state )

	LogService:Log( "anoryxian:OnEnterWaveSpawn" )

	local availableSpawnPoints = Copy( self.spawnPoints )
	local wave = self.fightConfig[self.currentPhase][self.SPECIAL_ATTACK_WAVE]
	local waveCount = wave.count

	if ( waveCount > #self.spawnPoints ) then
		waveCount = #self.spawnPoints
	end

	for i = 1, waveCount do
		
		local randomSpawnPointNumer = RandInt( 1, #availableSpawnPoints )
		local spawnPointName = EntityService:GetName( availableSpawnPoints[randomSpawnPointNumer] )
		table.remove( availableSpawnPoints, randomSpawnPointNumer )

		local randomWaveNumer = RandInt( 1, #wave["attacks"] )
		local waveName = wave["attacks"][randomWaveNumer]

		LogService:Log( "anoryxian:OnEnterWaveSpawn : " .. spawnPointName .. " " .. waveName )

		self.data:SetString( "spawn_point", spawnPointName )
		local attack = MissionService:ActivateMissionFlow( "", waveName, "default", self.data )

		table.insert( self.spawnedAttacks, attack )
	end

	self.attackIsFinished = false
end

function anoryxian_base:OnExecuteWaveSpawn( state, dt )
	if ( #self.spawnedAttacks == 0 ) then
		LogService:Log( "anoryxian:OnExecuteWaveSpawn: Exit" )
		self.attackIsFinished = true
		state:Exit()
		self:CreateSpecialAttackCooldown( self.SPECIAL_ATTACK_WAVE )
	end
end


function anoryxian_base:OnEnterBreakHeal( state )
	LogService:Log( "anoryxian:OnEnterBreakHeal" )

	self:ClearHeal()

	self:CreateSpecialAttackCooldown( self.SPECIAL_ATTACK_HEAL )

	self.healWasBreak = true

	QueueEvent( "EmitStateMachineEventRequest", self.entity, "heal_failed" )
end

function anoryxian_base:CreateShield( param )
	local onShieldMarker = FindService:FindEntityByGroup( self.config.shieldSpawnName );

	if ( onShieldMarker ~= INVALID_ID ) then

		self.bossShield = EntityService:SpawnEntity( "props/special/caverns/anoryxian_boss_shield", onShieldMarker, "" );	
		local db = EntityService:GetDatabase( self.bossShield )
		
		db:SetInt( param, 1 )
	end
end

function anoryxian_base:OnEnterHeal( state )
	LogService:Log( "anoryxian:OnEnterHeal" )

	local heal = self.fightConfig[self.currentPhase][self.SPECIAL_ATTACK_HEAL]
	local currentHealthPercentage = HealthService:GetHealthInPercentage( self.entity )

	if ( currentHealthPercentage <= heal.heal_when_min_health ) then
		self.healTo = HealthService:GetHealth( self.entity ) + ( HealthService:GetMaxHealth( self.entity ) * ( heal.heal_percentage / 100 ) );

		--LogService:Log( "anoryxian:OnEnterHeal " .. tostring( HealthService:GetHealth( self.entity ) ) .. " " .. tostring( HealthService:GetMaxHealth( self.entity ) ) .. " " .. tostring( self.healTo ) )

		self:CreateShield( "is_shield_fast" )

		local onInteractMarkers = FindService:FindEntitiesByGroup( self.config.interactiveSpawnName );

		if ( #onInteractMarkers > 0  ) then
			onInteractMarker = onInteractMarkers[RandInt( 1, #onInteractMarkers )]
			local toEntity = FindService:FindEntityByName( "logic/position_marker_boss_energy_output" );

			if ( ( onInteractMarker ~= INVALID_ID ) and ( toEntity ~= INVALID_ID ) ) then
				self.bossInteract = EntityService:SpawnEntity( "units/ground/anoryxian_boss/interactive", onInteractMarker, "" );

				self:CreateBeam( self.bossInteract, toEntity )
			end
		end

		EffectService:AttachEffects( self.entity, "healing" )
	end
end

function anoryxian_base:CreateBeam( fromEntity, toEntity )
    self.bossInteractBeam = EntityService:SpawnEntity( "units/ground/anoryxian_boss/interactive_beam", self.entity, "" )
    local component = reflection_helper( EntityService:GetComponent( self.bossInteractBeam, "LightningDataComponent" ) )

    local container = rawget( component.lighning_vec, "__ptr" );
    local instance = nil
    if ( container:GetItemCount() == 0 ) then
        instance = reflection_helper(container:CreateItem())
    else 
        instance = reflection_helper(container:GetItem(0))
    end

	local fromOrigin = EntityService:GetPosition( fromEntity )
	local toOrigin = EntityService:GetPosition( toEntity )

    instance.start_point.x = fromOrigin.x
    instance.start_point.y = fromOrigin.y
    instance.start_point.z = fromOrigin.z

    instance.end_point.x = toOrigin.x
    instance.end_point.y = 2.0
    instance.end_point.z = toOrigin.z
end

function anoryxian_base:OnExecuteHeal( state, dt )
	local heal = self.fightConfig[self.currentPhase][self.SPECIAL_ATTACK_HEAL]

	local health = HealthService:GetHealth( self.entity );
	local maxHealth = HealthService:GetMaxHealth( self.entity );	

	if ( health < self.healTo ) then
		--LogService:Log( "anoryxian:OnExecuteHeal " .. tostring( HealthService:GetHealth( self.entity ) ) .. " " .. tostring( HealthService:GetMaxHealth( self.entity ) ) .. " " .. tostring( self.healTo ) )

		health = health + ( heal.heal_speed_in_sec  * dt )
		HealthService:SetHealth( self.entity, math.min( health, maxHealth ) );
	else
		state:Exit()
		QueueEvent( "EmitStateMachineEventRequest", self.entity, "heal_finished" )
	end
end

function anoryxian_base:OnExitHeal( state )
	LogService:Log( "anoryxian:OnExitHeal" )
end


function anoryxian_base:OnEnterFight( state )
	LogService:Log( "anoryxian:OnEnterFight" )
	UnitService:SetUnitState( self.entity, UNIT_AGGRESSIVE );
	HealthService:SetImmortality( self.entity, false )
	self:PrepareAttacks()
end


function anoryxian_base:OnExecuteFight( state, dt )
	if ( self.attackIsFinished == true ) then
		self:PickSpecialAttack()
	end

	local phase = self.fightConfig[self.currentPhase]

	local currentHealth = HealthService:GetHealthInPercentage( self.entity )

	if ( currentHealth <= phase.hpMin ) then

		if ( self.currentPhase == #self.fightConfig ) then
			self.fightFSM:ChangeState( "dead" )
		else
			self.fightFSM:ChangeState( "change_phase" )
		end
	end

	for i = 1, #self.specialAttackCurrentCooldown do		
		self.specialAttackCurrentCooldown[i].timer = self.specialAttackCurrentCooldown[i].timer - dt

		--LogService:Log( "anoryxian:cooldown " .. self.specialAttackCurrentCooldown[i].name .. " " .. tostring( self.specialAttackCurrentCooldown[i].timer ) )

		if ( self.specialAttackCurrentCooldown[i].timer < 0 ) then
			table.remove( self.specialAttackCurrentCooldown, i )
			break
		end
	end
end

function anoryxian_base:OnEnterAvalanche( state )
	LogService:Log( "OnEnterAvalanche" )

	local avalanche = self.fightConfig[self.currentPhase][self.SPECIAL_ATTACK_AVALANCHE]
	state:SetDurationLimit( avalanche.duration + 5 )

	self.avalancheEntity = MeteorService:SpawnMeteorShower( self.entity, "weather/falling_stalactites_anoryxian", avalanche.duration, avalanche.spawnTime, avalanche.radius, 1, 2.0, "effects/messages_and_markers/meteor_marker", METEOR_FOLLOW_PLAYER )
	local db = EntityService:GetDatabase( self.avalancheEntity )

	db:SetString( "meteor_blueprint", avalanche.blueprint )

	self.attackIsFinished = false
end

function anoryxian_base:OnExitAvalanche( state )
	LogService:Log( "OnExitAvalanche" )

	self.attackIsFinished = true

	self:CreateSpecialAttackCooldown( self.SPECIAL_ATTACK_AVALANCHE )

	self.avalancheEntity = INVALID_ID
end

function anoryxian_base:OnEnterEggs( state )
	LogService:Log( "OnEnterEggs" )

	local spawnerMarkers = FindService:FindEntitiesByGroup( self.config.unitSpawnerSpawnName );

	if ( #spawnerMarkers > 0  ) then
		local spawnerMarker = spawnerMarkers[RandInt( 1, #spawnerMarkers )]

		local eggs = self.fightConfig[self.currentPhase][self.SPECIAL_ATTACK_EGGS]
		state:SetDurationLimit( 10 ) -- TODOD

		UnitService:SpawnUnitsAroundEntity( spawnerMarker, 50, eggs.randomOffset, eggs.distanceBetween, eggs.count,  eggs.blueprint, "enemy", true, 0.01 );		
	else
		state:Exit()
	end
	
	self.attackIsFinished = false

end

function anoryxian_base:OnExitEggs( state )
	LogService:Log( "OnExitEggs" )

	self:CreateSpecialAttackCooldown( self.SPECIAL_ATTACK_EGGS )

	self.attackIsFinished = true
end

function anoryxian_base:OnEnterTowerSpawn( state )
	LogService:Log( "OnEnterTowerSpawn" )

	local spawnPoints = FindService:FindEntitiesByGroup( self.config.towerSpawnName )

	local availableSpawnPoints = Copy( spawnPoints )
	local tower = self.fightConfig[self.currentPhase][self.SPECIAL_ATTACK_TOWER]
	local towerCount = tower.count

	if ( towerCount > #spawnPoints ) then
		towerCount = #spawnPoints
	end

	state:SetDurationLimit( tower.duration )

	for i = 1, towerCount do
		
		local randomSpawnPointNumer = RandInt( 1, #availableSpawnPoints )
		local currentPointName = availableSpawnPoints[randomSpawnPointNumer]
		table.remove( availableSpawnPoints, randomSpawnPointNumer )

		local tower = EntityService:SpawnEntity( tower.blueprint, currentPointName, "" )	
		table.insert( self.towers, tower )
	end

	--self.attackIsFinished = false


end

function anoryxian_base:ClearTowers()
	for i = 1, #self.towers do
		QueueEvent( "EmitStateMachineEventRequest", self.towers[i], "force_hide" )
	end

	QueueEvent( "EmitStateMachineEventRequest", self.entity, "force_hide" )

	self.towers = {}
end


function anoryxian_base:OnExitTowerSpawn( state )
	LogService:Log( "OnExitTowerSpawn" )

	self:ClearTowers()
end

function anoryxian_base:OnEnterFirewall( state )
	LogService:Log( "OnEnterFirewall" )
	state:SetDurationLimit( 3 )
	UnitService:SetStateMachineParam( self.entity, "can_fire", 1 )
	
	self.attackIsFinished = false

end

function anoryxian_base:OnExitFirewall( state )
	LogService:Log( "OnExitFirewall" )

	UnitService:SetStateMachineParam( self.entity, "can_fire", 0 )

	self.attackIsFinished = true
end

function anoryxian_base:DestroyShield()
	LogService:Log( "DestroyShield" )

	if ( self.bossShield ~= INVALID_ID ) then
		local db = EntityService:GetDatabase( self.bossShield )	
		db:SetInt( "is_shield_down", 1 )

		self.bossShield = INVALID_ID
	end
end

function anoryxian_base:ClearHeal()
	
	self:DestroyShield()

	if ( self.bossInteract ~= INVALID_ID ) then
		EntityService:DissolveEntity( self.bossInteract, 0.1 )
	end

	if ( self.bossInteractBeam ~= INVALID_ID ) then
		EntityService:DissolveEntity( self.bossInteractBeam, 0.1 )
	end

	self.bossInteract = INVALID_ID
	self.bossInteractBeam = INVALID_ID
end


function anoryxian_base:OnHealEnd( evt )
	LogService:Log( "OnHealEnd" )

	self:ClearHeal()

	self.attackIsFinished = true

	HealthService:SetImmortality( self.entity, false )
	UnitService:SetStateMachineParam( self.entity, "can_attack", 1 )
	UnitService:SetStateMachineParam( self.entity, "can_heal", 0 )
	
	self.isHealing = false

	if ( self.healWasBreak == false ) then
		self:CreateSpecialAttackCooldown( self.SPECIAL_ATTACK_HEAL )
	end

	EffectService:DestroyEffectsByGroup( self.entity, "healing" )

	self.healWasBreak = false
end

function anoryxian_base:OnEnterHealPrepare( state )
	LogService:Log( "OnEnterHealPrepare" )

	local heal = self.fightConfig[self.currentPhase][self.SPECIAL_ATTACK_HEAL]
	local currentHealthPercentage = HealthService:GetHealthInPercentage( self.entity )

	LogService:Log( "anoryxian:OnEnterHeal " .. tostring( currentHealthPercentage ) .. " " .. tostring( heal.heal_when_min_health) )

	if ( currentHealthPercentage <= heal.heal_when_min_health ) then

		UnitService:SetStateMachineParam( self.entity, "can_attack", 0 )
		UnitService:SetStateMachineParam( self.entity, "can_heal", 1 )
		HealthService:SetImmortality( self.entity, true )
		self.attackIsFinished = false
		self.isHealing = true
	else
		QueueEvent( "EmitStateMachineEventRequest", self.entity, "heal_finished" )
		state:Exit()
	end
end

function anoryxian_base:OnHealStart( evt )
	LogService:Log( "OnHealStart" )

	self.healFSM:ChangeState( "heal" )
end

function anoryxian_base:OnShootEvent( evt )

	EffectService:AttachEffects( self.entity, "attack_range_1" )
	EffectService:AttachEffects( self.entity, "attack_range_2" )

	local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), "range_attack_origin" )
	local myOrigin = EntityService:GetPosition( self.entity )
	local rightVector = EntityService:GetRightVector( VectorSub( targetOrigin, myOrigin ) )

	local projectile = self.fightConfig[self.currentPhase][self.SPECIAL_ATTACK_PROJECTILE]

	local count = math.floor( projectile.count / 2 )
	local mod = projectile.count % 2

	if ( count == projectile.count ) then
		WeaponService:ShootProjectileOnTargetOrigin( self.entity, self.entity, targetOrigin.x + ( rightVector.x * i * projectile.spread ), targetOrigin.y + 0.5, targetOrigin.z + ( rightVector.z * i * projectile.spread  ), "att_gun_left" )
		WeaponService:ShootProjectileOnTargetOrigin( self.entity, self.entity, targetOrigin.x + ( rightVector.x * i * projectile.spread ), targetOrigin.y + 0.5, targetOrigin.z + ( rightVector.z * i * projectile.spread  ), "att_gun_right" )
	elseif ( mod == 0 ) then
		for i = -count, count do 		
			if ( i ~= 0  ) then
				WeaponService:ShootProjectileOnTargetOrigin( self.entity, self.entity, targetOrigin.x + ( rightVector.x * i * projectile.spread ), targetOrigin.y + 0.5, targetOrigin.z + ( rightVector.z * i * projectile.spread  ), "att_gun_left" )
				WeaponService:ShootProjectileOnTargetOrigin( self.entity, self.entity, targetOrigin.x + ( rightVector.x * i * projectile.spread ), targetOrigin.y + 0.5, targetOrigin.z + ( rightVector.z * i * projectile.spread  ), "att_gun_right" )
			end
		end	
	else
		for i = -count, count do 
			WeaponService:ShootProjectileOnTargetOrigin( self.entity, self.entity, targetOrigin.x + ( rightVector.x * i * projectile.spread ), targetOrigin.y + 0.5, targetOrigin.z + ( rightVector.z * i * projectile.spread  ), "att_gun_left" )
			WeaponService:ShootProjectileOnTargetOrigin( self.entity, self.entity, targetOrigin.x + ( rightVector.x * i * projectile.spread ), targetOrigin.y + 0.5, targetOrigin.z + ( rightVector.z * i * projectile.spread  ), "att_gun_right" )
		end
	end
end

function anoryxian_base:OnShootLightningEvent( evt )
	LogService:Log( "OnShootLightningEvent" )
	self.towerFSM:ChangeState( "tower_spawn" )
end

-- THIS IS NOT GOOD....
function anoryxian_base:OnShootArtilleryEvent( evt )
	local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), evt:GetTargetTag() )

	local fire = self.fightConfig[self.currentPhase][self.SPECIAL_ATTACK_FIREWALL]

	local myOrigin = EntityService:GetPosition( self.entity )
	local rightVector = EntityService:GetRightVector( VectorSub( targetOrigin, myOrigin ) )

	local count = math.floor( fire.count / 2 )
	local mod = fire.count % 2


	if ( count == fire.count ) then
		local fireEntity = WeaponService:ShootEntityOnTargetOrigin( self.entity, self.entity, targetOrigin.x + ( rightVector.x * i * fire.spread ), targetOrigin.y + 2.0, targetOrigin.z + ( rightVector.z * i * fire.spread ), 10, "att_stomach", fire.blueprint )
		local component = reflection_helper( EntityService:CreateComponent( fireEntity,"BurningComponent" ) );

		if ( fireEntity ~= INVALID_ID ) then
			local db = EntityService:GetDatabase( fireEntity )
			db:SetString( "owner", tostring( self.entity ) )
		end
	elseif ( mod == 0 ) then
		for i = -count, count do 		
			if ( i ~= 0  ) then
				local fireEntity = WeaponService:ShootEntityOnTargetOrigin( self.entity, self.entity, targetOrigin.x + ( rightVector.x * i * fire.spread ), targetOrigin.y + 2.0, targetOrigin.z + ( rightVector.z * i * fire.spread ), 10, "att_stomach", fire.blueprint )
				local component = reflection_helper( EntityService:CreateComponent( fireEntity,"BurningComponent" ) );

				if ( fireEntity ~= INVALID_ID ) then
					local db = EntityService:GetDatabase( fireEntity )
					db:SetString( "owner", tostring( self.entity ) )
				end
			end
		end	
	else
		for i = -count, count do 
			local fireEntity = WeaponService:ShootEntityOnTargetOrigin( self.entity, self.entity, targetOrigin.x + ( rightVector.x * i * fire.spread ), targetOrigin.y + 2.0, targetOrigin.z + ( rightVector.z * i * fire.spread ), 10, "att_stomach", fire.blueprint )
			local component = reflection_helper( EntityService:CreateComponent( fireEntity,"BurningComponent" ) );

			if ( fireEntity ~= INVALID_ID ) then
				local db = EntityService:GetDatabase( fireEntity )
				db:SetString( "owner", tostring( self.entity ) )
			end
		end
	end
end

function anoryxian_base:ClearAfterDeath()

	for i = 1, #self.spawnedAttacks, 1 do 	
		MissionService:DeactivateMissionFlow( self.spawnedAttacks[i] )	
	end

	if ( self.avalancheEntity ~= INVALID_ID ) then
		EntityService:RemoveEntity( self.avalancheEntity )
		self.avalancheEntity = INVALID_ID
	end


	for i = 1, #self.towers do
		EntityService:DissolveEntity( self.towers[i], 0.3 )
	end
	
	self.towers = {}
	--self:ClearTowers()

	EffectService:DestroyEffectsByGroup( self.entity, "charge" )

end

function anoryxian_base:DisableBuildMode()

	local players = PlayerService:GetAllPlayers()

	for i = 1, #players, 1 do
		PlayerService:DisableBuildMode( players[i] )
	end
end

function anoryxian_base:EnableBuildMode()

	local players = PlayerService:GetAllPlayers()

	for i = 1, #players, 1 do
		PlayerService:EnableBuildMode( players[i] )
	end
end

function anoryxian_base:OnLuaGlobalEvent( evt )
	local eventName = evt:GetEvent()
	local params = evt:GetDatabase()

	if ( eventName == self.BossIntro ) then
		local cameraId = CameraService:GetActiveCamera()
		CameraService:SetTargetDistance( cameraId, self.config.cameraDistance )
		self.bossIntroFile = MissionService:ActivateMissionFlow( "",  self.config.introLogicFile , "default" )
		self:DisableBuildMode()
		self:SetupDifficulty()
		CampaignService:OperateDOMPlanetaryJump( false )
		GuiService:EnableMinimapInterference()
	elseif 	( eventName == self.BossIntroDefenseDown ) then
		QueueEvent( "EmitStateMachineEventRequest", self.entity, "defense_down" )
	elseif 	( eventName == self.BossHeartExposeStart ) then
		QueueEvent( "EmitStateMachineEventRequest", self.entity, "heart_expose_start" )
	elseif 	( eventName == self.BossIntroShieldDown ) then
		self:DestroyShield()
	elseif 	( eventName == self.BossOutroShieldDown ) then
		self:DestroyShield()
	elseif 	( eventName == self.BossOutroShieldUp ) then
		self:CreateShield( "is_shield_slow" )
	elseif 	( eventName == self.BossPlayOutroAnim ) then
		QueueEvent( "EmitStateMachineEventRequest", self.entity, "play_outro" )
	elseif 	( eventName == self.BossPlayOutroBadAnim ) then
		QueueEvent( "EmitStateMachineEventRequest", self.entity, "play_outro_bad" )
	elseif 	( eventName == self.BossPlayOutroGoodAnim ) then
		QueueEvent( "EmitStateMachineEventRequest", self.entity, "play_outro_good" )
	elseif 	( eventName == self.BossPlayPhaseAnim ) then
		UnitService:SetUnitState( self.entity, UNIT_PHASE );
	elseif 	( eventName == self.BossHeal ) then
		LogService:Log( "self.BossHeal" )
		self.healFSM:ChangeState( "heal_prepare" )
	elseif 	( eventName == self.BossBreakHeal ) then
		self.healFSM:ChangeState( "break_heal" )
	end
end

function anoryxian_base:OnMissionFlowDeactivatedEvent( event )

	local logicFile = event:GetName()

	if ( logicFile == self.bossIntroFile ) then
		QueueEvent( "EmitStateMachineEventRequest", self.entity, self.BossIntroFinished )
		self.fightFSM:ChangeState( "fight" )
		self.bossFightFile = MissionService:ActivateMissionFlow( "",  self.config.fightLogicFile , "default" )
	elseif ( logicFile == self.bossOutroFile ) then
		self:EnableBuildMode()
		CampaignService:OperateDOMPlanetaryJump( true )
		GuiService:DisableMinimapInterference()
	end



	if ( logicFile == self.bossPhaseFile ) then

		--if ( self.isDead == true ) then
		--	LogService:Log( "anoryxian:OnMissionFlowDeactivatedEvent - Dead" )
		--else
			LogService:Log( "OnMissionFlowDeactivatedEvent" )
			self.fightFSM:ChangeState( "fight" )
		--end
	end

	for i = 1, #self.spawnedAttacks, 1 do 
		if self.spawnedAttacks[i] == logicFile then
			table.remove( self.spawnedAttacks, i )		
		end
	end

end

function anoryxian_base:OnAnimationMarkerReached( evt )
	local markerName = evt:GetMarkerName() 

	--LogService:Log( "anoryxian:OnAnimationMarkerReached : " ..  markerName)



	if ( markerName == "phase_finish" ) then
		QueueEvent( "LuaGlobalEvent", event_sink, self.BossPhaseAnimEnd, {} )
	end

	if ( markerName == "charge"  ) then
		LogService:Log( "anoryxian:AttachEffects : " ..  markerName)
		EffectService:AttachEffects( self.entity, "charge" )
		return false;
	end

	if ( markerName == "charge_attack"  ) then
		EffectService:DestroyEffectsByGroup( self.entity, "charge" )
		return false;
	end

	return true
end


return anoryxian_base
