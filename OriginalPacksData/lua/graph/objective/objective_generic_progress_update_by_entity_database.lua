class 'objective_generic_progress_update_by_entity_database' ( LuaGraphNode )

function objective_generic_progress_update_by_entity_database:__init()
	LuaGraphNode.__init(self,self)
end

function objective_generic_progress_update_by_entity_database:init()
	self.objectiveName =  self.data:GetString( "unique_name_id" )
	if self.data:GetIntOrDefault("is_objective_local", 1) == 1 then
		self.objectiveName = self.parent:CreateGraphUniqueString( self.objectiveName )
	end

	self.data:SetString("unique_name_id", self.objectiveName )
	self.entityName = self.data:GetString( "entity_name" )
	self.fieldName = self.data:GetString( "field_name" )
	
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="OnUpdate" } )
		
end

function objective_generic_progress_update_by_entity_database:Activated()
	self.fsm:ChangeState( "update" )
end

function objective_generic_progress_update_by_entity_database:OnUpdate()
	local objectiveId = ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( self.objectiveName )
	
	if ( ObjectiveService:GetObjectiveStatus( objectiveId ) == OBJECTIVE_SUCCESS ) then
			self:SetFinished()	
	else
		local database = ObjectiveService:GetObjectiveDatabase( objectiveId )
	
		self.entity = FindService:FindEntityByName( self.entityName )
		
		local progressCurrent = 0
		if ( EntityService:IsAlive( self.entity ) == true ) then
			local db = EntityService:GetDatabase( self.entity )
			progressCurrent = db:GetFloatOrDefault(self.fieldName , 0 )
		end
		if ( database ~= nil ) then
			database:SetInt( "progress_current", progressCurrent )
		end
	end
end

return objective_generic_progress_update_by_entity_database