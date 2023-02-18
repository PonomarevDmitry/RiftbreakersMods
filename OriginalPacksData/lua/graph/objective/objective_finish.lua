class 'objective_finish' ( LuaGraphNode )

function objective_finish:__init()
	LuaGraphNode.__init(self,self)
end

function objective_finish:init()
	self.objectiveName =  self.data:GetString( "unique_name_id" )
	if self.data:GetIntOrDefault("is_objective_local", 1) == 1 then
		self.objectiveName = self.parent:CreateGraphUniqueString( self.objectiveName )
	end

	self.data:SetString("unique_name_id", self.objectiveName )

	self.objectiveStatus = OBJECTIVE_SUCCESS;
	if self.data:GetString( "success" ) == "false" then
		self.objectiveStatus = OBJECTIVE_FAILED
	end
end

function objective_finish:Activated()
	local objectiveID = ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( self.objectiveName  )
	
	if Assert( objectiveID ~= INVALID_OBJECTIVE_ID, "ERROR: there is no objective with name: " .. self.objectiveName ) then
		ObjectiveService:FinishObjectiveByObjectiveId( objectiveID, self.objectiveStatus )
	end

	self:SetFinished()
end

return objective_finish