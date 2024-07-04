require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

ConsoleService:RegisterCommand( "test_log_researchsystemdata", function( args )

    local researchSystemDataComponent = EntityService:GetSingletonComponent("ResearchSystemDataComponent")

    if ( researchSystemDataComponent == nil ) then

        LogService:Log("ResearchSystemDataComponent is nil")
        return
    end

    local researchSystemDataComponentRef = reflection_helper( researchSystemDataComponent )

    LogService:Log(tostring(researchSystemDataComponentRef))
end)