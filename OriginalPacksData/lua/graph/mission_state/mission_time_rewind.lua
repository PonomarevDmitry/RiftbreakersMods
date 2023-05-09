class 'mission_time_rewind' ( LuaGraphNode )

function mission_time_rewind:__init()
    LuaGraphNode.__init(self, self)
end

function mission_time_rewind:init()
end

function mission_time_rewind:Activated()
	local timeOfDay = self.data:GetStringOrDefault("time_of_day", "day")	
	
	EnvironmentService:SetForwardToTimeOfDay( timeOfDay )

    self:SetFinished()
end

return mission_time_rewind