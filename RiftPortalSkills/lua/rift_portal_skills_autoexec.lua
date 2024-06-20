require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

local rift_portal_skills_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

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

        for skillName in Iter( skillList ) do

            if (hashItemUnlocked[skillName] == nil) then

                local team = EntityService:GetTeam( player )

                QueueEvent( "NewAwardEvent", INVALID_ID, skillName, true, team )
            end
        end
    end

    local inventoryComponent = EntityService:GetComponent(player, "InventoryComponent")
    if ( inventoryComponent ~= nil ) then

        for skillName in Iter( skillList ) do

            local itemCount = ItemService:GetItemCount( player, skillName )

            if ( itemCount == 0 ) then
                PlayerService:AddItemToInventory( playerId, skillName )
            end
        end
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    rift_portal_skills_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    rift_portal_skills_autoexec(evt)
end)