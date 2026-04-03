require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/reflection.lua")

local PowerWellsToolsUtils = {}

function PowerWellsToolsUtils:GetStoredBlueprints(globalPlayerEntityDB, parameterName)

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

            local blueprintName = splitBlueprintCount[1]
            local countString = splitBlueprintCount[2]

            if ( blueprintName == nil or blueprintName == "" or countString == nil or countString == "" ) then
                goto continueLabel
            end

            if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then

                goto continueLabel
            end

            local count = tonumber(countString)
            if ( count == nil or count <=0 ) then

                goto continueLabel
            end

            result[blueprintName] = count

            ::continueLabel::
        end
    end

    return result
end

function PowerWellsToolsUtils:SaveStoredBlueprints(globalPlayerEntity, globalPlayerEntityDB, parameterName, storeBlueprints)

    local keys = {}

    for blueprintName, count in pairs( storeBlueprints ) do
        
        Insert(keys, blueprintName)
    end

    table.sort(keys)

    local currentListArray = {} 

    for blueprintName in Iter( keys ) do

        if ( blueprintName == nil or blueprintName == "" ) then
            goto continueLabel
        end

        local count = storeBlueprints[blueprintName]

        if ( count == nil or count <=0 ) then
            goto continueLabel
        end

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then

            goto continueLabel
        end

        local splitBlueprintCount = tostring(blueprintName) .. "," .. tostring(count)

        Insert(currentListArray, splitBlueprintCount)

        ::continueLabel::
    end

    local currentListString = ""

    if ( #currentListArray > 0 ) then

        currentListString = table.concat( currentListArray, "|" )
    end

    if ( globalPlayerEntityDB ) then
        globalPlayerEntityDB:SetString(parameterName, currentListString)
    end

    if not ( is_server and is_client ) then

        local mapperName = "SetGlobalPlayerEntityDatabaseString|" .. parameterName .. "|" .. currentListString

        QueueEvent("OperateActionMapperRequest", globalPlayerEntity, mapperName, false )
    end
end

return PowerWellsToolsUtils