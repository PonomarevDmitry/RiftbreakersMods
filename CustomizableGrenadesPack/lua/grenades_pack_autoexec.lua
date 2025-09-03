require("lua/utils/table_utils.lua")

local grenades_pack_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local skillList = {

        "items/skills/grenades_pack_1_item",
        "items/skills/grenades_pack_2_item",
        "items/skills/grenades_pack_3_item"
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

--RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
--
--    grenades_pack_autoexec(evt)
--end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    grenades_pack_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    grenades_pack_autoexec(evt)
end)