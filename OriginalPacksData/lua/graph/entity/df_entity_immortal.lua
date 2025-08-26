require("lua/utils/data_flow.lua")
require("lua/utils/table_utils.lua")

class 'df_entity_immortal' ( LuaGraphNode )

function df_entity_immortal:__init()
    LuaGraphNode.__init(self, self)
end

function df_entity_immortal:Activated()
	local enable_immortality = self.data:GetString("state") == "true"

    local entities = GetEntitiesFromString( self.data:GetString("in_entities") )
    for entity in Iter(entities) do
        HealthService:SetImmortality( entity, enable_immortality )
    end

    self:SetFinished();
end

return df_entity_immortal