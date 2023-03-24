RegisterGlobalEventHandler("EquipItemRequest", function(evt)

    LogService:Log("EquipItemRequest " .. tostring(evt) )

    local entity = evt:GetEntity()
    local itemEnt = evt:GetItemEnt()
    local slot = evt:GetSlot()

    local entityName = EntityService:GetBlueprintName( entity )
    local itemEntName = EntityService:GetBlueprintName( itemEnt )

    LogService:Log("EquipItemRequest slot " .. slot)

    LogService:Log("EquipItemRequest entityName " .. tostring(entityName) .. " entity " .. tostring(entity) )

    LogService:Log("EquipItemRequest itemEntName " .. tostring(itemEntName) .. " itemEnt " .. tostring(itemEnt) )
end)

RegisterGlobalEventHandler("UnequipItemRequest", function(evt)

    LogService:Log("UnequipItemRequest " .. tostring(evt) )

    local entity = evt:GetEntity()
    local itemEnt = evt:GetItemEnt()
    local slot = evt:GetSlot()

    local entityName = EntityService:GetBlueprintName( entity )
    local itemEntName = EntityService:GetBlueprintName( itemEnt )

    LogService:Log("UnequipItemRequest slot " .. slot)

    LogService:Log("UnequipItemRequest entityName " .. tostring(entityName) .. " entity " .. tostring(entity) )

    LogService:Log("UnequipItemRequest itemEntName " .. tostring(itemEntName) .. " itemEnt " .. tostring(itemEnt) )
end)

RegisterGlobalEventHandler("AddItemToInventoryRequest", function(evt)

    LogService:Log("AddItemToInventoryRequest " .. tostring(evt) )

    local inventoryEnt = evt:GetInventoryEnt()
    local item = evt:GetItem()

    local inventoryEntName = EntityService:GetBlueprintName( inventoryEnt )
    local itemName = EntityService:GetBlueprintName( item )

    LogService:Log("AddItemToInventoryRequest inventoryEntName " .. tostring(inventoryEntName) .. " inventoryEnt " .. tostring(inventoryEnt) )

    LogService:Log("AddItemToInventoryRequest itemName " .. tostring(itemName) .. " item " .. tostring(item) )
end)

RegisterGlobalEventHandler("RemoveItemFromInventoryRequest", function(evt)

    LogService:Log("RemoveItemFromInventoryRequest " .. tostring(evt) )

    local inventoryEnt = evt:GetInventoryEnt()
    local item = evt:GetItem()

    local inventoryEntName = EntityService:GetBlueprintName( inventoryEnt )
    local itemName = EntityService:GetBlueprintName( item )

    LogService:Log("RemoveItemFromInventoryRequest inventoryEntName " .. tostring(inventoryEntName) .. " inventoryEnt " .. tostring(inventoryEnt) )

    LogService:Log("RemoveItemFromInventoryRequest itemName " .. tostring(itemName) .. " item " .. tostring(item) )
end)