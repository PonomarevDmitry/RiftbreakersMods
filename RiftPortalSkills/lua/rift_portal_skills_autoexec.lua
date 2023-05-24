require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil ) then
        return
    end

    local skillList = {

        "items/skills/temporary_rift_portal",
        "items/skills/personal_rift_portal",
        "items/skills/rift_jump_to_hq",
        "items/skills/rift_jump_to_nearest_portal"
    }

    for skillName in Iter( skillList ) do

        local itemCount = ItemService:GetItemCount( player, skillName )

        if ( itemCount == 0 ) then
            PlayerService:AddItemToInventory( playerId, skillName )
        end
    end
end)