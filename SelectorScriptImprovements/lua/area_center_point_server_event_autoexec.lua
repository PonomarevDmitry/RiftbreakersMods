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

    local stringNumber = string.find( mapperName, "AreaCenterPointChangeRequest" )
    if ( stringNumber ~= 1 ) then
        return
    end

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive(entity) ) then
        return
    end


    local splitArray = Split( mapperName, "|" )
    if ( #splitArray ~= 3 ) then
        return
    end

    local pointXStr = splitArray[2]
    local pointZStr = splitArray[3]

    local pointX = tonumber(pointXStr)
    local pointZ = tonumber(pointZStr)

    if ( pointX == nil or pointZ == nil ) then
        return
    end

    local params = {
        point_x = pointX,
        point_z = pointZ,
    }

    QueueEvent( "LuaGlobalEvent", entity, "AreaCenterPointChangeEvent", params )

end)