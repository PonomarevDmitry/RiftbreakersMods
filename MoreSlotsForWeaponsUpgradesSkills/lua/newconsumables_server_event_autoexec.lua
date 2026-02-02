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

    local stringNumber = string.find( mapperName, "ActivateAdditionalSlotRequest" )
    if ( stringNumber ~= 1 ) then

        return
    end

    local splitArray = Split( mapperName, "|" )
    if ( #splitArray ~= 3 ) then
        return
    end
        
    local slotName = splitArray[3]
    if ( slotName == nil or slotName == "" ) then
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

    if ( not EntityService:IsAlive( player ) ) then
        return
    end

    local slotItem = ItemService:GetEquippedItem( player, slotName )

    if ( slotItem == nil ) then
        return
    end

    local slotItemType = ItemService:GetItemType( slotItem )

    if ( not ItemService:CanActivateItemSlot( player, slotName, slotItemType ) ) then
        return
    end

    --LogService:Log("ActivateAdditionalSlotRequest " .. tostring(slotName) .. " ActivateEquipmentSlotRequest" )
    --QueueEvent("ActivateEquipmentSlotRequest", player, slotName, "" )
    --QueueEvent("DeactivateEquipmentSlotRequest", player, slotName, true )


    LogService:Log("ActivateAdditionalSlotRequest " .. tostring(slotName) .. " UseEquippedItem" )

    ItemService:UseEquippedItem( player, slotName )
    ItemService:StopUsingEquippedItem( player, slotName )
    
end)