require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
local base_unit = require("lua/units/base_unit.lua")

class 'bomotimer' ( LuaEntityObject )

function bomotimer:__init()
	LuaEntityObject.__init(self,self)
end

function bomotimer:init()
    self.tableEntsBomo = {}
    local names = self.data:GetIntKeys()

    for name in Iter(names) do
        local ent  = self.data:GetInt( name )
        table.insert( self.tableEntsBomo, ent )
    end
    
end

function bomotimer:OnRelease()
	for ent in Iter( self.tableEntsBomo ) do
        if EntityService:IsAlive(ent) then
            BuildingService:EnableBuilding( ent )
            EffectService:DestroyEffectsByGroup(ent, "building_disable")
        end
	end
end

return bomotimer