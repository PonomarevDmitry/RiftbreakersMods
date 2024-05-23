require("lua/utils/string_utils.lua")

function GetEntitiesAsString( entities )
    local out_entities = ""
    for entity in Iter(entities) do
        if out_entities ~= "" then
            out_entities = out_entities .. ","
        end

        out_entities = out_entities .. tostring(entity)
    end

    return out_entities
end

function GetEntitiesFromString( entities_string )
    return Split( entities_string, ",", tonumber )
end