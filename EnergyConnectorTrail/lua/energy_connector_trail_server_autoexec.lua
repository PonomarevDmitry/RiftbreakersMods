if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local energy_connector_trail_autoexec = function(evt, eventName)

    if ( not is_server ) then
        return
    end

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetGlobalPlayerEntity( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local skillName = "items/skills/energy_connector_trail"

    local inventorySystemDataComponent = EntityService:GetSingletonComponent("InventorySystemDataComponent")
    if ( inventorySystemDataComponent ~= nil ) then

        local isItemUnlocked = false

        local inventorySystemDataComponentRef = reflection_helper( inventorySystemDataComponent )

        local unlockedArray = inventorySystemDataComponentRef.unlocked

        for i=1,unlockedArray.count do

            local unlockedItem = unlockedArray[i]

            if ( unlockedItem == skillName ) then

                isItemUnlocked = true
                break
            end
        end

        if (isItemUnlocked == false) then

            local team = EntityService:GetTeam( player )

            QueueEvent( "NewAwardEvent", INVALID_ID, skillName, true, team )
        end
    end

    local inventoryComponent = EntityService:GetComponent(player, "InventoryComponent")
    if ( inventoryComponent ~= nil ) then

        local inventoryComponentRef = reflection_helper( inventoryComponent )

        --LogService:Log(eventName .. " inventoryComponentRef " .. tostring(inventoryComponentRef))

        if ( inventoryComponentRef.inventory ~= nil and inventoryComponentRef.inventory.items ~= nil and inventoryComponentRef.inventory.items.count > 0 ) then

            local isItemExists = false

            local items = inventoryComponentRef.inventory.items

            for i=1,items.count do

                local item = items[i]

                if ( item and item.id ~= nil ) then

                    local blueprintName = EntityService:GetBlueprintName(item.id)

                    if ( blueprintName == skillName ) then

                        LogService:Log(eventName .. " blueprintName " .. tostring(blueprintName) .. " EXIST " .. tostring(item.id))

                        isItemExists = true
                        break
                    end
                end
            end

            local items_by_blueprint = inventoryComponentRef.inventory.items_by_blueprint

            for i=1,items_by_blueprint.count do

                local keyCollection = items_by_blueprint[i]

                if ( keyCollection and keyCollection.key ~= nil and keyCollection.value and keyCollection.value.count > 0 ) then

                    if ( keyCollection.key == skillName ) then

                        LogService:Log(eventName .. " keyCollection.key " .. tostring(keyCollection.key) .. " EXIST ")

                        isItemExists = true
                        break
                    end
                end
            end

            if (isItemExists == false) then

                LogService:Log(eventName .. " skillName " .. tostring(skillName) .. " CREATING.")
    
                PlayerService:AddItemToInventory( playerId, skillName )
            end
        end
    end
end



RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    energy_connector_trail_autoexec(evt, "PlayerCreatedEvent")
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    energy_connector_trail_autoexec(evt, "PlayerInitializedEvent")
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    energy_connector_trail_autoexec(evt, "PlayerControlledEntityChangeEvent")
end)