class 'logic_wait_on_dissolve' ( LuaGraphNode )

function logic_wait_on_dissolve:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_wait_on_dissolve:init()	
    self.entityName = self.data:GetString("entity_name")
    if self.data:GetIntOrDefault("name_is_global", 1) == 0 then
		self.entityName = self.parent:CreateGraphUniqueString(self.entityName)
	end
end

function logic_wait_on_dissolve:Activated()
	self:RegisterHandler( event_sink, "DissolveEntityRequest",  "OnDissolveEntityRequest" )
end

function logic_wait_on_dissolve:OnDissolveEntityRequest( evt )
    local name = EntityService:GetName(evt:GetEntity() )
    if ( name == self.entityName ) then        
		self:SetFinished()
    end
end

return logic_wait_on_dissolve