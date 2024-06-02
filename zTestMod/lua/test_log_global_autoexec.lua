require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

ConsoleService:RegisterCommand( "test_log_global", function( args )

    local keysNames = {}
    local maxLenKey = 0
    local maxLenType = 0

    for key,value in pairs(_G) do

        maxLenKey = math.max(maxLenKey, string.len( tostring(key) ))

        local typeString  = tostring(type( value ))

        maxLenType = math.max(maxLenType, string.len( typeString ))

        local keyObj = {
            name = key,
            type = typeString
        }

        Insert(keysNames, keyObj)
    end

    local sorter = function(a, b)

        if ( a.type == b.type ) then
            return a.name:upper() < b.name:upper()
        end

        return a.type < b.type
    end

    table.sort( keysNames, sorter )

    LogService:Log("Start Global Description")

    for keyObj in Iter(keysNames) do

        local value = _G[keyObj.name]

        local keyString = tostring(keyObj.name)

        local typeString = tostring(type( value ))

        local valueString = tostring(value)

        local message = "Global key " .. keyString .. string.rep(" ", maxLenKey - string.len(keyString)) .. "        type " .. typeString .. string.rep(" ", maxLenType - string.len(typeString)) .. "        value " .. valueString

        LogService:Log(message)
    end

    LogService:Log("End Global Description")
end)