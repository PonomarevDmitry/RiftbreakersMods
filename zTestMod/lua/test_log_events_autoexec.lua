--RegisterGlobalEventHandler("ResourceMissingEvent", function(evt)

--    local text = "ResourceMissingEvent " .. tostring(evt)

--    if (evt ~= nil) then

--        local entity = evt:GetEntity()
--        local entityName = EntityService:GetBlueprintName( entity )

--        local negative = evt:GetNegative()

--        local resource = evt:GetResource()

--        local family = evt:GetFamily()

--        text = text .. "\n" .. "negative " .. tostring(negative)

--        text = text .. "\n" .. "resource " .. tostring(resource)

--        text = text .. "\n" .. "family " .. tostring(family)

--        text = text .. "\n" .. "entityName " .. tostring(entityName)

--        text = text .. "\n" .. "entity " .. tostring(entity)
--    end

--    LogService:Log(text)
--end)




--RegisterGlobalEventHandler("PickedUpItemEvent", function(evt)

--    local text = "PickedUpItemEvent " .. tostring(evt)

--    if (evt ~= nil) then

--        local entity = evt:GetEntity()
--        local inventory = evt:GetInventory()

--        text = text .. "\n" .. "entity " .. tostring(entity) .. " entityName " .. tostring(EntityService:GetBlueprintName( entity ))

--        text = text .. "\n" .. "inventory " .. tostring(entity) .. " inventory " .. tostring(EntityService:GetBlueprintName( inventory ))
--    end

--    LogService:Log(text)
--end)




--RegisterGlobalEventHandler("TurretEvent", function(evt)

--    local text = "TurretEvent " .. tostring(evt)

--    if (evt ~= nil) then

--        local turretEntity = evt:GetTurretEntity()

--        local targetEntity = evt:GetTargetEntity()

--        local turretStatus = evt:GetTurretStatus()

--        text = text .. "\n" .. "turretEntityBlueprintName " .. tostring(EntityService:GetBlueprintName( turretEntity )) .. " turretEntity " .. tostring(turretEntity)

--        text = text .. "\n" .. "targetEntityBlueprintName " .. tostring(EntityService:GetBlueprintName( targetEntity )) .. " targetEntity " .. tostring(targetEntity)

--        if ( evt.GetTurrentName ) then

--            local turrentName = evt:GetTurrentName()

--            text = text .. "\n" .. "turrentName " .. tostring(turrentName)
--        end

--        text = text .. "\n" .. "turretStatus " .. tostring(turretStatus)

--        text = text .. "\n"
--        text = text .. "\n"
--    end

--    LogService:Log(text)
--end)



local logHandler = function(evt)

    local text = "\n" .. tostring(evt) .. " is_server " .. tostring(is_server) .. " is_client " .. tostring(is_client) 

    if (evt ~= nil) then

        if (evt.GetPlayerId) then

            local playerId = evt:GetPlayerId()

            text = text .. "\n" .. "playerId " .. tostring(playerId)
        end

        if (evt.GetTeamId) then

            local teamId = evt:GetTeamId()

            if ( teamId ~= nil ) then
                text = text .. "\n" .. "teamId " .. tostring(teamId)
            end
        end

        if (evt.GetOptions) then

            local options = evt:GetOptions()

            text = text .. "\n" .. "options " .. tostring(options)
        end

        if (evt.GetContinous) then

            local continous = evt:GetContinous()

            text = text .. "\n" .. "continous " .. tostring(continous)
        end

        if (evt.GetActivationId) then

            local activationId = evt:GetActivationId()

            text = text .. "\n" .. "activationId " .. tostring(activationId)
        end

        if (evt.GetSlot) then

            local slot = evt:GetSlot()

            text = text .. "\n" .. "slot " .. tostring(slot)
        end

        if (evt.GetEventType) then

            local eventType = evt:GetEventType()

            text = text .. "\n" .. "eventType " .. tostring(eventType)
        end

        if (evt.GetBlueprint) then

            local blueprint = evt:GetBlueprint()

            text = text .. "\n" .. "blueprint " .. tostring(blueprint)
        end

        if (evt.GetResearch) then

            local research = evt:GetResearch()

            text = text .. "\n" .. "research " .. tostring(research)
        end

        if (evt.GetResearched) then

            local researched = evt:GetResearched()

            text = text .. "\n" .. "researched " .. tostring(researched)
        end

        if (evt.GetName) then

            local name = evt:GetName()

            text = text .. "\n" .. "name " .. tostring(name)
        end

        if (evt.GetEmptyCosts) then

            local emptyCosts = evt:GetEmptyCosts()

            text = text .. "\n" .. "emptyCosts " .. tostring(emptyCosts)
        end

        if (evt.GetEntity) then

            local entity = evt:GetEntity()

            if ( entity ~= INVALID_ID ) then

                text = text .. "\n" .. "entityBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " entity " .. tostring(entity)

            else

                text = text .. "\n" .. "entity INVALID_ID"
            end
        end

        if (evt.GetItemEnt) then

            local entity = evt:GetItemEnt()

            if ( entity ~= INVALID_ID ) then

                text = text .. "\n" .. "itemEntBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " itemEnt " .. tostring(entity)

            else

                text = text .. "\n" .. "itemEnt INVALID_ID"
            end
        end

        if (evt.GetOwner) then

            local entity = evt:GetOwner()

            if ( entity ~= INVALID_ID ) then

                text = text .. "\n" .. "ownerBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " owner " .. tostring(entity)

            else

                text = text .. "\n" .. "owner INVALID_ID"
            end
        end

        if (evt.GetItem) then

            local entity = evt:GetItem()

            if ( entity ~= INVALID_ID ) then

                text = text .. "\n" .. "itemBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " item " .. tostring(entity)

                local itemName = ItemService:GetItemName( entity )

                text = text .. " itemName " .. tostring(itemName)

            else

                text = text .. "\n" .. "item INVALID_ID"
            end
        end

        if (evt.GetInventoryEnt) then

            local entity = evt:GetInventoryEnt()

            if ( entity ~= INVALID_ID ) then

                text = text .. "\n" .. "InventoryEntBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " InventoryEnt " .. tostring(entity)

            else

                text = text .. "\n" .. "InventoryEnt INVALID_ID"
            end
        end

        if (evt.GetSink) then

            local entity = evt:GetSink()

            if ( entity ~= INVALID_ID ) then

                text = text .. "\n" .. "sinkBlueprintName " .. tostring(EntityService:GetBlueprintName( entity )) .. " sink " .. tostring(entity)

            else

                text = text .. "\n" .. "sink INVALID_ID"
            end
        end

        text = text .. "\n"
        text = text .. "\n"
    end

    LogService:Log(text)
end




    
--RegisterGlobalEventHandler("BuildingStartEvent", logHandler)
--RegisterGlobalEventHandler("StartBuildingEvent", logHandler)
--
--RegisterGlobalEventHandler("BuildingSellEvent", logHandler)
--RegisterGlobalEventHandler("BuildingOverrideEvent", logHandler)
--
--RegisterGlobalEventHandler("ActivateBuildingEvent", logHandler)
--RegisterGlobalEventHandler("DeactivateBuildingEvent", logHandler)
--
--RegisterGlobalEventHandler("ActivateEntityRequest", logHandler)
--RegisterGlobalEventHandler("DeactivateEntityRequest", logHandler)
--
--RegisterGlobalEventHandler("SelectEntityRequest", logHandler)
--RegisterGlobalEventHandler("DeselectEntityRequest", logHandler)
--
--RegisterGlobalEventHandler("BuildingPoweredEvent", logHandler)
--RegisterGlobalEventHandler("BuildingPowerOffEvent", logHandler)
--
--RegisterGlobalEventHandler("BuildingResourceGrantedEvent", logHandler)
--RegisterGlobalEventHandler("BuildingResourceMissingEvent", logHandler)
--
--RegisterGlobalEventHandler("BuildingModifiedEvent", logHandler)
--
--RegisterGlobalEventHandler("BuildingBuildEvent", logHandler)
--RegisterGlobalEventHandler("BuildingBuildEndEvent", logHandler)






--RegisterGlobalEventHandler("DestroyRequest", logHandler)

--RegisterGlobalEventHandler("ItemEquippedEvent", logHandler)
--RegisterGlobalEventHandler("ItemEquipedEvent", logHandler)

--RegisterGlobalEventHandler("EquipItemRequest", logHandler)
--RegisterGlobalEventHandler("EquipItemEvent", logHandler)

--RegisterGlobalEventHandler("ItemUnequippedEvent", logHandler)
--RegisterGlobalEventHandler("UnequipedItemEvent", logHandler)
--RegisterGlobalEventHandler("UnequipItemRequest", logHandler)

--RegisterGlobalEventHandler("ItemCraftedEvent", logHandler)

--RegisterGlobalEventHandler("AddItemToInventoryRequest", logHandler)
--RegisterGlobalEventHandler("RemoveItemFromInventoryRequest", logHandler)
--RegisterGlobalEventHandler("CreateItemInInventoryRequest", logHandler)

--RegisterGlobalEventHandler("InventoryItemCreatedEvent", logHandler)
--RegisterGlobalEventHandler("NetReplicateEntityRequest", logHandler)

--RegisterGlobalEventHandler("ActivateItemRequest", logHandler)


--RegisterGlobalEventHandler("AddToResearchRequest", logHandler)
--RegisterGlobalEventHandler("AddedToResearchEvent", logHandler)

--RegisterGlobalEventHandler("RemovedFromResearchRequest", logHandler)
--RegisterGlobalEventHandler("RemovedFromResearchEvent", logHandler)

--RegisterGlobalEventHandler("NewResearchAvailableEvent", logHandler)

--RegisterGlobalEventHandler("NewAwardEvent", logHandler)

--RegisterGlobalEventHandler("ResearchUnlockedEvent", logHandler)












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
        
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_bouncing_blades_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_bouncing_blades_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_bouncing_blades_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_bouncing_blades_extreme_item", researched, team )
        
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_burst_rifle_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_burst_rifle_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_burst_rifle_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_burst_rifle_extreme_item", researched, team )
        
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_sniper_rifle_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_sniper_rifle_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_sniper_rifle_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_sniper_rifle_extreme_item", researched, team )
        
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_blaster_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_blaster_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_blaster_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_blaster_extreme_item", researched, team )
        
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_lava_gun_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_lava_gun_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_lava_gun_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_lava_gun_extreme_item", researched, team )
        
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_railgun_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_railgun_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_railgun_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_railgun_extreme_item", researched, team )
        
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_rocket_launcher_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_rocket_launcher_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_rocket_launcher_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_rocket_launcher_extreme_item", researched, team )
        
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_atom_bomb_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_atom_bomb_advanced_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_atom_bomb_superior_item", researched, team )
        --QueueEvent( "NewAwardEvent", INVALID_ID, "items/weapons/auto_atom_bomb_extreme_item", researched, team )
        
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
        
        --item = unlockedContainer:CreateItem()
        --item:SetValue("items/weapons/auto_shotgun_superior_item")
        
        --item = unlockedContainer:CreateItem()
        --item:SetValue("items/weapons/auto_shotgun_extreme_item")

        --local inventoryComponentRef = reflection_helper( inventoryComponent )

        --LogService:Log(tostring(inventoryComponentRef))
    end
end)