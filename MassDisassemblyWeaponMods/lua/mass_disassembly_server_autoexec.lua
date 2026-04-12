require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

if ( not is_server ) then
    return
end



local mass_disassembly_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent ~= nil ) then

        BuildingService:UnlockBuilding("buildings/main/mass_disassembly")
        BuildingService:UnlockBuilding("buildings/main/mass_disassembly_by_rarity")
        BuildingService:UnlockBuilding("buildings/main/mass_disassembly_equal_and_lower")
        
        BuildingService:UnlockBuilding("buildings/tools/mass_disassembly_by_rarity_tool")
    end

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetGlobalPlayerEntity( playerId )
    if ( player == nil or player == INVALID_ID ) then
        return
    end


    local itemList = {
        "items/mass_disassembly_rarity/standard",
        "items/mass_disassembly_rarity/advanced",
        "items/mass_disassembly_rarity/superior",
        "items/mass_disassembly_rarity/extreme"  
    }

    local hashItemInInventory = {}

    for itemName in Iter( itemList ) do

        hashItemInInventory[itemName] = false
    end

    local inventoryComponent = EntityService:GetComponent(player, "InventoryComponent")
    if ( inventoryComponent ~= nil ) then

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
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    mass_disassembly_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    mass_disassembly_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    mass_disassembly_autoexec(evt)
end)