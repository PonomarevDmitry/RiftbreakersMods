local ep = require( "lua/entity_patcher.lua" )

local entity_patcher_autoexec = function( evt )
    if ExecuteOnceGuard( "Entity Patcher" ) then
        return
    end

    ep:EnsurePatch()
end

RegisterGlobalEventHandler( "PlayerCreatedEvent", function( evt )
    -- ConsoleService:Write( "PlayerCreatedEvent" )
    entity_patcher_autoexec( evt )
end )

RegisterGlobalEventHandler( "PlayerInitializedEvent", function( evt )
    -- ConsoleService:Write( "PlayerInitializedEvent" )
    entity_patcher_autoexec( evt )
end )

RegisterGlobalEventHandler( "PlayerControlledEntityChangeEvent", function( evt )
    -- ConsoleService:Write( "PlayerControlledEntityChangeEvent" )
    entity_patcher_autoexec( evt )
end )
