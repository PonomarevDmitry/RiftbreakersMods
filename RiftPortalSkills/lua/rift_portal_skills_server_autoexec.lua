if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local rift_portal_skills_autoexec = function(evt, eventName)

    if ( not is_server ) then
        return
    end

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetGlobalPlayerEntity( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local skillList = {

        "items/skills/rift_portal_temporary",
        "items/skills/rift_portal_personal",
        "items/skills/rift_jump_to_hq",
        "items/skills/rift_jump_to_nearest_portal"
    }

    local inventorySystemDataComponent = EntityService:GetSingletonComponent("InventorySystemDataComponent")
    if ( inventorySystemDataComponent ~= nil ) then

        local hashItemUnlocked = {}

        local inventorySystemDataComponentRef = reflection_helper( inventorySystemDataComponent )

        local unlockedArray = inventorySystemDataComponentRef.unlocked

        for i=1,unlockedArray.count do

            local unlockedItem = unlockedArray[i]

            if ( IndexOf( skillList, unlockedItem ) ~= nil ) then

                hashItemUnlocked[unlockedItem] = true
            end
        end

        local team = EntityService:GetTeam( player )

        for skillName in Iter( skillList ) do

            if (hashItemUnlocked[skillName] == nil) then

                QueueEvent( "NewAwardEvent", INVALID_ID, skillName, true, team )
            end
        end
    end

    local inventoryComponent = EntityService:GetComponent(player, "InventoryComponent")
    if ( inventoryComponent ~= nil ) then

        local inventoryComponentRef = reflection_helper( inventoryComponent )

        --LogService:Log(eventName .. " inventoryComponentRef " .. tostring(inventoryComponentRef))

        if ( inventoryComponentRef.inventory ~= nil and inventoryComponentRef.inventory.items ~= nil and inventoryComponentRef.inventory.items.count > 0 ) then

            local hashItemInInventory = {}

            local items = inventoryComponentRef.inventory.items

            for i=1,items.count do

                local item = items[i]

                if ( item and item.id ~= nil ) then

                    local blueprintName = EntityService:GetBlueprintName(item.id)

                    if ( IndexOf( skillList, blueprintName ) ~= nil ) then

                        LogService:Log(eventName .. " blueprintName " .. tostring(blueprintName) .. " EXIST " .. tostring(item.id))

                        hashItemInInventory[blueprintName] = true
                    end
                end
            end

            for skillName in Iter( skillList ) do

                if (hashItemInInventory[skillName] == nil) then

                    LogService:Log(eventName .. " skillName " .. tostring(skillName) .. " CREATING.")
    
                    PlayerService:AddItemToInventory( playerId, skillName )
                end
            end
        end
    end
end



RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    rift_portal_skills_autoexec(evt, "PlayerCreatedEvent")
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    rift_portal_skills_autoexec(evt, "PlayerInitializedEvent")
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    rift_portal_skills_autoexec(evt, "PlayerControlledEntityChangeEvent")
end)