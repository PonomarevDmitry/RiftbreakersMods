require("lua/utils/reflection.lua")

ConsoleService:RegisterCommand( "test_log_resource", function( args )

    if not Assert( #args == 1, "Command test_log_resource requires one [resource] " .. tostring(#args) ) then
        return 
    end

    local resouceName = args[1]

    if ( not ResourceManager:ResourceExists( "GameplayResourceDef", resouceName ) ) then
        LogService:Log("test_log_resource GameplayResourceDef NOT EXISTS " .. resouceName )
        return
    end

    local resourceDef = ResourceManager:GetResource("GameplayResourceDef", resouceName)
    if ( resourceDef == nil ) then
        LogService:Log("test_log_resource GameplayResourceDef NOT EXISTS " .. resouceName )
        return
    end

    local resourceDefRef = reflection_helper( resourceDef )

    LogService:Log(tostring(resourceDefRef))
end)