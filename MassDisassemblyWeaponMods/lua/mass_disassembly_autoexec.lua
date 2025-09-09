if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

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

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local itemsList = {

        "items/mass_disassembly_rarity/standard",
        "items/mass_disassembly_rarity/advanced",
        "items/mass_disassembly_rarity/superior",
        "items/mass_disassembly_rarity/extreme"
    }

    local inventorySystemDataComponent = EntityService:GetSingletonComponent("InventorySystemDataComponent")
    if ( inventorySystemDataComponent ~= nil ) then

        local hashItemUnlocked = {}

        local inventorySystemDataComponentRef = reflection_helper( inventorySystemDataComponent )

        local unlockedArray = inventorySystemDataComponentRef.unlocked

        for i=1,unlockedArray.count do

            local unlockedItem = unlockedArray[i]

            if ( IndexOf( itemsList, unlockedItem ) ~= nil ) then

                hashItemUnlocked[unlockedItem] = true
            end
        end

        local team = EntityService:GetTeam( player )

        for itemName in Iter( itemsList ) do

            if (hashItemUnlocked[itemName] == nil) then

                QueueEvent( "NewAwardEvent", INVALID_ID, itemName, true, team )
            end
        end
    end
end

--RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
--
--    mass_disassembly_autoexec(evt)
--end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    mass_disassembly_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    mass_disassembly_autoexec(evt)
end)