RegisterGlobalEventHandler("InventoryItemCreatedEvent", function(evt)

    if (evt == nil) then
        return
    end

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    local itemType = ItemService:GetItemType(entity)
    if ( itemType ~= "turrets_cluster_mod" ) then
        return
    end

    local player_id = 0
    local player = PlayerService:GetPlayerControlledEnt(player_id)
    if ( player == INVALID_ID or player == nil ) then
        return
    end

    local inventoryItemComponent = EntityService:GetComponent(entity, "InventoryItemComponent")
    if ( inventoryItemComponent == nil ) then
        return
    end

    local inventoryItemComponentRef = reflection_helper( inventoryItemComponent )
    if ( inventoryItemComponentRef.owner == nil or inventoryItemComponentRef.owner.id == nil or inventoryItemComponentRef.owner.id == INVALID_ID ) then
        return
    end

    if ( inventoryItemComponentRef.owner.id ~= player ) then
        return
    end

    local turretsClusterItem = ItemService:GetFirstItemForBlueprint( player, "items/consumables/turrets_cluster_standard_item" )
    if ( turretsClusterItem == INVALID_ID ) then
        return
    end

    local database = EntityService:GetDatabase( turretsClusterItem )
    if ( database == nil ) then
        return
    end

    local itemName = ItemService:GetItemName(entity)
    local itemBlueprintName = EntityService:GetBlueprintName( entity )

    for modNumber=1,3 do

        local key = "turrets_cluster_MOD_" .. tostring(modNumber)

        local modItemBlueprintName = database:GetStringOrDefault(key, "") or ""
        if ( modItemBlueprintName == nil or modItemBlueprintName == "" ) then
            goto continue
        end

        if ( modItemBlueprintName == itemBlueprintName ) then
            goto continue
        end

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprintName ) ) then
            goto continue
        end

        local blueprint = ResourceManager:GetBlueprint( modItemBlueprintName )
        if ( blueprint == nil ) then
            goto continue
        end

        local modItemInventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")
        if ( modItemInventoryItemComponent == nil ) then
            goto continue
        end

        local modItemInventoryItemComponentRef = reflection_helper(modItemInventoryItemComponent)

        local modItemName = modItemInventoryItemComponentRef.name

        if ( modItemName == itemName ) then

            database:SetString(key, itemBlueprintName)
        end

        ::continue::
    end
end)
