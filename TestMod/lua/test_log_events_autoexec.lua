


--RegisterGlobalEventHandler("EquipItemRequest", function(evt)
--
--    local text = "EquipItemRequest " .. tostring(evt)
--
--    if (evt ~= nil) then
--
--        local entity = evt:GetEntity()
--        local entityName = EntityService:GetBlueprintName( entity )
--
--        local itemEnt = evt:GetItemEnt()
--        local itemEntName = EntityService:GetBlueprintName( itemEnt )
--
--        local slot = evt:GetSlot()
--
--        text = text .. "\n" .. "slot " .. tostring(slot)
--
--        text = text .. "\n" .. "entityName " .. tostring(entityName)
--
--        text = text .. "\n" .. "entity " .. tostring(entity)
--
--        text = text .. "\n" .. "itemEntName " .. tostring(itemEntName)
--
--        text = text .. "\n" .. "itemEnt " .. tostring(itemEnt)
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
--        local entityName = EntityService:GetBlueprintName( entity )
--
--        local itemEnt = evt:GetItemEnt()
--        local itemEntName = EntityService:GetBlueprintName( itemEnt )
--
--        local slot = evt:GetSlot()
--
--        text = text .. "\n" .. "slot " .. tostring(slot)
--
--        text = text .. "\n" .. "entityName " .. tostring(entityName)
--
--        text = text .. "\n" .. "entity " .. tostring(entity)
--
--        text = text .. "\n" .. "itemEntName " .. tostring(itemEntName)
--
--        text = text .. "\n" .. "itemEnt " .. tostring(itemEnt)
--    end
--
--    LogService:Log(text)
--end)





RegisterGlobalEventHandler("AddItemToInventoryRequest", function(evt)

    local text = "AddItemToInventoryRequest " .. tostring(evt)

    if (evt ~= nil) then

        local inventoryEnt = evt:GetInventoryEnt()
        local inventoryEntName = EntityService:GetBlueprintName( inventoryEnt )

        local item = evt:GetItem()
        local itemName = EntityService:GetBlueprintName( item )

        text = text .. "\n" .. "inventoryEntName " .. tostring(inventoryEntName)

        text = text .. "\n" .. "inventoryEnt " .. tostring(inventoryEnt)

        text = text .. "\n" .. "itemName " .. tostring(itemName)

        text = text .. "\n" .. "item " .. tostring(item)
    end

    LogService:Log(text)
end)

RegisterGlobalEventHandler("RemoveItemFromInventoryRequest", function(evt)

    local text = "RemoveItemFromInventoryRequest " .. tostring(evt)

    if (evt ~= nil) then

        local inventoryEnt = evt:GetInventoryEnt()
        local inventoryEntName = EntityService:GetBlueprintName( inventoryEnt )

        local item = evt:GetItem()
        local itemName = EntityService:GetBlueprintName( item )

        text = text .. "\n" .. "inventoryEntName " .. tostring(inventoryEntName)

        text = text .. "\n" .. "inventoryEnt " .. tostring(inventoryEnt)

        text = text .. "\n" .. "itemName " .. tostring(itemName)

        text = text .. "\n" .. "item " .. tostring(item)
    end

    LogService:Log(text)
end)





RegisterGlobalEventHandler("AddToResearchRequest", function(evt)

    local text = "AddToResearchRequest " .. tostring(evt)

    if (evt ~= nil) then

        local entity = evt:GetEntity()
        local entityName = EntityService:GetBlueprintName( entity )

        local research = evt:GetResearch()

        --local playerId = evt:GetPlayerId()

        text = text .. "\n" .. "research " .. tostring(research)

        --text = text .. "\n" .. "playerId " .. tostring(playerId)

        text = text .. "\n" .. "entityName " .. tostring(entityName)

        text = text .. "\n" .. "entity " .. tostring(entity)

    end

    LogService:Log(text)
end)

RegisterGlobalEventHandler("AddToResearchEvent", function(evt)

    local text = "AddToResearchEvent " .. tostring(evt)

    if (evt ~= nil) then

        local entity = evt:GetEntity()
        local entityName = EntityService:GetBlueprintName( entity )

        local name = evt:GetName()

        --local teamId = evt:GetTeamId()

        text = text .. "\n" .. "name " .. tostring(name)

        --text = text .. "\n" .. "teamId.idx " .. tostring(teamId.idx)

        text = text .. "\n" .. "entityName " .. tostring(entityName)

        text = text .. "\n" .. "entity " .. tostring(entity)
    end

    LogService:Log(text)
end)



RegisterGlobalEventHandler("RemovedFromResearchRequest", function(evt)

    local text = "RemovedFromResearchRequest " .. tostring(evt)

    if (evt ~= nil) then

        local entity = evt:GetEntity()
        local entityName = EntityService:GetBlueprintName( entity )

        local research = evt:GetResearch()

        --local playerId = evt:GetPlayerId()

        text = text .. "\n" .. "research " .. tostring(research)

        --text = text .. "\n" .. "playerId " .. tostring(playerId)

        text = text .. "\n" .. "entityName " .. tostring(entityName)

        text = text .. "\n" .. "entity " .. tostring(entity)
    end

    LogService:Log(text)
end)

RegisterGlobalEventHandler("RemovedFromResearchEvent", function(evt)

    local text = "RemovedFromResearchEvent " .. tostring(evt)

    if (evt ~= nil) then

        local entity = evt:GetEntity()
        local entityName = EntityService:GetBlueprintName( entity )

        local name = evt:GetName()

        --local teamId = evt:GetTeamId()

        text = text .. "\n" .. "name " .. tostring(name)

        --text = text .. "\n" .. "teamId.idx " .. tostring(teamId.idx)

        text = text .. "\n" .. "entityName " .. tostring(entityName)

        text = text .. "\n" .. "entity " .. tostring(entity)
    end

    LogService:Log(text)
end)





RegisterGlobalEventHandler("ResearchUnlockedEvent", function(evt)

    local text = "ResearchUnlockedEvent " .. tostring(evt)

    if (evt ~= nil) then

        local entity = evt:GetEntity()
        local entityName = EntityService:GetBlueprintName( entity )

        local name = evt:GetName()

        --local teamId = evt:GetTeamId()

        local emptyCosts = evt:GetEmptyCosts()

        text = text .. "\n" .. "name " .. tostring(name)

        --text = text .. "\n" .. "teamId.idx " .. tostring(teamId.idx)

        text = text .. "\n" .. "emptyCosts " .. tostring(emptyCosts)

        text = text .. "\n" .. "entityName " .. tostring(entityName)

        text = text .. "\n" .. "entity " .. tostring(entity)

        --local awards = evt:GetAwards()
        --if ( awards ~= nil ) then
        --
        --    for i=1,awards.count do
        --    
        --        local award = awards[i]
        --
        --        text = text .. "\n" .. "award index " .. tostring(i) .. " blueprint " .. tostring(award.blueprint) .. " is_visible " .. tostring(award.is_visible)
        --    end
        --end
    end

    LogService:Log(text)
end)