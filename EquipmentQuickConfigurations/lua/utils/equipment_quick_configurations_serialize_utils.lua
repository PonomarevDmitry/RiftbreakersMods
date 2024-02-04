require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local QuickEquipmentSerializeUtils = {}

function QuickEquipmentSerializeUtils:IsTable( field )
    return type(field) == "table"
end

function QuickEquipmentSerializeUtils:IsNumber( field )
    return type(field) == "number"
end

function QuickEquipmentSerializeUtils:IsString( field )
    return type(field) == "string"
end

function QuickEquipmentSerializeUtils:IsBoolean( field )
    return type(field) == "boolean"
end

function QuickEquipmentSerializeUtils:toboolean( x )
   return x == "true"
end

function QuickEquipmentSerializeUtils:SerializeObject( field )
    if type( field ) == "table" then
        return QuickEquipmentSerializeUtils:SerializeTable( field )
    end

    return type( field ) .. "=" .. tostring( field )
end

function QuickEquipmentSerializeUtils:SerializeField( fieldName, field )
    return "<" .. fieldName .. ":" .. QuickEquipmentSerializeUtils:SerializeObject( field ) .. ">"
end

function QuickEquipmentSerializeUtils:FindScope( opening, ending, str )
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

function QuickEquipmentSerializeUtils:DeserializeField( data )
    local scope = QuickEquipmentSerializeUtils:FindScope( "<", ">", data )
    if ( scope.startPos == nil or scope.endPos == nil ) then
        return nil 
    end

    local namePos = string.find( data, ":" )
    if ( namePos == nil ) then
        return nil 
    end
    
    local name = string.sub( data, scope.startPos + 1, namePos - 1 )
    local value = string.sub( data, namePos + 1, scope.endPos - 1 )

    return {
        name = name,
        value = QuickEquipmentSerializeUtils:DeserializeObject( value ),
        endPos = scope.endPos
    }
end

function QuickEquipmentSerializeUtils:SerializeTable( field )
    local data = type( field ) .. "=" .. "["
    for key, value in pairs( field ) do
        data = data .. QuickEquipmentSerializeUtils:SerializeField( "key", key )
        data = data .. QuickEquipmentSerializeUtils:SerializeField( "value", value )
    end
    return data .. "]"
end

function QuickEquipmentSerializeUtils:DeserializeTable( data )
    local object = {}

    local scope = QuickEquipmentSerializeUtils:FindScope( "[", "]", data )
    if ( scope.startPos == nil or scope.endPos == nil ) then
        return object 
    end

    local tableData = string.sub( data, scope.startPos + 1, scope.endPos - 1 )
    while tableData ~= nil do
        local keyInfo = QuickEquipmentSerializeUtils:DeserializeField( tableData )
        
        if ( keyInfo == nil ) then
            break
        end
        
        tableData = string.sub( tableData, keyInfo.endPos + 1 )

        Assert( keyInfo.name == "key", "QuickEquipmentSerializeUtils.Deserialization: expected `key` got `" .. keyInfo.name .. "`" )

        local valueInfo = QuickEquipmentSerializeUtils:DeserializeField( tableData )
        
        
        if ( valueInfo == nil ) then
            break
        end
        
        tableData = string.sub( tableData, valueInfo.endPos + 1 )

        Assert( valueInfo.name == "value", "QuickEquipmentSerializeUtils.Deserialization: expected `value` got `" .. valueInfo.name .. "`" )

        if #tableData == 0 then
            tableData = nil
        end

        object[ keyInfo.value ] = valueInfo.value
    end

    return object
end

function QuickEquipmentSerializeUtils:DeserializeObject( data )
    local pos = string.find( data, "=" )

    if ( pos == nil ) then
        return nil
    end

    local type = string.sub( data, 1, pos - 1 )
    local value = string.sub( data, pos + 1 )

    if type == "string" then
        return value
    elseif type == "number" then
        return tonumber( value )
    elseif type == "boolean" then
        return QuickEquipmentSerializeUtils:toboolean( value )
    elseif type == "table" then
        return QuickEquipmentSerializeUtils:DeserializeTable( value )
    end
end

function QuickEquipmentSerializeUtils:SerializeFields( object, fields )
    local data = ""

    for fieldName in Iter( fields ) do
        local field = object[ fieldName ]
        data = data .. QuickEquipmentSerializeUtils:SerializeField( fieldName, field )
    end

    return data
end

function QuickEquipmentSerializeUtils:DeserializeFields( object, data )
    for field in string.gmatch( data, "%b<>" ) do
        local info = QuickEquipmentSerializeUtils:DeserializeField( field )
        object[ info.name ] = info.value
    end
end

return QuickEquipmentSerializeUtils
