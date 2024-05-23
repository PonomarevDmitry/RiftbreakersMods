require("lua/utils/data_flow.lua")

class 'df_entity_array_compare' ( LuaGraphNodeSelector )

function df_entity_array_compare:__init()
    LuaGraphNodeSelector.__init(self, self)
end

local COMPARE_OPERATORS = {
    ["equal"] = function( lhs, rhs )
        return lhs == rhs
    end,
    ["not_equal"] = function( lhs, rhs )
        return lhs ~= rhs
    end,
    ["greater"] = function( lhs, rhs )
        return lhs > rhs
    end,
    ["greater_or_equal"] = function( lhs, rhs )
        return lhs >= rhs
    end,
    ["less"] = function( lhs, rhs )
        return lhs < rhs
    end,
    ["less_or_equal"] = function( lhs, rhs )
        return lhs <= rhs
    end
}

function df_entity_array_compare:Activated()
    local compare_type = self.data:GetString("compare_type")
    local compare_value = self.data:GetInt("compare_value")

    local entities = GetEntitiesFromString( self.data:GetString("in_entities") )

    local handler = COMPARE_OPERATORS[compare_type]
    if Assert( handler ~= nil, "ERROR: no handler for compare_type = '" .. tostring(compare_type) .. "'") then
        if handler( #entities, compare_value ) then
            self:SetFinished("true")
        else
            self:SetFinished("false")
        end
    end
end

return df_entity_array_compare