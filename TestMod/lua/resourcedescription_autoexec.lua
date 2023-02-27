require("lua/utils/reflection.lua")

ConsoleService:RegisterCommand( "test_log_resource", function( args )

    if not Assert( #args == 1 or #args == 2, "Command test_log_resource requires one or two arguments! [blueprintName],[componentName] " .. tostring(#args) ) then
        return 
    end

    local blueprintName = args[1]

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then

        LogService:Log("test_log_resource EntityBlueprint NOT EXISTS " .. blueprintName )
        return
    end

    local blueprint = ResourceManager:GetBlueprint( blueprintName )

    if ( #args == 1 ) then

        local componentNames = blueprint:GetComponentNames()

        local count = 0

        if (componentNames.count ~= nil) then
            count = componentNames.count
        else
            count = #componentNames
        end

        for i = 1, count do 
        
            local componentName = componentNames[i]

            LogService:Log("test_log_resource blueprint " .. blueprintName .. " " .. componentName )
        end
    else

        local componentName = args[2]

        local component = blueprint:GetComponent(componentName)

        local componentRef = reflection_helper(component)

        LogService:Log("test_log_resource blueprint " .. blueprintName .. " component " .. " " .. tostring(componentRef) )
    end
end)