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

        -- EA
        "resources/ammo_mech_medium_caliber",
        "resources/ammo_mech_acid_cells",
        "resources/ammo_mech_crystal_dna",
        "resources/ammo_mech_cryo_cells",
        "resources/ammo_mech_magma_cells",
        "resources/ammo_mech_plasma_cells",
        "resources/ammo_mech_radio_cells",
        "resources/ammo_mech_gravity_matrix",
        "resources/ammo_mech_morphium_canister",
        "resources/ammo_mech_rift_charge",

        "resources/ammo_tower_plasma_cells",
        "resources/ammo_tower_advanced_explosive",
        "resources/ammo_tower_acid_cells",
        "resources/ammo_tower_cryo_cells",
        "resources/ammo_tower_magma_cells",
        "resources/ammo_tower_radio_cells",
        "resources/ammo_tower_gravity_matrix",

        -- Tower Arsenal
        "resources/ammo_mech_cosmic_cells",
        "resources/ammo_mech_plasmoid_cells",

        "resources/ammo_cosmic_explosive",
        "resources/ammo_cosmic_machinegun_cells",

        "resources/ammo_tower_acidic_cells",
        "resources/ammo_tower_cosmic_cells",
        "resources/ammo_tower_cryogenic_cells",
        "resources/ammo_tower_flame_cells",
        "resources/ammo_tower_plasmoid_cells",
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

            if ( name ~= nil and name ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", name ) ) then

                if (hashItemUnlocked[name] == nil) then

                    LogService:Log(eventName .. " NewAwardEvent name " .. tostring(name) .. ".")

                    QueueEvent( "NewAwardEvent", INVALID_ID, name, true, team )
                end
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