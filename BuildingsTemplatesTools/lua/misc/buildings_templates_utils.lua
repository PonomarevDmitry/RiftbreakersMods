require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local BuildingsTemplatesUtils = {}

function BuildingsTemplatesUtils:GetTemplatesDatabases(selector)

    local globalPlayerEntityDB = nil
    local selectorDB = nil

    if (selector and selector ~= INVALID_ID) then

        selectorDB = EntityService:GetOrCreateDatabase( selector )

        local playerId = PlayerService:GetPlayerForEntity( selector )

        if ( playerId ~= nil and playerId ~= -1 ) then

            local globalPlayerEntity = PlayerService:GetGlobalPlayerEntity( playerId )

            if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

                globalPlayerEntityDB = EntityService:GetOrCreateDatabase( globalPlayerEntity )
            end
        end
    end



    local campaignDatabase = nil

    if ( CampaignService.GetCampaignData ~= nil ) then
        campaignDatabase = CampaignService:GetCampaignData()
    end



    return globalPlayerEntityDB, selectorDB, campaignDatabase
end

function BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntityDB, selectorDB, campaignDatabase)

    local result = ""

    if ( result == "" and globalPlayerEntityDB and globalPlayerEntityDB:HasString( templateName ) ) then
        result = globalPlayerEntityDB:GetStringOrDefault( templateName, "" ) or ""
    end

    if ( result == "" and selectorDB and selectorDB:HasString( templateName ) ) then
        result = selectorDB:GetStringOrDefault( templateName, "" ) or ""
    end

    if ( result == "" and campaignDatabase and campaignDatabase:HasString( templateName ) ) then
        result = campaignDatabase:GetStringOrDefault( templateName, "" ) or ""

        result = result or ""

        if ( result ~= "" ) then

            if ( globalPlayerEntityDB ) then
                globalPlayerEntityDB:SetString( templateName, result )
            end

            if ( selectorDB ) then
                selectorDB:SetString( templateName, result )
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

    local globalPlayerEntityDB, selectorDB, campaignDatabase = BuildingsTemplatesUtils:GetTemplatesDatabases(selector)



    if ( result == nil and globalPlayerEntityDB and globalPlayerEntityDB:HasInt( configName ) ) then
        result = globalPlayerEntityDB:GetIntOrDefault( configName, 1 )
    end



    if ( result == nil and selectorDB and selectorDB:HasInt( configName ) ) then
        result = selectorDB:GetIntOrDefault( configName, 1 )
    end



    if ( result == nil and campaignDatabase and campaignDatabase:HasInt( configName ) ) then
        result = campaignDatabase:GetIntOrDefault( configName, 1 )
    end



    result = result or 1



    if ( globalPlayerEntityDB ) then
        globalPlayerEntityDB:SetInt( configName, result )
    end

    if ( selectorDB ) then
        selectorDB:SetInt( configName, result )
    end



    return result
end

function BuildingsTemplatesUtils:SetCurrentPersistentDatabase(selector, selectedDatabaseNumber)

    local configName = "$buildings_database_select_config"

    local globalPlayerEntityDB, selectorDB, campaignDatabase = BuildingsTemplatesUtils:GetTemplatesDatabases(selector)

    if ( globalPlayerEntityDB ) then
        globalPlayerEntityDB:SetInt( configName, selectedDatabaseNumber )
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
