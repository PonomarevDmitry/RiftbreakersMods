require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

if ( not is_server ) then
    return
end

mod_autoadding_player_inventory_list = mod_autoadding_player_inventory_list or {}

local autoadding_player_inventory_server_autoexec = function(evt, eventName)

    if ( not is_server ) then
        return
    end

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetGlobalPlayerEntity( playerId )
    if ( player == nil or player == INVALID_ID ) then
        return
    end

    if ( #mod_autoadding_player_inventory_list == 0 ) then
        return
    end

    local itemList = {}
    local hashItemUnlocked = {}
    local hashItemInInventory = {}

    for itemName in Iter( mod_autoadding_player_inventory_list ) do

        if ( ResourceManager:ResourceExists( "EntityBlueprint", itemName ) ) then

            Insert(itemList, itemName)

            hashItemUnlocked[itemName] = false
            hashItemInInventory[itemName] = false
        end
    end

    if ( #itemList == 0 ) then
        return
    end

    local inventorySystemDataComponent = EntityService:GetSingletonComponent("InventorySystemDataComponent")
    if ( inventorySystemDataComponent ~= nil ) then

        local inventorySystemDataComponentRef = reflection_helper( inventorySystemDataComponent )

        local unlockedArray = inventorySystemDataComponentRef.unlocked

        for i=1,unlockedArray.count do

            local unlockedItem = unlockedArray[i]

            if ( hashItemUnlocked[unlockedItem] ~= nil ) then

                hashItemUnlocked[unlockedItem] = true
            end
        end

        local team = EntityService:GetTeam( player )

        for itemName in Iter( itemList ) do

            if (hashItemUnlocked[itemName] == false) then

                QueueEvent( "NewAwardEvent", INVALID_ID, itemName, true, team )
            end
        end
    end

    local inventoryComponent = EntityService:GetComponent(player, "InventoryComponent")
    if ( inventoryComponent == nil ) then
        return
    end

    local inventoryComponentRef = reflection_helper( inventoryComponent )

    --LogService:Log(eventName .. " inventoryComponentRef " .. tostring(inventoryComponentRef))

    if ( inventoryComponentRef.inventory ~= nil and inventoryComponentRef.inventory.items ~= nil and inventoryComponentRef.inventory.items.count > 0 ) then

        local items = inventoryComponentRef.inventory.items

        for i=1,items.count do

            local item = items[i]

            if ( item and item.id ~= nil ) then

                local blueprintName = EntityService:GetBlueprintName(item.id)

                if ( hashItemInInventory[blueprintName] ~= nil ) then

                    --LogService:Log(eventName .. " blueprintName " .. tostring(blueprintName) .. " EXIST " .. tostring(item.id))

                    hashItemInInventory[blueprintName] = true
                end
            end
        end
    end

    if ( inventoryComponentRef.inventory ~= nil and inventoryComponentRef.inventory.items_by_blueprint ~= nil and inventoryComponentRef.inventory.items_by_blueprint.count > 0 ) then

        local items_by_blueprint = inventoryComponentRef.inventory.items_by_blueprint

        for i=1,items_by_blueprint.count do

            local keyCollection = items_by_blueprint[i]

            if ( keyCollection and keyCollection.key ~= nil and keyCollection.value and keyCollection.value.count > 0 ) then

                local blueprintName = keyCollection.key

                if ( hashItemInInventory[blueprintName] ~= nil ) then

                    --LogService:Log(eventName .. " items_by_blueprint.key " .. tostring(blueprintName) .. " EXIST ")

                    hashItemInInventory[blueprintName] = true
                end
            end
        end
    end

    for itemName in Iter( itemList ) do

        if (hashItemInInventory[itemName] == false) then

            --LogService:Log(eventName .. " itemName " .. tostring(itemName) .. " CREATING.")
    
            PlayerService:AddItemToInventory( playerId, itemName )
        end
    end
end



RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    autoadding_player_inventory_server_autoexec(evt, "PlayerCreatedEvent")
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    autoadding_player_inventory_server_autoexec(evt, "PlayerInitializedEvent")
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    autoadding_player_inventory_server_autoexec(evt, "PlayerControlledEntityChangeEvent")
end)