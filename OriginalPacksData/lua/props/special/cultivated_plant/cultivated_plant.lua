class 'cultivated_plant' ( LuaEntityObject )

function cultivated_plant:__init()
	LuaEntityObject.__init(self,self)
end

function cultivated_plant:init()
	self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnLuaGlobalEvent" )
end

function cultivated_plant:OnLuaGlobalEvent(evt)
    if evt:GetEvent() == "CultivationEnded" then
        self:UnregisterHandler( self.entity, "LuaGlobalEvent", "OnLuaGlobalEvent" )

        local blueprint = self.data:GetString("cultivated_blueprint")
        EntityService:SpawnEntity( blueprint, self.entity, EntityService:GetTeam(self.entity) )
        EntityService:RequestDestroyPattern( self.entity, "default", true )
    end
end

return cultivated_plant