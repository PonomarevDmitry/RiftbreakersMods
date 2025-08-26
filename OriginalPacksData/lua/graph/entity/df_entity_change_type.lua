require("lua/utils/data_flow.lua")
require("lua/utils/table_utils.lua")

class 'df_entity_change_type' ( LuaGraphNode )

function df_entity_change_type:__init()
    LuaGraphNode.__init(self, self)
end

function df_entity_change_type:Activated()
	local type_mask = self.data:GetString("type_mask")

    local entities = GetEntitiesFromString( self.data:GetString("in_entities") )
    for entity in Iter(entities) do
        EntityService:ChangeType( entity, type_mask )
    end

    self:SetFinished();
end

return df_entity_change_type