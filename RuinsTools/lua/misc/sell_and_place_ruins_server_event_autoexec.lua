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

    local stringNumber = string.find( mapperName, "SellAndPlaceRuinsRequest" )
    if ( stringNumber ~= 1 ) then
        return
    end

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive(entity) ) then
        return
    end

    local splitArray = Split( mapperName, "_" )
    if ( #splitArray ~= 2 ) then
        return
    end

    local playerIdStr = splitArray[2]

    local playerId = tonumber(playerIdStr)
    if ( playerId == nil ) then
        return
    end



    local team = EntityService:GetTeam( entity )

    local transform = EntityService:GetWorldTransform( entity )

    local position = transform.position
    local orientation = transform.orientation

    local blueprintName = EntityService:GetBlueprintName( entity )

    local ruinsBlueprintName = blueprintName .. "_ruins"



    local placeRuinScript = EntityService:SpawnEntity( "misc/place_ruin_after_sell/script", position, team )

    local database = EntityService:GetOrCreateDatabase( placeRuinScript )

    database:SetInt( "player_id", playerId )
    database:SetInt( "target_entity", entity )
    database:SetString( "ruins_blueprint", ruinsBlueprintName )

    QueueEvent( "SellBuildingRequest", entity, playerId, false )
end)