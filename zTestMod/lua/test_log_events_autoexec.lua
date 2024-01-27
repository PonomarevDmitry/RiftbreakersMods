


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





--RegisterGlobalEventHandler("AddItemToInventoryRequest", function(evt)
--
--    local text = "AddItemToInventoryRequest " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local inventoryEnt = evt:GetInventoryEnt()
--        local inventoryEntName = EntityService:GetBlueprintName( inventoryEnt )
--
--        local item = evt:GetItem()
--        local itemName = EntityService:GetBlueprintName( item )
--
--        text = text .. "\n" .. "inventoryEntName " .. tostring(inventoryEntName)
--
--        text = text .. "\n" .. "inventoryEnt " .. tostring(inventoryEnt)
--
--        text = text .. "\n" .. "itemName " .. tostring(itemName)
--
--        text = text .. "\n" .. "item " .. tostring(item)
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
--        local inventoryEnt = evt:GetInventoryEnt()
--        local inventoryEntName = EntityService:GetBlueprintName( inventoryEnt )
--
--        local item = evt:GetItem()
--        local itemName = EntityService:GetBlueprintName( item )
--
--        text = text .. "\n" .. "inventoryEntName " .. tostring(inventoryEntName)
--
--        text = text .. "\n" .. "inventoryEnt " .. tostring(inventoryEnt)
--
--        text = text .. "\n" .. "itemName " .. tostring(itemName)
--
--        text = text .. "\n" .. "item " .. tostring(item)
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
--        local entityName = EntityService:GetBlueprintName( entity )
--
--        local research = evt:GetResearch()
--
--        --local playerId = evt:GetPlayerId()
--
--        text = text .. "\n" .. "research " .. tostring(research)
--
--        --text = text .. "\n" .. "playerId " .. tostring(playerId)
--
--        text = text .. "\n" .. "entityName " .. tostring(entityName)
--
--        text = text .. "\n" .. "entity " .. tostring(entity)
--
--    end
--
--    LogService:Log(text)
--end)

--RegisterGlobalEventHandler("AddToResearchEvent", function(evt)
--
--    local text = "AddToResearchEvent " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--        local entityName = EntityService:GetBlueprintName( entity )
--
--        local name = evt:GetName()
--
--        --local teamId = evt:GetTeamId()
--
--        text = text .. "\n" .. "name " .. tostring(name)
--
--        --text = text .. "\n" .. "teamId.idx " .. tostring(teamId.idx)
--
--        text = text .. "\n" .. "entityName " .. tostring(entityName)
--
--        text = text .. "\n" .. "entity " .. tostring(entity)
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
--        local entityName = EntityService:GetBlueprintName( entity )
--
--        local research = evt:GetResearch()
--
--        --local playerId = evt:GetPlayerId()
--
--        text = text .. "\n" .. "research " .. tostring(research)
--
--        --text = text .. "\n" .. "playerId " .. tostring(playerId)
--
--        text = text .. "\n" .. "entityName " .. tostring(entityName)
--
--        text = text .. "\n" .. "entity " .. tostring(entity)
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
--        local entityName = EntityService:GetBlueprintName( entity )
--
--        local name = evt:GetName()
--
--        --local teamId = evt:GetTeamId()
--
--        text = text .. "\n" .. "name " .. tostring(name)
--
--        --text = text .. "\n" .. "teamId.idx " .. tostring(teamId.idx)
--
--        text = text .. "\n" .. "entityName " .. tostring(entityName)
--
--        text = text .. "\n" .. "entity " .. tostring(entity)
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
--        local entityName = EntityService:GetBlueprintName( entity )
--
--        local name = evt:GetName()
--
--        --local teamId = evt:GetTeamId()
--
--        local emptyCosts = evt:GetEmptyCosts()
--
--        text = text .. "\n" .. "name " .. tostring(name)
--
--        --text = text .. "\n" .. "teamId.idx " .. tostring(teamId.idx)
--
--        text = text .. "\n" .. "emptyCosts " .. tostring(emptyCosts)
--
--        text = text .. "\n" .. "entityName " .. tostring(entityName)
--
--        text = text .. "\n" .. "entity " .. tostring(entity)
--
--        --local awards = evt:GetAwards()
--        --if ( awards ~= nil ) then
--        --
--        --    for i=1,awards.count do
--        --    
--        --        local award = awards[i]
--        --
--        --        text = text .. "\n" .. "award index " .. tostring(i) .. " blueprint " .. tostring(award.blueprint) .. " is_visible " .. tostring(award.is_visible)
--        --    end
--        --end
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





RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

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