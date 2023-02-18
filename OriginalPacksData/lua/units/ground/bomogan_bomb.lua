require("lua/utils/table_utils.lua")
require("lua/units/units_utils.lua")

class 'bomogan_bomb' ( LuaEntityObject )

function bomogan_bomb:__init()
	LuaEntityObject.__init(self, self)
end

function bomogan_bomb:init()
	self:RegisterHandler( self.entity, "AmmoRemoveRequest",  "OnAmmoRemoveRequest" )
end

function bomogan_bomb:OnAmmoRemoveRequest()
	EntityService:RequestDestroyPattern( self.entity, "wreck" )	
end


function bomogan_bomb:OnRelease()


end

return bomogan_bomb
