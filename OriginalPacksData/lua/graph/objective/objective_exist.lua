class 'objective_exist' ( LuaGraphNodeSelector )

function objective_exist:__init()
	LuaGraphNodeSelector.__init(self,self)
end

function objective_exist:init()
	self.objectiveName =  self.data:GetString( "unique_name_id" )
	if self.data:GetIntOrDefault("is_objective_local", 1) == 1 then
		self.objectiveName = self.parent:CreateGraphUniqueString( self.objectiveName )
	end

	self.data:SetString("unique_name_id", self.objectiveName )
end

function objective_exist:Activated()
	local objectiveID = ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( self.objectiveName )

	local exist = ObjectiveService:IsObjectiveExist( objectiveID )
	if ( exist == true ) then
		self:SetFinished( "true" )
	else
		self:SetFinished( "false" )
	end	
end

return objective_exist