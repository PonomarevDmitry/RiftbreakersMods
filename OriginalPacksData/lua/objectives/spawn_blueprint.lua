class 'spawn_blueprint' ( LuaGraphNode )

function spawn_blueprint:__init()
	LuaGraphNode.__init(self, self)
end

function spawn_blueprint:init()
    local blueprints = self.data:GetStringKeys()
	if ( self.data:HasString("entity_name")) then
		self.name = self.data:GetString("entity_name")
		Remove(blueprints, "entity_name")
	else
		self.name = "spawn_blueprint"
	end
	local random = RandInt(1,#blueprints)
	self.nestBP = self.data:GetString( blueprints[random])
end

function spawn_blueprint:Activated()
	local objectiveSpawn = MissionService:SpawnMissionObjective(self.nestBP, false)
	if objectiveSpawn == INVALID_ID then
		LogService:Log("NO FREE OBJECTIVE SPAWN POINTS - ABORTING OBJECTIVE")
		QueueEvent( "LuaGlobalEvent", event_sink, "SpawnFailed", {} )	
	else		
		EntityService:SetName( objectiveSpawn, self.name )	
		EntityService:SetGroup( objectiveSpawn, "objective" )

		QueueEvent( "LuaGlobalEvent", event_sink, "SpawnSuccessful", {} )
	end
	
end

return spawn_blueprint