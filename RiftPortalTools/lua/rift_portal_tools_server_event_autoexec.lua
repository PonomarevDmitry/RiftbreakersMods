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

    local stringNumber = string.find( mapperName, "RiftPortalTool" )

    if ( stringNumber ~= 1 ) then
        return
    end

    local splitArray = Split( mapperName, "_" )

    if ( #splitArray ~= 3 ) then
        return
    end

    local playerIdStr = splitArray[2]

    local playerId = tonumber(playerIdStr)

    local cellEntityStr = splitArray[3]

    local cellEntity = tonumber(cellEntityStr)

    if ( cellEntity == nil or playerId == nil ) then
        return
    end

    if ( not EntityService:IsAlive( cellEntity ) ) then
        return
    end



    local position = FindService:GetCellOrigin(cellEntity)

    if ( FindService:IsGridMarkedWithLayer(position, "TeleportBlockerLayerComponent") ) then
        return
    end

    if ( FindService:IsGridMarkedWithLayer(position, "WorldBlockerLayerComponent") ) then
        return
    end

    local blueprintName = "misc/rift"



    local entities = FindService:FindEntitiesByBlueprint( blueprintName )

    for entity in Iter( entities ) do

        local playerReferenceComponent = EntityService:GetComponent( entity, "PlayerReferenceComponent" )
        if (playerReferenceComponent) then

            local playerReferenceComponentRef = reflection_helper(playerReferenceComponent)

            if (playerReferenceComponentRef and playerReferenceComponentRef.player_id == playerId) then

                QueueEvent( "DissolveEntityRequest", entity, 0.2, 0 )
            end
        end
    end


    local player = PlayerService:GetPlayerControlledEnt(playerId)

    local team = EntityService:GetTeam( player )

    local newPortal = EntityService:SpawnEntity( blueprintName, position, team )

    local playerReferenceComponentRef = reflection_helper(EntityService:CreateComponent(newPortal, "PlayerReferenceComponent"))
    playerReferenceComponentRef.player_id = playerId
    playerReferenceComponentRef.reference_type.internal_enum = 3

    EntityService:CreateComponent( newPortal, "NetReplicateToOwnerComponent")
end)