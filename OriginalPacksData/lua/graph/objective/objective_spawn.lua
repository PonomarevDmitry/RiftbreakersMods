class 'objective_spawn' ( LuaGraphNode )

function objective_spawn:__init()
    LuaGraphNode.__init(self, self)
end

function objective_spawn:init()
	local objectiveName =  self.data:GetString( "unique_name_id" )
	if self.data:GetIntOrDefault("is_objective_local", 1) == 1 then
		objectiveName = self.parent:CreateGraphUniqueString( objectiveName )
	end

	self.data:SetString("unique_name_id", objectiveName )

	local parentName =  self.data:GetString( "unique_parent_id_name" )
	if parentName ~= "" and self.data:GetIntOrDefault("is_parent_local", 1) == 1 then
		parentName = self.parent:CreateGraphUniqueString( parentName )
	end

	self.global = self.data:GetIntOrDefault( "is_global", 0 ) == 1 

	self.data:SetString("unique_parent_id_name", parentName )

	self.wait = self.data:GetString( "wait" ) == "true"
end

function objective_spawn:Activated()
	self.objectiveID = ObjectiveService:CreateObjective( self.data:GetString( "objective_blueprint" ), self.data, self.global, CampaignService:GetCurrentMissionId() )
	self.data:SetString("out_objective_id", tostring(self.objectiveID) )

	if self.wait then
		self:RegisterHandler( event_sink, "ObjectiveFinishedEvent", "OnObjectiveFinishedEvent" )
	else
	    self:SetFinished()
	end
end

function objective_spawn:Interrupted()
	if ( self.objectiveID and ObjectiveService:IsObjectiveExist( self.objectiveID ) == true ) then
		LogService:Log( "objective_spawn:Interrupted() : " .. tostring( self.objectiveID ) )
		ObjectiveService:FinishObjectiveByObjectiveId( self.objectiveID, OBJECTIVE_SILENT_REMOVE )
	end
end

function objective_spawn:OnObjectiveFinishedEvent( event )
	if ( event:GetObjectiveId() == self.objectiveID ) then
		self:UnregisterHandler( event_sink, "ObjectiveFinishedEvent", "OnObjectiveFinishedEvent" )
		self:SetFinished()
	end
end

return objective_spawn