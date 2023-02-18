class 'acid_undergound_mushroom' ( LuaEntityObject )

function acid_undergound_mushroom:__init()
	LuaEntityObject.__init(self,self)
end

function acid_undergound_mushroom:init()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent", 	 "OnEnteredTriggerEvent" )
end

function acid_undergound_mushroom:OnEnteredTriggerEvent( evt )
    QueueEvent("OpenEnterPortalPopupRequest", self.entity)
end


return acid_undergound_mushroom
 