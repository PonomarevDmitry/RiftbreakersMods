class 'influence_pylon' ( LuaEntityObject )

function influence_pylon:__init()
	LuaEntityObject.__init(self,self)
end

function influence_pylon:init()	
	self:RegisterHandler( self.entity, "InteractWithEntityRequest",  "OnInteractWithEntityRequest" )
end


function influence_pylon:OnInteractWithEntityRequest( evt )
	QueueEvent("DestroyRequest", self.entity, "default", 100 )
    QueueEvent("DissolveEntityRequest", self.entity, 4.0, 0.0 )			
    EntityService:SetGraphicsUniform( self.entity, "cDissolveColor", 0.0, 10.0, 20.0, 1.0 )
end


return influence_pylon