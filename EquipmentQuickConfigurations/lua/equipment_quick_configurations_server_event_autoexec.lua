if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")
local EquipmentQuickConfigurationsUtils = require("lua/utils/equipment_quick_configurations_utils.lua")

RegisterGlobalEventHandler("OperateActionMapperRequest", function(evt)

    if ( not is_server ) then
        return
    end

    local mapperName = evt:GetMapperName()

    local stringNumber = string.find( mapperName, "EquipmentQuickConfigurationsNewId" )
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

    local database = EntityService:GetOrCreateDatabase( entity )
    if ( database == nil ) then
        return nil
    end

    local itemKeyConfigName = "$EquipmentQuickConfigurationsUtils_KeyId"

    database:SetString(itemKeyConfigName, itemKey)

    EntityService:CreateComponent( entity, "NetReplicateNextFrameComponent")
end)