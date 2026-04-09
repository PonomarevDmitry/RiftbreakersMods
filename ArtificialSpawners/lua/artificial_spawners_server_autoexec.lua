if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local artificial_spawners_autoexec = function(evt, eventName)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent ~= nil ) then

        BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_slots_picker")
        BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_slots_replacer")
        BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_slots_replacer_all_map")

        BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_activate")
        BuildingService:UnlockBuilding("buildings/tools/artificial_spawner_activate_all_map")
    end

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetGlobalPlayerEntity( playerId )
    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local inventoryComponent = EntityService:GetComponent(player, "InventoryComponent")
    if ( inventoryComponent == nil ) then
        return
    end

    local inventorySystemDataComponent = EntityService:GetSingletonComponent("InventorySystemDataComponent")
    if ( inventorySystemDataComponent == nil ) then
        return
    end

    local itemsList = {

        "items/artificial_spawner_waves/acid_standard",
        "items/artificial_spawner_waves/acid_advanced",
        "items/artificial_spawner_waves/acid_superior",
        "items/artificial_spawner_waves/acid_extreme",

        "items/artificial_spawner_waves/caverns_standard",
        "items/artificial_spawner_waves/caverns_advanced",
        "items/artificial_spawner_waves/caverns_superior",
        "items/artificial_spawner_waves/caverns_extreme",

        "items/artificial_spawner_waves/desert_standard",
        "items/artificial_spawner_waves/desert_advanced",
        "items/artificial_spawner_waves/desert_superior",
        "items/artificial_spawner_waves/desert_extreme",

        "items/artificial_spawner_waves/jungle_standard",
        "items/artificial_spawner_waves/jungle_advanced",
        "items/artificial_spawner_waves/jungle_superior",
        "items/artificial_spawner_waves/jungle_extreme",

        "items/artificial_spawner_waves/magma_standard",
        "items/artificial_spawner_waves/magma_advanced",
        "items/artificial_spawner_waves/magma_superior",
        "items/artificial_spawner_waves/magma_extreme",

        "items/artificial_spawner_waves/metallic_standard",
        "items/artificial_spawner_waves/metallic_advanced",
        "items/artificial_spawner_waves/metallic_superior",
        "items/artificial_spawner_waves/metallic_extreme",

        "items/artificial_spawner_waves/swamp_standard",
        "items/artificial_spawner_waves/swamp_advanced",
        "items/artificial_spawner_waves/swamp_superior",
        "items/artificial_spawner_waves/swamp_extreme",

        "items/artificial_spawner_waves/ice_standard",
        "items/artificial_spawner_waves/ice_advanced",
        "items/artificial_spawner_waves/ice_superior",
        "items/artificial_spawner_waves/ice_extreme",

        "items/artificial_spawner_waves/boss_arachnoid",
        "items/artificial_spawner_waves/boss_baxmoth",
        "items/artificial_spawner_waves/boss_gnerot",
        "items/artificial_spawner_waves/boss_krocoon",

        "items/artificial_spawner_waves/boss_magmoth",
        "items/artificial_spawner_waves/boss_mudroner",
        "items/artificial_spawner_waves/boss_nerilian",
        "items/artificial_spawner_waves/boss_nurglax",

        "items/artificial_spawner_waves/boss_stregaros",

        "items/artificial_spawner_waves/shegret",
        "items/artificial_spawner_waves/shegret_alpha",
        "items/artificial_spawner_waves/shegret_ultra",

        "items/artificial_spawner_waves/boss_dynamic",

        "items/artificial_spawner_waves/drillgor",
        "items/artificial_spawner_waves/drillgor_alpha",
        "items/artificial_spawner_waves/drillgor_ultra"
    }

    local hashItemUnlocked = {}
    local hashItemInInventory = {}

    for item in Iter( itemsList ) do
        hashItemUnlocked[item] = false
        hashItemInInventory[item] = false
    end

    local inventorySystemDataComponentRef = reflection_helper( inventorySystemDataComponent )

    local unlockedArray = inventorySystemDataComponentRef.unlocked

    for i=1,unlockedArray.count do

        local unlockedItem = unlockedArray[i]

        if ( hashItemUnlocked[unlockedItem] ~= nil ) then

            hashItemUnlocked[unlockedItem] = true
        end
    end

    local inventoryComponentRef = reflection_helper( inventoryComponent )

    if ( inventoryComponentRef.inventory ~= nil and inventoryComponentRef.inventory.items ~= nil and inventoryComponentRef.inventory.items.count > 0 ) then

        local items = inventoryComponentRef.inventory.items

        for i=1,items.count do

            local item = items[i]

            if ( item and item.id ~= nil ) then

                local blueprintName = EntityService:GetBlueprintName(item.id)

                if ( hashItemUnlocked[blueprintName] == true ) then

                    LogService:Log(eventName .. " blueprintName " .. tostring(blueprintName) .. " EXIST " .. tostring(item.id))

                    hashItemInInventory[blueprintName] = true
                end
            end
        end

        local items_by_blueprint = inventoryComponentRef.inventory.items_by_blueprint

        for i=1,items_by_blueprint.count do

            local keyCollection = items_by_blueprint[i]

            if ( keyCollection and keyCollection.key ~= nil and keyCollection.value and keyCollection.value.count > 0 ) then

                local blueprintName = keyCollection.key

                if ( hashItemUnlocked[blueprintName] == true ) then

                    LogService:Log(eventName .. " blueprintName " .. tostring(blueprintName) .. " EXIST ")

                    hashItemInInventory[blueprintName] = true
                end
            end
        end

        for item in Iter( itemsList ) do

            if (hashItemUnlocked[item] == true and hashItemInInventory[item] ~= true) then

                LogService:Log(eventName .. " item " .. tostring(item) .. " CREATING.")
    
                PlayerService:AddItemToInventory( playerId, item )
            end
        end
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    artificial_spawners_autoexec(evt, "PlayerCreatedEvent")
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    artificial_spawners_autoexec(evt, "PlayerInitializedEvent")
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    artificial_spawners_autoexec(evt, "PlayerControlledEntityChangeEvent")
end)