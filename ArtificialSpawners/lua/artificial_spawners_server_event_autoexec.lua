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

    local stringNumber = string.find( mapperName, "ArtificialSpawnersReplaceRequest" )
    if ( stringNumber == 1 ) then

        local entity = evt:GetEntity()

        if ( not EntityService:IsAlive(entity) ) then
            return
        end

        local splitArray = Split( mapperName, "|" )
        if ( #splitArray ~= 3 ) then
            return
        end
        
        local slotName = splitArray[2]
        if ( slotName == nil or slotName == "" ) then
            return
        end

        local modItemBlueprintName = splitArray[3]
        if ( modItemBlueprintName == nil or modItemBlueprintName == "" ) then
            return
        end

        local item = ItemService:GetFirstItemForBlueprint( entity, modItemBlueprintName )

        if ( item == INVALID_ID ) then

            item = ItemService:AddItemToInventory( entity, modItemBlueprintName )
        end

        ItemService:EquipItemInSlot( entity, item, slotName )

        BuildingService:BlinkBuilding(entity)

        return
    end

    

    local stringNumber = string.find( mapperName, "ArtificialSpawnersActivateSingleRequest" )
    if ( stringNumber == 1 ) then

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

        local player = PlayerService:GetPlayerControlledEnt( playerId )
        if ( player == nil or player == INVALID_ID ) then
            return
        end

        QueueEvent( "InteractWithEntityRequest", entity, player )

        return
    end
    
end)