class 'interface_wait_on_build_menu' ( LuaGraphNode )

function interface_wait_on_build_menu:__init()
    LuaGraphNode.__init(self, self)
end

function interface_wait_on_build_menu:init()		
end

function interface_wait_on_build_menu:Activated()							
	self:RegisterHandler( event_sink , "EnterBuildMenuEvent", "OnEnterBuildMenuEvent")	
end

function interface_wait_on_build_menu:Deactivated()
	self:UnregisterHandler( event_sink, "EnterBuildMenuEvent", "OnEnterBuildMenuEvent" )
end

function interface_wait_on_build_menu:OnEnterBuildMenuEvent()
    self:SetFinished()
end

return interface_wait_on_build_menu