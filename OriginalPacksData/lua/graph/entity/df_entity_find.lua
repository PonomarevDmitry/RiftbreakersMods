require("lua/utils/find_utils.lua")
require("lua/utils/data_flow.lua")

class 'df_entity_find' ( LuaGraphNode )

function df_entity_find:__init()
    LuaGraphNode.__init(self, self)
end

function df_entity_find:Activated()
    local find_type = self.data:GetString("find_type")
    local find_value = self.data:GetString("find_value")
    local find_radius = self.data:GetFloat("find_radius")

    local entities = {}
    if self.data:HasString("in_entities") then
        local in_entities = GetEntitiesFromString( self.data:GetString("in_entities") )
        entities = FindEntitiesInDinstance(find_type, find_value, in_entities, 0.0, find_radius )
    else
        entities = FindEntities( find_type, find_value )
    end

    local out_entities = GetEntitiesAsString(entities)
    self.data:SetString("out_entities", out_entities)

    self:SetFinished()
end

return df_entity_find