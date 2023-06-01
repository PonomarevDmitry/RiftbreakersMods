require ( "lua/utils/enumerables.lua" )
class 'mission_save_toggle' ( LuaGraphNode )

function mission_save_toggle:__init()
	LuaGraphNode.__init(self,self)
end

function mission_save_toggle:init()

end

function mission_save_toggle:Activated()   
	local state = self.data:GetStringOrDefault("state", "Enable" )	
	QueueEvent("BlockSaveRequest", event_sink, state == "true" )
	self:SetFinished();
end


return mission_save_toggle