class 'exit_portal' ( LuaEntityObject )

function exit_portal:__init()
	LuaEntityObject.__init(self,self)
end

function exit_portal:init()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent", 	 "OnEnteredTriggerEvent" )
end

function exit_portal:OnEnteredTriggerEvent( evt )
    QueueEvent("OpenEnterPortalPopupRequest", evt:GetOtherEntity() )
end


return exit_portal
 