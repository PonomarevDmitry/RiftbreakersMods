require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

ConsoleService:RegisterCommand( "test_log_blueprint", function( args )

    if not Assert( #args == 1 or #args == 2, "Command test_log_blueprint requires one or two arguments! [blueprintName] [componentName] " .. tostring(#args) ) then
        return 
    end

    local blueprintName = args[1]

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then

        LogService:Log("test_log_blueprint EntityBlueprint NOT EXISTS " .. blueprintName )
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

        local tableNames = {}

        for i = 1, count do

            Insert( tableNames, componentNames[i] )
        end

        table.sort(tableNames)

        for i = 1, #tableNames do

            LogService:Log("test_log_blueprint " .. blueprintName .. " " .. tableNames[i] )
        end
    else

        local componentName = args[2]

        if ( componentName == "-all" ) then

            local componentNames = blueprint:GetComponentNames()

            local count = 0

            if (componentNames.count ~= nil) then
                count = componentNames.count
            else
                count = #componentNames
            end

            local tableNames = {}

            for i = 1, count do

                Insert( tableNames, componentNames[i] )
            end

            table.sort(tableNames)

            for i = 1, #tableNames do

                LogService:Log("test_log_blueprint " .. blueprintName .. " " .. tableNames[i] )
            end

            for i = 1, #tableNames do

                local component = blueprint:GetComponent(tableNames[i])

                local componentRef = reflection_helper(component)

                LogService:Log("test_log_blueprint blueprint " .. blueprintName .. " component " .. tostring(componentRef) )
            end
        else

            local component = blueprint:GetComponent(componentName)

            local componentRef = reflection_helper(component)

            LogService:Log("test_log_blueprint blueprint " .. blueprintName .. " component " .. tostring(componentRef) )

        end
    end
end)