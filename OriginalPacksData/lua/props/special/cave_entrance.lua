class 'cave_entrance' ( LuaEntityObject )

function cave_entrance:__init()
	LuaEntityObject.__init(self,self)
end

function cave_entrance:init()	
	self:RegisterHandler( self.entity, "InteractWithEntityRequest",  "OnInteractWithEntityRequest" )
	self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
end

function cave_entrance:OnLuaGlobalEvent( event )
	if "CaveEntranceEnabled" == event:GetEvent() then
        local component = reflection_helper( EntityService:CreateComponent(self.entity,"InteractiveComponent") );
        component.slot = "ACTIVATOR"
        component.radius = 6 
        component.remove_entity = 0
        component.remove_component = 0
    end
end


function cave_entrance:OnInteractWithEntityRequest( evt )
	local params = { target = tostring( EntityService:GetName( self.entity ) ) }
	QueueEvent( "LuaGlobalEvent", event_sink, "CavernsEntranceActivated", params )	
end


return cave_entrance