require("lua/utils/table_utils.lua")

class 'tornado_collision' ( LuaEntityObject )

function tornado_collision:__init()
	LuaEntityObject.__init(self, self)
end

function tornado_collision:init()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent",  "OnEnteredTriggerEvent" )
end

function tornado_collision:OnEnteredTriggerEvent( evt )
	EntityService:RemoveEntity( self.entity )
end


return tornado_collision
