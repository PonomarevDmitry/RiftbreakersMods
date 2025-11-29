require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local BuildingsTemplatesUtils = {}

function BuildingsTemplatesUtils:GetTemplatesDatabases(selector)

    local selectorDB = nil
    local globalPlayerEntity = nil

    if (selector and selector ~= INVALID_ID) then

        selectorDB = EntityService:GetOrCreateDatabase( selector )

        local playerId = PlayerService:GetPlayerForEntity( selector )

        if ( playerId ~= nil and playerId ~= -1 ) then

            globalPlayerEntity = PlayerService:GetGlobalPlayerEntity( playerId )

            if ( globalPlayerEntity == INVALID_ID ) then

                globalPlayerEntity = nil
            end
        end
    end

    return globalPlayerEntity, selectorDB
end

function BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB)

    local result = ""

    if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

        local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

        if ( globalPlayerEntityDB and globalPlayerEntityDB:HasString( templateName ) ) then
            result = globalPlayerEntityDB:GetStringOrDefault( templateName, "" ) or ""
        end
    end

    

    if ( result == "" and selectorDB and selectorDB:HasString( templateName ) ) then
        result = selectorDB:GetStringOrDefault( templateName, "" ) or ""

        if ( result ~= "" ) then

            if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

                local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

                if ( globalPlayerEntityDB ) then
                    globalPlayerEntityDB:SetString( templateName, result )
                end

                if not ( is_server and is_client ) then

                    local mapperName = "SetGlobalPlayerEntityDatabaseString|" .. templateName .. "|" .. result

                    QueueEvent("OperateActionMapperRequest", globalPlayerEntity, mapperName, false )
                end
            end
        end
    end



    if ( result == "" and CampaignService.GetCampaignData ~= nil ) then

        local campaignDatabase = CampaignService:GetCampaignData()

        if ( campaignDatabase and campaignDatabase:HasString( templateName ) ) then

            result = campaignDatabase:GetStringOrDefault( templateName, "" ) or ""

            if ( result ~= "" ) then

                if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

                    local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

                    if ( globalPlayerEntityDB ) then
                        globalPlayerEntityDB:SetString( templateName, result )
                    end

                    if not ( is_server and is_client ) then

                        local mapperName = "SetGlobalPlayerEntityDatabaseString|" .. templateName .. "|" .. result

                        QueueEvent("OperateActionMapperRequest", globalPlayerEntity, mapperName, false )
                    end
                end

                if ( selectorDB ) then
                    selectorDB:SetString( templateName, result )
                end
            end
        end
    end

    result = result or ""

    return result
end

function BuildingsTemplatesUtils:GetPersistentDatabase(selectedDatabaseNumber)

    local databaseName = "BuildingsTemplatesTools_" .. string.format( "%02d", selectedDatabaseNumber )

    local result = PlayerService:GetOrCreateGlobalDatabase(databaseName)

    return result
end

function BuildingsTemplatesUtils:IsTemplateEquals(templateString1, templateString2)

    templateString1 = templateString1 or ""
    templateString2 = templateString2 or ""

    if ( templateString1 == "" and templateString2 == "" ) then

        return true
    end

    if ( templateString1 ~= "" and templateString2 == "" ) then

        return false
    end

    if ( templateString1 == "" and templateString2 ~= "" ) then

        return false
    end

    if ( templateString1 == templateString2 ) then

        return true
    end

    return false
end

function BuildingsTemplatesUtils:GetCurrentPersistentDatabase(selector)

    local configName = "$buildings_database_select_config"

    local result = nil

    local globalPlayerEntity, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(selector)




    if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

        local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

        if ( globalPlayerEntityDB and globalPlayerEntityDB:HasInt( configName ) ) then
            result = globalPlayerEntityDB:GetIntOrDefault( configName, 1 )
        end
    end





    if ( result == nil and selectorDB and selectorDB:HasInt( configName ) ) then
        result = selectorDB:GetIntOrDefault( configName, 1 )
    end





    if ( result == nil and CampaignService.GetCampaignData ~= nil ) then

        local campaignDatabase = CampaignService:GetCampaignData()

        if ( campaignDatabase and campaignDatabase:HasInt( configName ) ) then
            result = campaignDatabase:GetIntOrDefault( configName, 1 )
        end
    end



    result = result or 1



    if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

        local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

        if ( globalPlayerEntityDB ) then
            globalPlayerEntityDB:SetInt( configName, result )
        end

        if not ( is_server and is_client ) then

            local mapperName = "SetGlobalPlayerEntityDatabaseInt|" .. configName .. "|" .. tostring(result)

            QueueEvent("OperateActionMapperRequest", globalPlayerEntity, mapperName, false )
        end
    end



    if ( selectorDB ) then
        selectorDB:SetInt( configName, result )
    end



    return result
end

function BuildingsTemplatesUtils:SetCurrentPersistentDatabase(selector, selectedDatabaseNumber)

    local configName = "$buildings_database_select_config"

    local globalPlayerEntity, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(selector)

    if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

        local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

        if ( globalPlayerEntityDB ) then
            globalPlayerEntityDB:SetInt( configName, selectedDatabaseNumber )
        end

        if not ( is_server and is_client ) then

            local mapperName = "SetGlobalPlayerEntityDatabaseInt|" .. configName .. "|" .. tostring(selectedDatabaseNumber)

            QueueEvent("OperateActionMapperRequest", globalPlayerEntity, mapperName, false )
        end
    end

    if ( selectorDB ) then
        selectorDB:SetInt( configName, selectedDatabaseNumber )
    end
end

function BuildingsTemplatesUtils:GetMaxAvailableTemplate()

    for number = 60, 1, -1 do

        local pickerToolBlueprint = "buildings/tools/buildings_picker_" .. string.format( "%02d", number )

        if ( ResourceManager:ResourceExists( "EntityBlueprint", pickerToolBlueprint ) ) then

            return number
        end
    end

    return 1
end

return BuildingsTemplatesUtils
