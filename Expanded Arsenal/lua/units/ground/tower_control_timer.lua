require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

class 'tower_control_timer' ( LuaEntityObject )

function tower_control_timer:__init()
	LuaEntityObject.__init(self,self)
end

function tower_control_timer:init()

	local hacked_effect = self.data:GetStringOrDefault("hacked_effect", "effects/messages_and_markers/tower_hacked")
	
    self.tableEntsControl = {}
    local names = self.data:GetIntKeys()

    for name in Iter(names) do
        local ent  = self.data:GetInt( name )
        table.insert( self.tableEntsControl, ent )
		EntityService:SpawnAndAttachEntity( hacked_effect, ent )
    end
end

function tower_control_timer:OnRelease()

	for ent in Iter( self.tableEntsControl ) do
		if HealthService:IsAlive(ent) then
			EntityService:ChangeType(ent, "tower")
			EntityService:SetTeam(ent, "player")
		end
	end
end

return tower_control_timer