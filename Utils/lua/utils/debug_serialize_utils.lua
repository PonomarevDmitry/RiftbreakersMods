require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local DebugSerializeUtils = {}

function DebugSerializeUtils:IsTable( field )
    return type(field) == "table"
end

function DebugSerializeUtils:IsNumber( field )
    return type(field) == "number"
end

function DebugSerializeUtils:IsString( field )
    return type(field) == "string"
end

function DebugSerializeUtils:IsBoolean( field )
    return type(field) == "boolean"
end

function DebugSerializeUtils:toboolean( x )
   return x == "true"
end

function DebugSerializeUtils:SerializeObject( field )
    if type( field ) == "table" then
        return DebugSerializeUtils:SerializeTable( field )
    end

    return "[" .. type( field ) .. "] " .. tostring( field )
end

function DebugSerializeUtils:SerializeField( fieldName, field )
    return fieldName .. " : " .. DebugSerializeUtils:SerializeObject( field )
end

function DebugSerializeUtils:FindScope( opening, ending, str )
    local openingIdx = nil
    local endingIdx = nil

    local chars = StringTable( str )

    local depth = 0
    for idx = 1, #chars do
        if chars[ idx ] == opening then
            if openingIdx == nil then
                openingIdx = idx
            else
                depth = depth + 1
            end
        end

        if chars[ idx ] == ending then
            if depth == 0 then
                endingIdx = idx
            else
                depth = depth - 1
            end
        end
    end

    return { startPos = openingIdx, endPos = endingIdx }
end

function DebugSerializeUtils:SerializeTable( field )
    local data = "[" .. type( field ) .. "] {\n"
    for key, value in pairs( field ) do

        local keyDesc = DebugSerializeUtils:SerializeObject( key )

        local fieldDescription = DebugSerializeUtils:SerializeField( keyDesc, value )

        local singleItemStringSplit = Split( fieldDescription, "\n" )

        if ( #singleItemStringSplit > 0 ) then

            data = data .. "    " .. singleItemStringSplit[1] .. "\n"

            if ( #singleItemStringSplit > 1 ) then

                for j=2,#singleItemStringSplit do
                    if ( singleItemStringSplit[j] ~= "" and singleItemStringSplit[j] ~= nil ) then
                        data = data .. "        " .. singleItemStringSplit[j] .. "\n"
                    end
                end
            end
        end
    end
    return data .. "}"
end

function DebugSerializeUtils:SerializeFields( object, fields )
    local data = ""

    for fieldName in Iter( fields ) do
        local field = object[ fieldName ]
        data = data .. DebugSerializeUtils:SerializeField( fieldName, field )
    end

    return data
end

return DebugSerializeUtils
