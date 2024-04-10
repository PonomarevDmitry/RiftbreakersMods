require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

class 'bomotimer' ( LuaEntityObject )

function bomotimer:__init()
	LuaEntityObject.__init(self,self)
end

function bomotimer:init()
	local disabled_effect = self.data:GetStringOrDefault("disabled_effect", "effects/messages_and_markers/building_disabled")
	
	self.tableEntsBomo = {}
    local names = self.data:GetIntKeys()

    for name in Iter(names) do
        local ent  = self.data:GetInt( name )
        table.insert( self.tableEntsBomo, ent )
		EntityService:SpawnAndAttachEntity( disabled_effect, ent )
    end
    
end

function bomotimer:OnRelease()

	for ent in Iter( self.tableEntsBomo ) do
        if HealthService:IsAlive(ent) then
            BuildingService:EnableBuilding( ent )
            EffectService:DestroyEffectsByGroup(ent, "building_disable")
        end
	end
end

return bomotimer