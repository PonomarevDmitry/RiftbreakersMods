require("lua/utils/string_utils.lua")

class 'df_entity_array_select' ( LuaGraphNode )

function df_entity_array_select:__init()
    LuaGraphNode.__init(self, self)
end

local SELECT_OPERATORS = {
    ["first"] = function( entities, count )
        local result = {}
        for i=1,count do
            table.insert(result, entities[i])
        end

        return result
    end,
    ["last"] = function( entities, count )
        local result = {}
        for i=1,count do
            table.insert(result, entities[#entities - i + 1])
        end

        return result
    end,
    ["random"] = function(entities, count )
        local test = {}
        
        local result = {}
        for i=1,count do
            local index = RandInt(1, #entities)
            while test[index] do
                index = RandInt(1, #entities)
            end

            test[index] = true

            table.insert(result, entities[index])
        end

        return result
    end
}

function df_entity_array_select:Activated()
    local select_type = self.data:GetString("select_type")
    local select_count = self.data:GetInt("select_count")

    local entities = Split( self.data:GetString("in_entities"), ",", tonumber )
    select_count = math.min(select_count, #entities)

    local handler = SELECT_OPERATORS[select_type]
    if Assert( handler ~= nil, "ERROR: no handler for select_type = '" .. tostring(select_type) .. "'") then
        entities = handler(entities, select_count)

        local out_entities = GetEntitiesAsString(entities)
        self.data:SetString("out_entities", out_entities)
        
        self:SetFinished()
    end
end

return df_entity_array_select