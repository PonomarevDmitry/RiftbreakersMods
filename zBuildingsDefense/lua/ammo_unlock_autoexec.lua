if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local ammo_unlock_autoexec = function(evt, eventName)

    if ( not is_server ) then
        return
    end

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetGlobalPlayerEntity( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    local list = {

        "resources/ammo_tower_low_caliber",
        "resources/ammo_tower_liquid",
        "resources/ammo_tower_explosive",
        "resources/ammo_tower_high_caliber",

        "resources/ammo_mech_liquid",
        "resources/ammo_mech_energy_cell",
        "resources/ammo_mech_explosive",
        "resources/ammo_mech_high_caliber",
        "resources/ammo_mech_low_caliber",
    }

    local inventorySystemDataComponent = EntityService:GetSingletonComponent("InventorySystemDataComponent")
    if ( inventorySystemDataComponent ~= nil ) then

        local hashItemUnlocked = {}

        local inventorySystemDataComponentRef = reflection_helper( inventorySystemDataComponent )

        local unlockedArray = inventorySystemDataComponentRef.unlocked

        for i=1,unlockedArray.count do

            local unlockedItem = unlockedArray[i]

            if ( IndexOf( list, unlockedItem ) ~= nil ) then

                hashItemUnlocked[unlockedItem] = true
            end
        end

        local team = EntityService:GetTeam( player )

        for name in Iter( list ) do

            if (hashItemUnlocked[name] == nil) then

                LogService:Log(eventName .. " NewAwardEvent name " .. tostring(name) .. ".")

                QueueEvent( "NewAwardEvent", INVALID_ID, name, true, team )
            end
        end
    end
end



RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    ammo_unlock_autoexec(evt, "PlayerCreatedEvent")
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    ammo_unlock_autoexec(evt, "PlayerInitializedEvent")
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    ammo_unlock_autoexec(evt, "PlayerControlledEntityChangeEvent")
end)