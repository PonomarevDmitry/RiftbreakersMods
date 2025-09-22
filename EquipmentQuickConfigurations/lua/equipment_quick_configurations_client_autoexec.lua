LogService:Log("Autoexec Load is_server " .. tostring(is_server) .. " is_client " .. tostring(is_client))

if ( not is_client ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
local EquipmentQuickConfigurationsUtils = require("lua/utils/equipment_quick_configurations_utils.lua")

globalEquipmentQuickConfigurationsUtilsEntitiesCache = globalEquipmentQuickConfigurationsUtilsEntitiesCache or {}



RegisterGlobalEventHandler("InventoryItemCreatedEvent", function(evt)

    if ( not is_client ) then
        return
    end

    --LogService:Log("InventoryItemCreatedEvent is_server " .. tostring(is_server) .. " is_client " .. tostring(is_client))

    if (evt == nil) then
        return
    end

    local entity = evt:GetEntity()

    if ( entity == nil or entity == INVALID_ID) then
        return
    end

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    local itemType = ItemService:GetItemType(entity)

    local isRightType = EquipmentQuickConfigurationsUtils:IsRightType(itemType)
    if ( not isRightType ) then
        return
    end

    local itemDatabaseKey = EquipmentQuickConfigurationsUtils:GetItemKey( entity )
    if ( itemDatabaseKey == "" or itemDatabaseKey == nil ) then
        return
    end

    globalEquipmentQuickConfigurationsUtilsEntitiesCache[itemDatabaseKey] = entity
end)
