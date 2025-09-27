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

    local stringNumber = string.find( mapperName, "CultivatorSaplingToolsReplaceRequest" )
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

    local itemBlueprintName = splitArray[2]

    if ( itemBlueprintName == nil or itemBlueprintName == "" ) then
        return
    end

    local item = ItemService:GetFirstItemForBlueprint( entity, itemBlueprintName )

    if ( item == INVALID_ID ) then

        item = ItemService:AddItemToInventory( entity, itemBlueprintName )
    end

    ItemService:EquipItemInSlot( entity, item, "MOD_1" )

    BuildingService:BlinkBuilding(entity)
    
end)