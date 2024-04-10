require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

class 'unit_control_timer' ( LuaEntityObject )

function unit_control_timer:__init()
	LuaEntityObject.__init(self,self)
end

function unit_control_timer:init()

	local controlled_effect = self.data:GetStringOrDefault("controlled_effect", "effects/messages_and_markers/unit_controlled")
	
	self.tableEntsControl = {}
    local names = self.data:GetIntKeys()

    for name in Iter(names) do
        local ent  = self.data:GetInt( name )
        table.insert( self.tableEntsControl, ent )
		EntityService:SpawnAndAttachEntity( controlled_effect, ent )
    end
    
end

function unit_control_timer:OnRelease()
	for ent in Iter( self.tableEntsControl ) do
		if HealthService:IsAlive(ent) then
			EntityService:SetTeam(ent, "wave_enemy")
		end
	end
end

return unit_control_timer