local activate_all_bioanomalies_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local skillName = "items/skills/activate_all_bioanomalies_item"

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

    local itemCount = PlayerService:GetItemNumber( playerId, skillName )

    if ( itemCount == 0 ) then
        PlayerService:AddItemToInventory( playerId, skillName )
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    activate_all_bioanomalies_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    activate_all_bioanomalies_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    activate_all_bioanomalies_autoexec(evt)
end)