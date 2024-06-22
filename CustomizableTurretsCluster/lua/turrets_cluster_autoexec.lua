require("lua/utils/table_utils.lua")

local turrets_cluster_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local skillList = {

        "items/skills/turrets_cluster_1_item",
        "items/skills/turrets_cluster_2_item",
        "items/skills/turrets_cluster_3_item"
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

    for skillName in Iter( skillList ) do

        local itemCount = PlayerService:GetItemNumber( playerId, skillName )

        if ( itemCount == 0 ) then
            PlayerService:AddItemToInventory( playerId, skillName )
        end
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    turrets_cluster_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    turrets_cluster_autoexec(evt)
end)