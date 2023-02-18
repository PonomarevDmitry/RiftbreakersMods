class 'objective_change_status' ( LuaGraphNode )
require("lua/utils/enumerables.lua")

function objective_change_status:__init()
	LuaGraphNode.__init(self,self)
end

function objective_change_status:init()
	self.objectiveName =  self.data:GetString( "unique_name_id" )
	if self.data:GetIntOrDefault("is_objective_local", 1) == 1 then
		self.objectiveName = self.parent:CreateGraphUniqueString( self.objectiveName )
	end

	self.data:SetString("unique_name_id", self.objectiveName )
end

function objective_change_status:Activated()
	local objectiveID = ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( self.objectiveName  )
    local status = self.data:GetString("status")
    self.objectiveStatus = StringToObjectiveStatus(status)    

	if objectiveID ~= INVALID_OBJECTIVE_ID then
		ObjectiveService:SetObjectiveStatusByObjectiveId( objectiveID, self.objectiveStatus )
	end

	self:SetFinished()
end

return objective_change_status