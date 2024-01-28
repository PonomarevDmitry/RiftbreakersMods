require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local TemplatesSerializeUtils = {}

function TemplatesSerializeUtils:IsTable( field )
    return type(field) == "table"
end

function TemplatesSerializeUtils:IsNumber( field )
    return type(field) == "number"
end

function TemplatesSerializeUtils:IsString( field )
    return type(field) == "string"
end

function TemplatesSerializeUtils:IsBoolean( field )
    return type(field) == "boolean"
end

function TemplatesSerializeUtils:toboolean( x )
   return x == "true"
end

function TemplatesSerializeUtils:SerializeObject( field )
    if type( field ) == "table" then
        return TemplatesSerializeUtils:SerializeTable( field )
    end

    return type( field ) .. "=" .. tostring( field )
end

function TemplatesSerializeUtils:SerializeField( fieldName, field )
    return "<" .. fieldName .. "@" .. TemplatesSerializeUtils:SerializeObject( field ) .. ">"
end

function TemplatesSerializeUtils:FindScope( opening, ending, str )
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

function TemplatesSerializeUtils:DeserializeField( data )
    local scope = TemplatesSerializeUtils:FindScope( "<", ">", data )

    local namePos = string.find( data, "@" )

    if ( scope.startPos == nil or scope.endPos == nil or namePos == nil ) then
        return nil
    end

    local name = string.sub( data, scope.startPos + 1, namePos - 1 )
    local value = string.sub( data, namePos + 1, scope.endPos - 1 )

    return {
        name = name,
        value = TemplatesSerializeUtils:DeserializeObject( value ),
        endPos = scope.endPos
    }
end

function TemplatesSerializeUtils:SerializeTable( field )
    local data = type( field ) .. "=" .. "["
    for key, value in pairs( field ) do
        data = data .. TemplatesSerializeUtils:SerializeField( "key", key )
        data = data .. TemplatesSerializeUtils:SerializeField( "value", value )
    end
    return data .. "]"
end

function TemplatesSerializeUtils:DeserializeTable( data )
    local scope = TemplatesSerializeUtils:FindScope( "[", "]", data )

    local object = {}

    local tableData = string.sub( data, scope.startPos + 1, scope.endPos - 1 )
    while tableData ~= nil do

        local keyInfo = TemplatesSerializeUtils:DeserializeField( tableData )
        if ( keyInfo == nil ) then
            break
        end

        tableData = string.sub( tableData, keyInfo.endPos + 1 )

        Assert( keyInfo.name == "key", "Deserialization: expected `key` got `" .. keyInfo.name .. "`" )

        local valueInfo = TemplatesSerializeUtils:DeserializeField( tableData )
        if ( valueInfo == nil ) then
            break
        end

        tableData = string.sub( tableData, valueInfo.endPos + 1 )

        Assert( valueInfo.name == "value", "Deserialization: expected `value` got `" .. valueInfo.name .. "`" )

        if #tableData == 0 then
            tableData = nil
        end

        object[ keyInfo.value ] = valueInfo.value
    end

    return object
end

function TemplatesSerializeUtils:DeserializeObject( data )
    local pos = string.find( data, "=" )

    local type = string.sub( data, 1, pos - 1 )
    local value = string.sub( data, pos + 1 )

    if type == "string" then
        return value
    elseif type == "number" then
        return tonumber( value )
    elseif type == "boolean" then
        return TemplatesSerializeUtils:toboolean( value )
    elseif type == "table" then
        return TemplatesSerializeUtils:DeserializeTable( value )
    end
end

function TemplatesSerializeUtils:SerializeFields( object, fields )
    local data = ""

    for fieldName in Iter( fields ) do
        local field = object[ fieldName ]
        data = data .. TemplatesSerializeUtils:SerializeField( fieldName, field )
    end

    return data
end

function TemplatesSerializeUtils:DeserializeFields( object, data )
    for field in string.gmatch( data, "%b<>" ) do
        local info = TemplatesSerializeUtils:DeserializeField( field )
        object[ info.name ] = info.value
    end
end

return TemplatesSerializeUtils
