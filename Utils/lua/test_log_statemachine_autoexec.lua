require("lua/utils/reflection.lua")

ConsoleService:RegisterCommand( "test_log_statemachine", function( args )

    if not Assert( #args == 1, "Command test_log_statemachine requires one [stateMachineName] " .. tostring(#args) ) then
        return 
    end

    local name = args[1]

    if ( not ResourceManager:ResourceExists( "StateMachineDef", name ) ) then
        LogService:Log("test_log_statemachine StateMachineDef NOT EXISTS " .. name )
        return
    end

    local stateMachineDef = ResourceManager:GetResource("StateMachineDef", name)
    if ( resourceDef == nil ) then
        LogService:Log("test_log_statemachine StateMachineDef NOT EXISTS " .. name )
        return
    end

    local stateMachineDefRef = reflection_helper( stateMachineDef )

    LogService:Log(tostring(stateMachineDefRef))
end)