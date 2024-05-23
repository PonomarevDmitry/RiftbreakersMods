class 'spawn_elite_multiple' ( LuaGraphNode )
require("lua/utils/find_utils.lua")
require("lua/utils/table_utils.lua")

function spawn_elite_multiple:__init()
	LuaGraphNode.__init(self, self)
end

function spawn_elite_multiple:init()
	local blueprints = self.data:GetStringKeys()
	if ( self.data:HasString("entity_name")) then
		self.name = self.data:GetString("entity_name")
		Remove(blueprints, "entity_name")
	else
		self.name = "spawn_elite_multiple"
	end
    if ( self.data:HasString("marker_name")) then
		self.marker_name = self.data:GetString("marker_name")
		Remove(blueprints, "marker_name")
	else
		self.marker_name = "spawn_elite_multiple_marker"
	end
	local random = RandInt(1,#blueprints)
	self.eliteBlueprint = self.data:GetString( blueprints[random])
    self.spawnCount = self.data:GetIntOrDefault( "spawn_count", 1)
	self.randomizePosition = self.data:GetIntOrDefault( "randomize_position", 0)
    self.radius = self.data:GetFloatOrDefault("radius", 10)
	self.globalWaitEvent = self.parent:CreateGraphUniqueString( "KillEliteEnd" )
end

function GetRandomPositionInRadius( targetEntity, radius )
	local position = EntityService:GetPosition( targetEntity )
	if radius > 0.0 then
		position.x = position.x + RandFloat(-radius, radius)
		position.z = position.z + RandFloat(-radius, radius)
	end
	return position;
end

function spawn_elite_multiple:Activated()
	self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
	
	local objectiveSpawn = MissionService:SpawnMissionObjective( "logic/position_marker", false )
	if objectiveSpawn == INVALID_ID then
		LogService:Log("NO FREE OBJECTIVE SPAWN POINTS - ABORTING OBJECTIVE")
		QueueEvent( "LuaGlobalEvent", event_sink, self.parent:CreateGraphUniqueString( "SpawnFailed" ), {} )			
	else
        self.marker = EntityService:SpawnEntity( "effects/messages_and_markers/objective_marker_red", objectiveSpawn, "no_team" )	
        EntityService:SetName( self.marker, self.marker_name )

		for i=1,self.spawnCount do
            local eliteUnit
			if ( self.randomizePosition == 0 ) then
				eliteUnit = EntityService:SpawnEntity( self.eliteBlueprint, objectiveSpawn, "enemy" )
			else
				local position = GetRandomPositionInRadius( objectiveSpawn, self.radius )
				eliteUnit = EntityService:SpawnEntity( self.eliteBlueprint, position, EntityService:GetTeam("enemy") )
			end

			MissionService:PushEntityToMissionObjectSpawnerPools( eliteUnit, "objectives" )

			if EntityService:GetComponent(eliteUnit, "NavMeshMovementComponent") == nil then
				EntityService:RemovePropsInEntityBounds( eliteUnit );
			end

			UnitService:DefendSpot( eliteUnit, 25, 100 )
			EntityService:SetName( eliteUnit, self.name  )	
			EntityService:SetGroup( eliteUnit, "objective" )	

		end
		
        QueueEvent( "LuaGlobalEvent", event_sink, self.parent:CreateGraphUniqueString( "SpawnSuccessful" ), {} )
    end
end

function spawn_elite_multiple:OnLuaGlobalEvent( event )
	if	self.globalWaitEvent  == event:GetEvent() then
		EntityService:RemoveEntity( self.marker )	
		self:SetFinished()
	end
end

function spawn_elite_multiple:Deactivated()
	self:UnregisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
end

return spawn_elite_multiple