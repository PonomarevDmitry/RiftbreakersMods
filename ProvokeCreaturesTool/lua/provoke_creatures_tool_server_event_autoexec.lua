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

    local stringNumber = string.find( mapperName, "ProvokeCreaturesTool" )

    if ( stringNumber ~= 1 ) then
        return
    end

    local splitArray = Split( mapperName, "_" )

    if ( #splitArray ~= 3 ) then
        return
    end

    local cellEntityStr = splitArray[2]

    local cellEntity = tonumber(cellEntityStr)

    local radiusStr = splitArray[3]

    local radius = tonumber(radiusStr)

    if ( cellEntity == nil or radius == nil ) then
        return
    end

    if ( radius <= 0 ) then
        return
    end

    if ( not EntityService:IsAlive( cellEntity ) ) then
        return
    end



    local position = FindService:GetCellOrigin(cellEntity)

    local currentTarget = EntityService:SpawnEntity( position )

    EntityService:CreateLifeTime( currentTarget, 0.1, "normal" )

    EffectService:SpawnEffect( currentTarget, "effects/enemies_generic/wave_start" )

    EntityService:ChangeAIGroupsToAggressive( currentTarget, radius, true )
end)