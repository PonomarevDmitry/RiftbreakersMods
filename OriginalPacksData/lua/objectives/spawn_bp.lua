require("lua/utils/find_utils.lua")

class 'spawn_objective_blueprint' ( LuaGraphNode )

function spawn_objective_blueprint:__init()
	LuaGraphNode.__init(self, self)
end

function spawn_objective_blueprint:init()
end

function spawn_objective_blueprint:Activated()
	Assert( self.data:HasString("blueprint") and self.data:HasString("target") and self.data:HasString("marker"), "No blueprint, target or marker for objective in database!" )
	self.blueprint = self.data:GetString( "blueprint");
	self.targetName = self.data:GetString( "target");
	self.markerName = self.data:GetStringOrDefault( "marker", "");
	self.endEvent = self.data:GetString( "end_event");
	self.startSuccesEvent = self.data:GetString( "start_success_event");
	self.startFailedEvent = self.data:GetString( "start_fail_event");
	self.team = self.data:GetStringOrDefault( "team", "enemy");
	self.markerBp = "effects/messages_and_markers/objective_marker_red"
	if ( self.data:GetStringOrDefault("unique_name_id", "") ~= "" ) then
		local objectiveName =  self.data:GetString( "unique_name_id" )
		if self.data:GetIntOrDefault("is_objective_local", 1) == 1 then
			objectiveName = self.parent:CreateGraphUniqueString( objectiveName )
		end
		local objectiveId = ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( objectiveName )
		self.markerBp = ObjectiveService:GetObjectiveMarkerBlueprint(objectiveId)
	end

	self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )

	local objectiveSpawn = MissionService:SpawnMissionObjective(self.blueprint, false)
	if objectiveSpawn == INVALID_ID then
		LogService:Log("NO FREE OBJECTIVE SPAWN POINTS - ABORTING OBJECTIVE")
		QueueEvent( "LuaGlobalEvent", event_sink, self.startFailedEvent, {} )	
	else		
		if ( self.markerName ~= "" ) then
			self.marker = EntityService:SpawnEntity( self.markerBp, objectiveSpawn, "no_team" )	
			EntityService:SetName( self.marker, self.markerName )
		end
		
		if self.team ~= "" then
			EntityService:SetTeam( objectiveSpawn, self.team )
		end

		EntityService:SetName( objectiveSpawn, self.targetName )	
		EntityService:SetGroup( objectiveSpawn, "objective" )
		
		QueueEvent( "LuaGlobalEvent", event_sink, self.startSuccesEvent, {} )
	end
	
end

function spawn_objective_blueprint:OnLuaGlobalEvent( event )
	if	self.endEvent == event:GetEvent() then			
		self:SetFinished()
	end
end

function spawn_objective_blueprint:Deactivated()
	self:UnregisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )	
end

return spawn_objective_blueprint