require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/reflection.lua")

local VentsToolsUtils = {}

function VentsToolsUtils:GetStoredBlueprints(globalPlayerEntityDB, parameterName)

    if ( globalPlayerEntityDB == nil ) then
        return nil
    end

    local currentListString = ""

    if ( globalPlayerEntityDB and globalPlayerEntityDB:HasString(parameterName) ) then

        currentListString = globalPlayerEntityDB:GetString( parameterName ) or ""
    end

    local result = {}

    if ( currentListString ~= nil and currentListString ~= "" ) then

        local currentListArray = Split( currentListString, "|" )

        for blueprintCount in Iter( currentListArray ) do

            local splitBlueprintCount = Split( blueprintCount, "," )

            if (#splitBlueprintCount ~= 2) then

                goto continueLabel
            end

            local resourceName = splitBlueprintCount[1]
            local countString = splitBlueprintCount[2]

            if ( resourceName == nil or resourceName == "" or countString == nil or countString == "" ) then
                goto continueLabel
            end

            if ( not ResourceManager:ResourceExists( "GameplayResourceDef", resourceName ) ) then

                goto continueLabel
            end

            local count = tonumber(countString)
            if ( count == nil or count <=0 ) then

                goto continueLabel
            end

            result[resourceName] = count

            ::continueLabel::
        end
    end

    return result
end

function VentsToolsUtils:FormatStoredBlueprintsString(storeBlueprints)

    local keys = {}

    for resourceName, count in pairs( storeBlueprints ) do
        
        Insert(keys, resourceName)
    end

    table.sort(keys)

    local currentListArray = {} 

    for resourceName in Iter( keys ) do

        if ( resourceName == nil or resourceName == "" ) then
            goto continueLabel
        end

        local count = storeBlueprints[resourceName]

        if ( count == nil or count <=0 ) then
            goto continueLabel
        end

        if ( not ResourceManager:ResourceExists( "GameplayResourceDef", resourceName ) ) then

            goto continueLabel
        end

        local splitBlueprintCount = tostring(resourceName) .. "," .. tostring(count)

        Insert(currentListArray, splitBlueprintCount)

        ::continueLabel::
    end

    local currentListString = ""

    if ( #currentListArray > 0 ) then

        currentListString = table.concat( currentListArray, "|" )
    end

    return currentListString
end

function VentsToolsUtils:SaveStoredBlueprints(globalPlayerEntity, globalPlayerEntityDB, parameterName, storeBlueprints)

    local currentListString = VentsToolsUtils:FormatStoredBlueprintsString(storeBlueprints)

    if ( globalPlayerEntityDB ) then
        globalPlayerEntityDB:SetString(parameterName, currentListString)
    end

    if not ( is_server and is_client ) then

        local mapperName = "SetGlobalPlayerEntityDatabaseString|" .. parameterName .. "|" .. currentListString

        QueueEvent("OperateActionMapperRequest", globalPlayerEntity, mapperName, false )
    end
end

return VentsToolsUtils