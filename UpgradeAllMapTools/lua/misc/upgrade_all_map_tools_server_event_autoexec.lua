if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

RegisterGlobalEventHandler("OperateActionMapperRequest", function(evt)

    if ( not is_server ) then
        return
    end

    local mapperName = evt:GetMapperName()

    local stringNumber = string.find( mapperName, "UpgradeAllMapToolsForceUpgrade" )
    if ( stringNumber ~= 1 ) then
        return
    end

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive(entity) ) then
        return
    end

    local splitArray = Split( mapperName, "|" )
    if ( #splitArray ~= 2 ) then
        return
    end

    local playerIdStr = splitArray[2]

    local playerId = tonumber(playerIdStr)
    if ( playerId == nil ) then
        return
    end


    QueueEvent( "UpgradeBuildingRequest", entity, playerId )

end)