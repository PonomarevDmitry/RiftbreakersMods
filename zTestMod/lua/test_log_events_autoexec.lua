


--RegisterGlobalEventHandler("EquipItemRequest", function(evt)
--
--    local text = "EquipItemRequest " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--
--        local itemEnt = evt:GetItemEnt()
--
--        local slot = evt:GetSlot()
--
--        text = text .. "\n" .. "slot " .. tostring(slot)
--
--        text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)
--
--        text = text .. "\n" .. "itemEntBlueprintName " .. tostring(EntityService:GetBlueprintName( itemEnt )) .. " itemEnt " .. tostring(itemEnt)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)
--
--RegisterGlobalEventHandler("EquipItemEvent", function(evt)
--
--    local text = "EquipItemEvent " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--
--        local itemEnt = evt:GetItemEnt()
--
--        local owner = evt:GetOwner()
--
--        local slot = evt:GetSlot()
--
--        text = text .. "\n" .. "slot " .. tostring(slot)
--
--        text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)
--
--        text = text .. "\n" .. "itemEntBlueprintName " .. tostring(EntityService:GetBlueprintName( itemEnt )) .. " itemEnt " .. tostring(itemEnt)
--
--        text = text .. "\n" .. "ownerBlueprintName " .. tostring(EntityService:GetBlueprintName( owner )) .. " owner " .. tostring(owner)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)
--
--RegisterGlobalEventHandler("ItemEquipedEvent", function(evt)
--
--    local text = "ItemEquipedEvent " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--
--        local item = evt:GetItem()
--
--        local slot = evt:GetSlot()
--
--        text = text .. "\n" .. "slot " .. tostring(slot)
--
--        text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)
--
--        text = text .. "\n" .. "itemBlueprintName " .. tostring(EntityService:GetBlueprintName( item )) .. " item " .. tostring(item)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)
--
--RegisterGlobalEventHandler("ItemUnequippedEvent", function(evt)
--
--    local text = "ItemUnequippedEvent " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--
--        local slot = evt:GetSlot()
--
--        text = text .. "\n" .. "slot " .. tostring(slot)
--
--        text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)
--
--RegisterGlobalEventHandler("UnequipItemRequest", function(evt)
--
--    local text = "UnequipItemRequest " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--
--        local itemEnt = evt:GetItemEnt()
--
--        local slot = evt:GetSlot()
--
--        text = text .. "\n" .. "slot " .. tostring(slot)
--
--        text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)
--
--        text = text .. "\n" .. "itemBlueprintName " .. tostring(EntityService:GetBlueprintName( itemEnt ))  .. " itemEnt " .. tostring(itemEnt)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)





--RegisterGlobalEventHandler("ItemCraftedEvent", function(evt)
--
--    local text = "ItemCraftedEvent " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local blueprint = evt:GetBlueprint()
--
--        local item = evt:GetItem()
--
--        local itemName = ItemService:GetItemName( item )
--
--        local sink = evt:GetSink()
--
--        text = text .. "\n" .. "blueprint " .. tostring(blueprint)
--
--        text = text .. "\n" .. "sinkBlueprintName " .. tostring(EntityService:GetBlueprintName( sink )) .. " sink " .. tostring(sink)
--
--        text = text .. "\n" .. "itemBlueprintName " .. tostring(EntityService:GetBlueprintName( item )) .. " item " .. tostring(item)
--
--        text = text .. "\n" .. "itemName " .. tostring(itemName)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)


--RegisterGlobalEventHandler("AddItemToInventoryRequest", function(evt)
--
--    local text = "AddItemToInventoryRequest " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local item = evt:GetItem()
--
--        local inventoryEnt = evt:GetInventoryEnt()
--
--        local itemName = ItemService:GetItemName( item )
--
--        text = text .. "\n" .. "itemBlueprintName " .. tostring(EntityService:GetBlueprintName( item )) .. " item " .. tostring(item)
--
--        text = text .. "\n" .. "itemName " .. tostring(itemName)
--
--        text = text .. "\n" .. "inventoryEntBlueprintName " .. tostring(EntityService:GetBlueprintName( inventoryEnt )) .. " inventoryEnt " .. tostring(inventoryEnt)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)


--RegisterGlobalEventHandler("RemoveItemFromInventoryRequest", function(evt)
--
--    local text = "RemoveItemFromInventoryRequest " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local item = evt:GetItem()
--
--        local inventoryEnt = evt:GetInventoryEnt()
--
--        local itemName = ItemService:GetItemName( item )
--
--        text = text .. "\n" .. "itemBlueprintName " .. tostring(EntityService:GetBlueprintName( item )) .. " item " .. tostring(item)
--
--        text = text .. "\n" .. "itemName " .. tostring(itemName)
--
--        text = text .. "\n" .. "inventoryEntBlueprintName " .. tostring(EntityService:GetBlueprintName( inventoryEnt )) .. " inventoryEnt " .. tostring(inventoryEnt)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)


--RegisterGlobalEventHandler("CreateItemInInventoryRequest", function(evt)
--
--    local text = "CreateItemInInventoryRequest " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local item = evt:GetItem()
--
--        local inventoryEnt = evt:GetInventoryEnt()
--
--        local eventType = evt:GetEventType()
--
--        text = text .. "\n" .. "eventType " .. tostring(eventType)
--
--        text = text .. "\n" .. "item " .. tostring(item)
--
--        text = text .. "\n" .. "inventoryEntBlueprintName " .. tostring(EntityService:GetBlueprintName( inventoryEnt )) .. " inventoryEnt " .. tostring(inventoryEnt)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)


--RegisterGlobalEventHandler("InventoryItemCreatedEvent", function(evt)
--
--    local text = "InventoryItemCreatedEvent " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--
--        text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)


--RegisterGlobalEventHandler("NetReplicateEntityRequest", function(evt)
--
--    local text = "NetReplicateEntityRequest " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--
--        local options = evt:GetOptions()
--
--        local playerId = evt:GetPlayerId()
--
--        --local signature = evt:GetSignature()
--
--        --text = text .. "\n" .. "signature " .. tostring(signature)
--
--        text = text .. "\n" .. "playerId " .. tostring(playerId)
--
--        text = text .. "\n" .. "options " .. tostring(options)
--
--        text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)





--RegisterGlobalEventHandler("AddToResearchRequest", function(evt)
--
--    local text = "AddToResearchRequest " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--
--        local research = evt:GetResearch()
--
--        local playerId = evt:GetPlayerId()
--
--        text = text .. "\n" .. "research " .. tostring(research)
--
--        text = text .. "\n" .. "playerId " .. tostring(playerId)
--
--        text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)

--RegisterGlobalEventHandler("AddedToResearchEvent", function(evt)
--
--    local text = "AddedToResearchEvent " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--
--        local name = evt:GetName()
--
--        local teamId = evt:GetTeamId()
--
--        text = text .. "\n" .. "name " .. tostring(name)
--
--        if ( teamId ~= nil ) then
--            text = text .. "\n" .. "teamId " .. tostring(teamId)
--        end
--
--        text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)



--RegisterGlobalEventHandler("RemovedFromResearchRequest", function(evt)
--
--    local text = "RemovedFromResearchRequest " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--
--        local research = evt:GetResearch()
--
--        local playerId = evt:GetPlayerId()
--
--        text = text .. "\n" .. "research " .. tostring(research)
--
--        text = text .. "\n" .. "playerId " .. tostring(playerId)
--
--        text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)

--RegisterGlobalEventHandler("RemovedFromResearchEvent", function(evt)
--
--    local text = "RemovedFromResearchEvent " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--
--        local name = evt:GetName()
--
--        local teamId = evt:GetTeamId()
--
--        text = text .. "\n" .. "name " .. tostring(name)
--
--        if ( teamId ~= nil ) then
--            text = text .. "\n" .. "teamId " .. tostring(teamId)
--        end
--
--        text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)

--RegisterGlobalEventHandler("NewResearchAvailableEvent", function(evt)
--
--    local text = "NewResearchAvailableEvent " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--
--        local name = evt:GetName()
--
--        text = text .. "\n" .. "name " .. tostring(name)
--
--        text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)





--RegisterGlobalEventHandler("ResearchUnlockedEvent", function(evt)
--
--    local text = "ResearchUnlockedEvent " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--
--        local name = evt:GetName()
--
--        local teamId = evt:GetTeamId()
--
--        local emptyCosts = evt:GetEmptyCosts()
--
--        text = text .. "\n" .. "name " .. tostring(name)
--
--        text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)
--
--        if ( teamId ~= nil ) then
--            text = text .. "\n" .. "teamId " .. tostring(teamId)
--        end
--
--        text = text .. "\n" .. "emptyCosts " .. tostring(emptyCosts)
--
--        --local awards = evt:GetAwards()
--        --if ( awards ~= nil ) then
--        --
--        --    for i=1,#awards do
--        --    
--        --        local award = awards[i]
--        --
--        --        text = text .. "\n" .. "award index " .. tostring(i) .. " blueprint " .. tostring(award.blueprint) .. " is_visible " .. tostring(award.is_visible)
--        --    end
--        --end
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)




--RegisterGlobalEventHandler("ResourceMissingEvent", function(evt)
--
--    local text = "ResourceMissingEvent " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--        local entityName = EntityService:GetBlueprintName( entity )
--
--        local negative = evt:GetNegative()
--
--        local resource = evt:GetResource()
--
--        local family = evt:GetFamily()
--
--        text = text .. "\n" .. "negative " .. tostring(negative)
--
--        text = text .. "\n" .. "resource " .. tostring(resource)
--
--        text = text .. "\n" .. "family " .. tostring(family)
--
--        text = text .. "\n" .. "entityName " .. tostring(entityName)
--
--        text = text .. "\n" .. "entity " .. tostring(entity)
--    end
--
--    LogService:Log(text)
--end)




--RegisterGlobalEventHandler("PickedUpItemEvent", function(evt)
--
--    local text = "PickedUpItemEvent " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--        local inventory = evt:GetInventory()
--
--        text = text .. "\n" .. "entity " .. tostring(entity) .. " entityName " .. tostring(EntityService:GetBlueprintName( entity ))
--
--        text = text .. "\n" .. "inventory " .. tostring(entity) .. " inventory " .. tostring(EntityService:GetBlueprintName( inventory ))
--    end
--
--    LogService:Log(text)
--end)




--RegisterGlobalEventHandler("TurretEvent", function(evt)
--
--    local text = "TurretEvent " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local turretEntity = evt:GetTurretEntity()
--
--        local targetEntity = evt:GetTargetEntity()
--
--        local turretStatus = evt:GetTurretStatus()
--
--        text = text .. "\n" .. "turretEntityBlueprintName " .. tostring(EntityService:GetBlueprintName( turretEntity )) .. " turretEntity " .. tostring(turretEntity)
--
--        text = text .. "\n" .. "targetEntityBlueprintName " .. tostring(EntityService:GetBlueprintName( targetEntity )) .. " targetEntity " .. tostring(targetEntity)
--
--        if ( evt.GetTurrentName ) then
--
--            local turrentName = evt:GetTurrentName()
--
--            text = text .. "\n" .. "turrentName " .. tostring(turrentName)
--        end
--
--        text = text .. "\n" .. "turretStatus " .. tostring(turretStatus)
--
--        text = text .. "\n"
--        text = text .. "\n"
--    end
--
--    LogService:Log(text)
--end)





RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    local inventoryComponent = EntityService:GetSingletonComponent("InventorySystemDataComponent")

    if ( inventoryComponent ~= nil ) then

        --local unlockedContainer = inventoryComponent:GetField("unlocked"):ToContainer()

        --local item = nil

        --item = unlockedContainer:CreateItem()
        --item:SetValue("items/weapons/auto_shotgun_item")

        local team = EntityService:GetTeam( "player" )

        local researched = true

        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_shotgun_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_shotgun_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_shotgun_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_shotgun_extreme_item", researched, team )
        --
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_bouncing_blades_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_bouncing_blades_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_bouncing_blades_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_bouncing_blades_extreme_item", researched, team )
        --
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_burst_rifle_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_burst_rifle_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_burst_rifle_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_burst_rifle_extreme_item", researched, team )
        --
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_sniper_rifle_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_sniper_rifle_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_sniper_rifle_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_sniper_rifle_extreme_item", researched, team )
        --
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_blaster_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_blaster_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_blaster_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_blaster_extreme_item", researched, team )
        --
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_lava_gun_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_lava_gun_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_lava_gun_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_lava_gun_extreme_item", researched, team )
        --
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_railgun_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_railgun_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_railgun_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_railgun_extreme_item", researched, team )
        --
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_rocket_launcher_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_rocket_launcher_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_rocket_launcher_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_rocket_launcher_extreme_item", researched, team )
        --
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_atom_bomb_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_atom_bomb_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_atom_bomb_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_atom_bomb_extreme_item", researched, team )
        --
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_heavy_plasma_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_heavy_plasma_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_heavy_plasma_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_heavy_plasma_extreme_item", researched, team )

        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/artificial_spawner_waves/boss_arachnoid", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/artificial_spawner_waves/boss_baxmoth", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/artificial_spawner_waves/boss_gnerot", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/artificial_spawner_waves/boss_krocoon", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/artificial_spawner_waves/boss_magmoth", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/artificial_spawner_waves/boss_nerilian", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/artificial_spawner_waves/boss_nurglax", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/artificial_spawner_waves/boss_stregaros", researched, team )

        --item = unlockedContainer:CreateItem()
        --item:SetValue("items/weapons/auto_shotgun_advanced_item")
        --
        --item = unlockedContainer:CreateItem()
        --item:SetValue("items/weapons/auto_shotgun_superior_item")
        --
        --item = unlockedContainer:CreateItem()
        --item:SetValue("items/weapons/auto_shotgun_extreme_item")

        --local inventoryComponentRef = reflection_helper( inventoryComponent )

        --LogService:Log(tostring(inventoryComponentRef))
    end
end)