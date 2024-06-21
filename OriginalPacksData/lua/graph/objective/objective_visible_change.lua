class 'objective_visible_change' ( LuaGraphNode )
require("lua/utils/enumerables.lua")

function objective_visible_change:__init()
	LuaGraphNode.__init(self,self)
end

function objective_visible_change:init()
	self.objectiveName =  self.data:GetString( "unique_name_id" )
	if self.data:GetIntOrDefault("is_objective_local", 1) == 1 then
		self.objectiveName = self.parent:CreateGraphUniqueString( self.objectiveName )
	end

	self.data:SetString("unique_name_id", self.objectiveName )
end

function objective_visible_change:Activated()
	local objectiveID = ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( self.objectiveName  )
    local visible = self.data:GetInt("visible") == 1

	if objectiveID ~= INVALID_OBJECTIVE_ID then
        if ( visible ) then
            QueueEvent("ShowObjectiveRequest", INVALID_ID, objectiveID)
        else
            QueueEvent("HideObjectiveRequest", INVALID_ID, objectiveID)
        end
	end

	self:SetFinished()
end

return objective_visible_change