require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

--test_log_blueprint items/loot/saplings/crystal_metallic_red_item

--test_log_blueprint items/loot/saplings/crystal_metallic_red_item InventoryItemComponent
--test_log_blueprint items/loot/saplings/crystal_metallic_red_item GatherResourceComponent
--test_log_blueprint items/loot/saplings/crystal_metallic_red_item DatabaseComponent

--test_log_blueprint buildings/energy/carbonium_powerplant

--test_log_blueprint buildings/energy/carbonium_powerplant AnimationGraphDesc
--test_log_blueprint buildings/energy/carbonium_powerplant BuildingComponent
--test_log_blueprint buildings/energy/carbonium_powerplant BuildingDesc
--test_log_blueprint buildings/energy/carbonium_powerplant BuildingStatusComponent
--test_log_blueprint buildings/energy/carbonium_powerplant DatabaseComponent
--test_log_blueprint buildings/energy/carbonium_powerplant DestroyDesc
--test_log_blueprint buildings/energy/carbonium_powerplant DestructionLevelComponent
--test_log_blueprint buildings/energy/carbonium_powerplant EffectDesc
--test_log_blueprint buildings/energy/carbonium_powerplant FogOfWarRevealerComponent
--test_log_blueprint buildings/energy/carbonium_powerplant GridCullerComponent
--test_log_blueprint buildings/energy/carbonium_powerplant HealthBarComponent
--test_log_blueprint buildings/energy/carbonium_powerplant HealthComponent
--test_log_blueprint buildings/energy/carbonium_powerplant HealthDesc
--test_log_blueprint buildings/energy/carbonium_powerplant LootComponent
--test_log_blueprint buildings/energy/carbonium_powerplant LuaComponent
--test_log_blueprint buildings/energy/carbonium_powerplant MeshDesc
--test_log_blueprint buildings/energy/carbonium_powerplant MinimapItemComponent
--test_log_blueprint buildings/energy/carbonium_powerplant NodeCullerComponent
--test_log_blueprint buildings/energy/carbonium_powerplant PhysicsDesc
--test_log_blueprint buildings/energy/carbonium_powerplant ResourceConverterComponent
--test_log_blueprint buildings/energy/carbonium_powerplant ResourceConverterDesc
--test_log_blueprint buildings/energy/carbonium_powerplant ResourceStorageComponent
--test_log_blueprint buildings/energy/carbonium_powerplant SkeletonDesc
--test_log_blueprint buildings/energy/carbonium_powerplant TypeComponent
--test_log_blueprint buildings/energy/carbonium_powerplant UniformComponent


--test_log_blueprint resources/resource_sludge -all

--test_log_blueprint spawners/loot_container_spawner -all

--test_log_blueprint spawners/loot_container_spawner_advanced -all

--test_log_blueprint buildings/main/headquarters -all

--test_log_blueprint buildings/decorations/floor_acid_1x1 -all




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