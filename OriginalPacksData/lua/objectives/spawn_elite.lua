class 'spawn_elite' ( LuaGraphNode )
require("lua/utils/find_utils.lua")
require("lua/utils/table_utils.lua")

function spawn_elite:__init()
	LuaGraphNode.__init(self, self)
end

function spawn_elite:init()
	local blueprints = self.data:GetStringKeys()
	if ( self.data:HasString("entity_name")) then
		self.name = self.data:GetString("entity_name")
		Remove(blueprints, "entity_name")
	else
		self.name = "spawn_elite"
	end
	
	if ( self.data:HasString("marker_name")) then
		self.marker_name = self.data:GetString("marker_name")
		Remove(blueprints, "marker_name")
	else
		self.marker_name = "spawn_elite_marker"
	end
	local random = RandInt(1,#blueprints)
	self.eliteBlueprint = self.data:GetString( blueprints[random])

	self.globalWaitEvent = self.parent:CreateGraphUniqueString( "KillEliteEnd" )
end

function spawn_elite:Activated()
	self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )	
	local objectiveSpawn = MissionService:SpawnMissionObjective(self.eliteBlueprint, false)
	if objectiveSpawn == INVALID_ID then
		LogService:Log("NO FREE OBJECTIVE SPAWN POINTS - ABORTING OBJECTIVE")
		
		QueueEvent( "LuaGlobalEvent", event_sink, self.parent:CreateGraphUniqueString( "SpawnFailed" ), {} )			
	else
		self.marker = EntityService:SpawnEntity( "effects/messages_and_markers/objective_marker_red", objectiveSpawn, "no_team" )	
		EntityService:SetName( self.marker, self.marker_name  )
		EntityService:SetName( objectiveSpawn, self.name  )	
		EntityService:SetGroup( objectiveSpawn, "objective" )	
		
		UnitService:DefendSpot( objectiveSpawn, 25, 100 )
		QueueEvent( "LuaGlobalEvent", event_sink, self.parent:CreateGraphUniqueString( "SpawnSuccessful" ), {} )
	end
end

function spawn_elite:OnLuaGlobalEvent( event )
	if self.globalWaitEvent == event:GetEvent() then
		EntityService:RemoveEntity( self.marker )	
		self:SetFinished()
	end
end

function spawn_elite:Deactivated()
	self:UnregisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
end

return spawn_elite