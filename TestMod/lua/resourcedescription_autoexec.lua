require("lua/utils/reflection.lua")

ConsoleService:RegisterCommand( "test_log_resource", function( args )

    if not Assert( #args == 1, "Command test_log_resource requires one argument! [blueprintName]" ) then
        return 
    end

    local blueprintName = args[1]

    if not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) then

        LogService:Log("test_log_resource EntityBlueprint NOT EXISTS " .. blueprintName )
        return
    end

    local blueprint = ResourceManager:GetBlueprint( blueprintName )

    local componentNames = blueprint:GetComponentNames()

    local count = 0

    if (componentNames.count ~= nil) then
        count = componentNames.count
    else
        count = #componentNames
    end

    for i = 1, count do 
        
        local componentName = componentNames[i]

        LogService:Log("test_log_resource " .. blueprintName .. " " .. componentName )
    end
    
end)


ConsoleService:RegisterCommand( "test_log_resource_component", function( args )

    if not Assert( #args == 2, "Command test_log_resource_component requires two argument! [blueprintName],[componentName]" .. tostring(#args) ) then
        for i = 1, #args do 

            LogService:Log(" test_log_resource_component " .. args[i] )
        end
        return 
    end

    local blueprintName = args[1]
    local componentName = args[2]

    if not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) then

        LogService:Log("test_log_resource_component EntityBlueprint NOT EXISTS " .. blueprintName )
        return
    end

    local blueprint = ResourceManager:GetBlueprint( blueprintName )

    local component = blueprint:GetComponent(componentName)

    local componentRef = reflection_helper(component)

    LogService:Log("test_log_resource_component " .. blueprintName .. " componentName " .. componentName .. " " .. tostring(componentRef) )
    
end)