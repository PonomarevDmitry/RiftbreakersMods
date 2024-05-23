require("lua/utils/find_utils.lua")

class 'spawn_nest' ( LuaGraphNode )

function spawn_nest:__init()
	LuaGraphNode.__init(self, self)
end

function spawn_nest:init()
    local blueprints = self.data:GetStringKeys()
	if ( self.data:HasString("entity_name")) then
		self.name = self.data:GetString("entity_name")
		Remove(blueprints, "entity_name")
	else
		self.name = "spawn_nest"
	end
	if ( self.data:HasString("marker_name")) then
		self.marker_name = self.data:GetString("marker_name")
		Remove(blueprints, "marker_name")
	else
		self.marker_name = "spawn_nest_marker"
	end
	local random = RandInt(1,#blueprints)
	self.nestBP = self.data:GetString( blueprints[random])
end

function spawn_nest:Activated()

	local objectiveSpawn = MissionService:SpawnMissionObjective(self.nestBP, false)
	if objectiveSpawn == INVALID_ID then
		LogService:Log("NO FREE OBJECTIVE SPAWN POINTS - ABORTING OBJECTIVE")
		QueueEvent( "LuaGlobalEvent", event_sink, "SpawnFailed", {} )	
	else		
		self.marker = EntityService:SpawnEntity( "effects/messages_and_markers/objective_marker_red", objectiveSpawn, "no_team" )	
		EntityService:SetName( self.marker, self.marker_name )
		
		EntityService:SetName( objectiveSpawn, self.name )	
		EntityService:SetTeam( objectiveSpawn, "team" )
		EntityService:SetGroup( objectiveSpawn, "objective" )	
		
		QueueEvent( "LuaGlobalEvent", event_sink, "SpawnSuccessful", {} )
	end
	self:SetFinished()
	
end

return spawn_nest