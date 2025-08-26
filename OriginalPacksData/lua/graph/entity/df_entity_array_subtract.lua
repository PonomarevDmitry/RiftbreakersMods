require("lua/utils/data_flow.lua")
require("lua/utils/table_utils.lua")

class 'df_entity_array_subtract' ( LuaGraphNode )

function df_entity_array_subtract:__init()
    LuaGraphNode.__init(self, self)
end

function df_entity_array_subtract:Activated()
    local in_entities_1 = self.data:GetString("in_entities_1")
    local in_entities_2 = self.data:GetStringOrDefault("in_entities_2", "")

    local entities_1 = GetEntitiesFromString( in_entities_1 )
    local entities_2 = GetEntitiesFromString( in_entities_2 )
    for entity in Iter(entities_2) do
        local index = IndexOf(entities_1, entity)
        if index then
            table.remove(entities_1, index)
        end
    end


    local out_entities = GetEntitiesAsString(entities_1)
    self.data:SetString("out_entities", out_entities)

    self:SetFinished()
end

return df_entity_array_subtract