if ( not is_client ) then
    return
end

if ( is_server and is_client ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

local EquipmentQuickConfigurationsUtils = require("lua/utils/equipment_quick_configurations_utils.lua")

globalEquipmentQuickConfigurationsUtilsEntitiesCache = globalEquipmentQuickConfigurationsUtilsEntitiesCache or {}



RegisterGlobalEventHandler("OperateActionMapperRequest", function(evt)

    if ( not is_client ) then
        return
    end

    if ( is_server and is_client ) then
        return
    end

    local mapperName = evt:GetMapperName()

    local stringNumber = string.find( mapperName, "EquipmentQuickConfigurationsItemKeyNewId" )
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

    local itemKey = splitArray[2]

    local itemType = ItemService:GetItemType(entity)

    local isRightType = EquipmentQuickConfigurationsUtils:IsRightType(itemType)
    if ( not isRightType ) then
        return
    end

    globalEquipmentQuickConfigurationsUtilsEntitiesCache[itemKey] = entity

    --LogService:Log("EquipmentQuickConfigurationsItemKeyNewId entity " .. tostring(entity) .. " inventoryEntBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " itemKey \"" .. tostring(itemKey) .. "\"")
end)