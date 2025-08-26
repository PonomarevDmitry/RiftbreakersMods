require("lua/utils/data_flow.lua")
require("lua/utils/string_utils.lua")

class 'event_graph_instance' ( LuaGraphNode )

function event_graph_instance:__init()
	LuaGraphNode.__init(self,self)
end

function event_graph_instance:init()
end

function event_graph_instance:Activated()
	local template_name = self.data:GetString("graph_template")
	local start_point = self.data:GetString("start_point")	

	MissionService:ActivateMissionFlow( "", template_name, start_point, self.data )
    self:SetFinished()
end

return event_graph_instance