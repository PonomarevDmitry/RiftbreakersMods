ConsoleService:RegisterCommand( "activate_mission_flow", function( args )
    if not Assert( #args >= 1, "Command requires at least one argument!" ) then return end

    if #args > 1 then
        MissionService:ActivateMissionFlow( args[ 1 ], args[ 2 ] )
    else
        MissionService:ActivateMissionFlow( "", args[ 1 ] )
    end
end)