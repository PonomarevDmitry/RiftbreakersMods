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

    for skillName in Iter( skillList ) do

        local itemCount = ItemService:GetItemCount( player, skillName )

        if ( itemCount == 0 ) then
            PlayerService:AddItemToInventory( playerId, skillName )
        end
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", rift_portal_skills_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", rift_portal_skills_autoexec)