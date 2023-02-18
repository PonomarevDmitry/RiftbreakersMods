class 'interface_wait_on_map' ( LuaGraphNode )

function interface_wait_on_map:__init()
    LuaGraphNode.__init(self, self)
end

function interface_wait_on_map:init()		
end

function interface_wait_on_map:Activated()							
	self:RegisterHandler( event_sink , "RiftMapVisibleChangedEvent", "OnRiftMapVisibleChangedEvent")	
end

function interface_wait_on_map:Deactivated()
	self:UnregisterHandler( event_sink, "RiftMapVisibleChangedEvent", "OnRiftMapVisibleChangedEvent" )
end

function interface_wait_on_map:OnRiftMapVisibleChangedEvent( evt )
	if (evt:GetVisible() == true) then
		self:SetFinished()
	end
end

return interface_wait_on_map