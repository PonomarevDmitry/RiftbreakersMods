require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

ConsoleService:RegisterCommand( "test_log_global", function( args )

    local keysNames = {}
    local maxLenKey = 0
    local maxLenType = 0

    for key,value in pairs(_G) do
        Insert(keysNames, key)

        maxLenKey = math.max(maxLenKey, string.len( tostring(key) ))

        maxLenType = math.max(maxLenType, string.len( tostring(type( value )) ))
    end

    table.sort( keysNames )

    LogService:Log("Start Global Description maxLenKey " .. tostring(maxLenKey) .. " maxLenType " .. tostring(maxLenType))

    for key in Iter(keysNames) do

        local value = _G[key]

        local keyString = tostring(key)

        local typeString = tostring(type( value ))

        local valueString = tostring(value)

        local message = "Global key " .. keyString .. string.rep(" ", maxLenKey - string.len(keyString)) .. "        type " .. typeString .. string.rep(" ", maxLenType - string.len(typeString)) .. "        value " .. valueString

        LogService:Log(message)
    end

    LogService:Log("End Global Description")
end)