require( "lua/utils/divergent.lua" )

ConsoleService:RegisterCommand( "ep_player_equipment", function( args )
    ConsoleService:Write( "Entity Patch Player Equipment" )

    local ep = require( "lua/entity_patcher.lua" )
    local players = PlayerService:GetAllPlayers()

    if #players == 0 then
        ConsoleService:Write( "Unable to find Players" )
        return
    end

    local mechs = {}
    for i = 1, #players do
        local player = players[i]
        if player == INVALID_ID then
            goto continue
        end

        local mech = PlayerService:GetGlobalPlayerEntity( player )
        if mech == INVALID_ID then
            goto continue
        end

        mechs[mech] = PlayerService:GetPlayerName( player )

        ::continue::
    end

    ep:AddToMechCheck( mechs )

    for _, player_name in pairs( mechs ) do
        ConsoleService:Write( (">> %s's equipment patched "):format( player_name ) )
    end

end )
