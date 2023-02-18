class 'objective_remove' ( LuaGraphNode )

function objective_remove:__init()
	LuaGraphNode.__init(self,self)
end

function objective_remove:init()
	self.objectiveName =  self.data:GetString( "unique_name_id" )
	if self.data:GetIntOrDefault("is_objective_local", 1) == 1 then
		self.objectiveName = self.parent:CreateGraphUniqueString( self.objectiveName )
	end
end

function objective_remove:Activated()
	local objectiveID = ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( self.objectiveName )
	
	ObjectiveService:FinishObjectiveByObjectiveId( objectiveID, OBJECTIVE_SILENT_REMOVE )
	self:SetFinished()
end

return objective_remove