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
end

function comet_silent:OnLoad()
	self:FillInitialParams()
end

function comet_silent:OnEnterSpawn( state )

	if ( self.findMode == "resource") then
		self.spaceEnt = ResourceService:FindEmptySpace( 100, 500 );
	elseif ( self.findMode == "objective") then
		self.spaceEnt = FindObjectiveSpot()
	else
	 	self.spaceEnt = ResourceService:FindEmptySpace( 100, 500 );
	end
    self.cometEnt = MeteorService:SpawnComet( PlayerService:GetPlayerControlledEnt( 0 ), self.spaceEnt, self.cometFlyingBp, 35, 20 )
end

function comet_silent:OnExecuteSpawn( state )
	if ( EntityService:IsAlive( self.cometEnt ) == false ) then
		self.spawner:ChangeState( "cleanup" )
	end
end

function comet_silent:OnExitSpawn( state )
	if ( self.cometDmgBp ~= "" ) then
		MeteorService:SpawnMeteorInRadius( self.spaceEnt, self.cometDmgBp, 0, 1, 140, 0, 0.0, "" ) --wersja do spadania ukosem 
	end

	if ( self.cometImpactPlaceBp ~= ""  ) then
		EntityService:SpawnEntity( self.cometImpactPlaceBp, self.spaceEnt, "no_team" )
	end

	if ( self.cometSpawnBp ~= "" ) then
		local spawnedEntity = EntityService:SpawnEntity( self.cometSpawnBp, self.spaceEnt, "" )
		if ( self.cometSpawnBpName ~= "") then
			EntityService:SetName(spawnedEntity, self.cometSpawnBpName)
		end
		if ( self.makeAggresive == 1 ) then
			EntityService:SetTeam( spawnedEntity, "wave_enemy")
			UnitService:SetInitialState( spawnedEntity, UNIT_AGGRESSIVE);
		end
	end
	if ( self.removeSpaceEnt == true ) then
		EntityService:RemoveEntity( self.spaceEnt )
	end
	EntityService:RemoveEntity( self.entity )
	QueueEvent("LuaGlobalEvent", event_sink, "CometHitGroundEvent", {})
end

return comet_silent