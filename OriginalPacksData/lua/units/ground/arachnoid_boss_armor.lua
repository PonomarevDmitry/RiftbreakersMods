class 'arachnoid_boss_armor' ( LuaEntityObject )

function arachnoid_boss_armor:__init()
	LuaEntityObject.__init(self,self)
end

function arachnoid_boss_armor:init()
	self.parent = EntityService:GetParent( self.entity )
	EntityService:DisableCollisions( self.parent )
	self:RegisterHandler( self.entity, "DestroyRequest",  "OnDestroyRequest" )
end

function arachnoid_boss_armor:OnDestroyRequest( evt )
	EntityService:EnableCollisions( self.parent )
end

return arachnoid_boss_armor
