require("lua/utils/find_utils.lua")

class 'comet_silent' ( LuaEntityObject )

function comet_silent:__init()
	LuaEntityObject.__init(self, self)
end

function comet_silent:init()

	self:FillInitialParams()
			
    self.spawner = self:CreateStateMachine()
    self.spawner:AddState( "spawn", { enter="OnEnterSpawn", execute="OnExecuteSpawn", exit= "OnExitSpawn" } )
	self.spawner:AddState( "cleanup", { } )

	self.spawner:ChangeState( "spawn" )

	self.spaceEnt = INVALID_ID
	self.cometEnt = INVALID_ID
	self.removeSpaceEnt = true;
end

function comet_silent:FillInitialParams()
	self.cometFlyingBp = self.data:GetString( "comet_flying_blueprint" )
	self.cometSpawnBp = self.data:GetStringOrDefault( "comet_impact_spawn" , "")
	self.cometDmgBp			= self.data:GetStringOrDefault( "comet_dmg_blueprint", "" )
	self.cometImpactPlaceBp	= self.data:GetStringOrDefault( "comet_impact_place_blueprint", "" )
	self.cometSpawnBpName 		= self.data:GetStringOrDefault( "comet_impact_spawn_name", "" )
	self.findMode = self.data:GetStringOrDefault( "find_mode", "resource" )
	self.makeAggresive = self.data:GetIntOrDefault( "make_unit_aggressive" , 0)
	self.spawnHeight = 10
end

function comet_silent:OnLoad()
	self:FillInitialParams()
end

function comet_silent:SelectFlyoverCandidate()
	for entity in Iter( PlayerService:GetPlayersMechs() ) do
		return entity
	end

	return FindService:FindEntityByName("headquarters")
end

function comet_silent:UpdateSpawnHeightForDamage( entity )
	local position = EntityService:GetPosition( entity )
	self.spawnHeight = math.max( EnvironmentService:GetTerrainHeight( position ) + 1, position.y )
end

local function RandPositionInRadius( position, radius )
	position.x = position.x + RandFloat( -radius, radius )
	position.z = position.z + RandFloat( -radius, radius )
	return position
end

function comet_silent:OnEnterSpawn( state )
	if ( self.findMode == "resource") then
		self.spaceEnt = ResourceService:FindEmptySpace( 50, 500 );
	elseif ( self.findMode == "objective") then
		self.spaceEnt = MissionService:SpawnMissionObjective( "logic/position_marker", true )
	else
	 	self.spaceEnt = ResourceService:FindEmptySpace( 50, 500 );
	end
	
	if Assert(self.spaceEnt ~= INVALID_ID, "ERROR: failed to find spawn position for blueprint: '" .. self.cometFlyingBp .. "'") then

		local candidate = self:SelectFlyoverCandidate()
    	self.cometEnt = MeteorService:SpawnComet( candidate, self.spaceEnt, self.cometFlyingBp, 35, 20 )

		local extra_count = self.data:GetIntOrDefault("comet_extra_flying_entities", 0)

		local spread_radius = self.data:GetFloatOrDefault("comet_extra_flying_spread_radius", 10.0)
		for i=1,extra_count do
			local entity = MeteorService:SpawnComet( candidate, self.spaceEnt, self.cometFlyingBp, RandFloat(25,35), 20 )
			EntityService:DisableComponent( entity, "WorldEffectComponent" )
			local position = EntityService:GetPosition( entity )
			EntityService:SetPosition(entity, RandPositionInRadius(position, spread_radius))
			EntityService:CreateOrSetLifetime(entity, EntityService:GetLifeTime(entity) + 20, "normal" )
		end

		self:UpdateSpawnHeightForDamage( self.cometEnt )
	else
		EntityService:RemoveEntity( self.entity )
	end
end

function comet_silent:OnExecuteSpawn( state )
	if ( EntityService:IsAlive( self.cometEnt ) == false ) then
		self.spawner:ChangeState( "cleanup" )
	else
		self:UpdateSpawnHeightForDamage( self.cometEnt )
	end
end

function comet_silent:OnExitSpawn( state )
	if ( self.cometDmgBp ~= "" ) then
		MeteorService:SpawnMeteorInRadius( self.spaceEnt, self.cometDmgBp, 0, self.spawnHeight, self.spawnHeight * 0.5, 0, 0.0, "" ) --wersja do spadania ukosem 
	end

	if ( self.cometImpactPlaceBp ~= ""  ) then
		local entity = EntityService:SpawnEntity( self.cometImpactPlaceBp, self.spaceEnt, "no_team" )
		if self.findMode == "objective" then
			MissionService:PushEntityToMissionObjectSpawnerPools( entity, "objectives" )
		end
	end

	if ( self.cometSpawnBp ~= "" ) then
		local spawnedEntity = EntityService:SpawnEntity( self.cometSpawnBp, self.spaceEnt, "" )
		if ( self.cometSpawnBpName ~= "") then
			EntityService:SetName(spawnedEntity, self.cometSpawnBpName)
		end

		if ( self.makeAggresive == 1 ) then
			EntityService:SetTeam( spawnedEntity, "wave_enemy")
			UnitService:SetInitialState( spawnedEntity, UNIT_AGGRESSIVE);
		elseif self.findMode == "objective" then
			MissionService:PushEntityToMissionObjectSpawnerPools( spawnedEntity, "objectives" )
		end
	end
	if ( self.removeSpaceEnt == true ) then
		EntityService:RemoveEntity( self.spaceEnt )
	end
	EntityService:RemoveEntity( self.entity )
	QueueEvent("LuaGlobalEvent", event_sink, "CometHitGroundEvent", {})
end

return comet_silent