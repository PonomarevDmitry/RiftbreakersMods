class 'objective_generic_increase' ( LuaGraphNode )

function objective_generic_increase:__init()
	LuaGraphNode.__init(self,self)
end

function objective_generic_increase:init()
	self.objectiveName =  self.data:GetString( "unique_name_id" )
	if self.data:GetIntOrDefault("is_objective_local", 1) == 1 then
		self.objectiveName = self.parent:CreateGraphUniqueString( self.objectiveName )
	end

	self.data:SetString("unique_name_id", self.objectiveName )

	self.increaseAmount = self.data:GetInt( "amount" )
end

function objective_generic_increase:Activated()
	local objectiveId = ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( self.objectiveName )
	if not Assert( objectiveId ~= INVALID_OBJECTIVE_ID, "ERROR: could NOT find objective with name: `" .. self.objectiveName .. "`" ) then
		return self:SetFinished()
	end

	local database = ObjectiveService:GetObjectiveDatabase( objectiveId )
	if not Assert( database ~= nil, "ERROR: could NOT find objective database with name: `" .. self.objectiveName .. "`" ) then
		return self:SetFinished()
	end

	local progressCurrent = database:GetInt( "progress_current" )
	progressCurrent = progressCurrent + self.increaseAmount

	database:SetInt( "progress_current", progressCurrent )

	self:SetFinished()
end

return objective_generic_increase