class 'building_activator_zone' ( LuaEntityObject )

function building_activator_zone:__init()
	LuaEntityObject.__init(self,self)
end

function building_activator_zone:init()	
	self:RegisterHandler( self.entity, "InteractWithEntityRequest",  "OnInteractWithEntityRequest" )
	self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
end

function building_activator_zone:OnLuaGlobalEvent( event )
	if "BuildingActivatorEnabled" == event:GetEvent() then
        local component = reflection_helper( EntityService:CreateComponent(self.entity,"InteractiveComponent") );
        component.slot = "ACTIVATOR"
        component.radius = 10 
        component.remove_entity = 1
        component.remove_component = 0
    end
end


function building_activator_zone:OnInteractWithEntityRequest( evt )
	local params = { target = tostring( EntityService:GetName( self.entity ) ) }
	QueueEvent( "LuaGlobalEvent", event_sink, "BuildingActivatorActivated", params )	
end


return building_activator_zone