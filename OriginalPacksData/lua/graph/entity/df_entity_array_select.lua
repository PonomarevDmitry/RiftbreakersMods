require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

class 'df_entity_array_select' ( LuaGraphNode )

function df_entity_array_select:__init()
    LuaGraphNode.__init(self, self)
end

local SELECT_OPERATORS = {
    ["first"] = function( entities, count )
        local remaining = DeepCopy(entities)
        local selected = {}

        for i=1,count do
            table.insert(selected, entities[i])
            table.remove(remaining, IndexOf(remaining, entities[i]) )
        end

        return selected,remaining
    end,
    ["last"] = function( entities, count )
        local remaining = DeepCopy(entities)
        local selected = {}

        for i=1,count do
		    local j =#entities - i + 1
            table.insert(selected, entities[j])
            table.remove(remaining, IndexOf(remaining, entities[i]) )
        end

        return selected,remaining 
    end,
    ["random"] = function(entities, count )
        local remaining = DeepCopy(entities)
        local selected = {}

        for i=1,count do
            local index = RandInt(1, #entities)
            while test[index] do
                index = RandInt(1, #entities)
            end

            test[index] = true

            table.insert(selected, entities[index])
            table.remove(remaining, IndexOf(remaining, entities[i]) )
        end

        return selected,remaining
    end
}

function df_entity_array_select:Activated()
    local select_type = self.data:GetString("select_type")
    local select_count = self.data:GetInt("select_count")

    local entities = GetEntitiesFromString( self.data:GetString("in_entities") )
	--LogService:Log("IN ENTITIES: " .. #entities .. " (" .. self.data:GetString("in_entities") .. ")")

    select_count = math.min(select_count, #entities)

    local handler = SELECT_OPERATORS[select_type]
    if Assert( handler ~= nil, "ERROR: no handler for select_type = '" .. tostring(select_type) .. "'") then
        local selected_entities,remaining_entities = handler(entities, select_count)

        local out_selected_entities = GetEntitiesAsString(selected_entities)
        self.data:SetString("out_entities", out_selected_entities)

        local out_remaining_entities = GetEntitiesAsString(remaining_entities)
		self.data:SetString("out_remaining_entities", out_remaining_entities)

        --LogService:Log("OUT ENTITIES 1: " .. #selected_entities .. " (" .. out_selected_entities .. ")")
        --LogService:Log("OUT ENTITIES 2: " .. #remaining_entities .. " (" .. out_remaining_entities .. ")")
        
        self:SetFinished()
    end
end

return df_entity_array_select