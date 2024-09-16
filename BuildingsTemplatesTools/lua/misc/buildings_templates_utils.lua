require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local BuildingsTemplatesUtils = {}

function BuildingsTemplatesUtils:GetTemplatesDatabases(selector)

    local campaignDatabase = nil

    if ( CampaignService.GetCampaignData ~= nil ) then
        campaignDatabase = CampaignService:GetCampaignData()
    end

    local selectorDB = nil

    if ( selector ~= nil ) then
        selectorDB = EntityService:GetDatabase( selector )
    end

    return campaignDatabase, selectorDB
end

function BuildingsTemplatesUtils:GetTemplateString(templateName, campaignDatabase, selectorDB)

    local result = ""

    if ( result == "" and campaignDatabase ) then
        result = campaignDatabase:GetStringOrDefault( templateName, "" ) or ""
    end

    if ( result == "" and selectorDB ) then
        result = selectorDB:GetStringOrDefault( templateName, "" ) or ""
    end

    result = result or ""

    return result
end

return BuildingsTemplatesUtils
