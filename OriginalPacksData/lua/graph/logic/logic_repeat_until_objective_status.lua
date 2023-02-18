class 'logic_repeat_until_objective_status' ( LuaGraphNodeSelector )
require("lua/utils/enumerables.lua")

function logic_repeat_until_objective_status:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_repeat_until_objective_status:init()	
    self.objectiveName =  self.data:GetString( "unique_name_id" )
	if self.data:GetIntOrDefault("is_objective_local", 1) == 1 then
		self.objectiveName = self.parent:CreateGraphUniqueString( self.objectiveName )
	end
    self.status = StringToObjectiveStatus(self.data:GetString("status"))
    
    self.objectiveID = ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( self.objectiveName )
end

function logic_repeat_until_objective_status:Activated()
    
    local objectiveStatus = ObjectiveService:GetObjectiveStatus( self.objectiveID )
	if objectiveStatus == self.status then
		self:SetFinished("true")
	else
		self:SetFinished("false")
	end
end

return logic_repeat_until_objective_status