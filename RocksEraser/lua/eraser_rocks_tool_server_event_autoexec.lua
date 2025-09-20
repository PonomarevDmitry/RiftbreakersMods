if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

RegisterGlobalEventHandler("OperateActionMapperRequest", function(evt)

    if ( not is_server ) then
        return
    end

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive(entity) ) then
        return
    end

    local mapperName = evt:GetMapperName()

    if ( mapperName == "RocksEraserRequest" ) then

        if ( EntityService:GetComponent( entity, "PhysicsComponent") ~= nil ) then

            EntityService:DisableCollisions( entity )

            BuildingService:DisablePhysics( entity )

            EntityService:RequestDestroyPattern( entity, "default" )
        end

        EntityService:DissolveEntity( entity, 0.5 )

        return
    end

    if ( mapperName == "RocksAndFloraEraserRequest" ) then

        -- Ignore Poogret plant
        local blueprintName = EntityService:GetBlueprintName(entity)
        if ( string.find(blueprintName, "props/special/interactive/poogret_plant" ) ~= nil ) then
            return
        end
    
        -- Ignore Poogret plant
        local enablerComponent = EntityService:GetComponent( entity, "VegetationLifecycleEnablerComponent")
        if ( enablerComponent ~= nil ) then

            local enablerComponentRef = reflection_helper(enablerComponent)

            if ( enablerComponentRef.chain_destination and enablerComponentRef.chain_destination.hash ) then

                local poogretPlantSmall = CalcHash("props/special/interactive/poogret_plant_small_01")
                local poogretPlantMedium = CalcHash("props/special/interactive/poogret_plant_medium_01")
                local poogretPlantBig = CalcHash("props/special/interactive/poogret_plant_big_01")

                local nextPlantHash = enablerComponentRef.chain_destination.hash

                if ( nextPlantHash == poogretPlantSmall or nextPlantHash == poogretPlantMedium or nextPlantHash == poogretPlantBig ) then

                    return
                end
            end
        end

        EntityService:RemoveComponent( entity, "VegetationLifecycleEnablerComponent" )

        EntityService:RequestDestroyPattern( entity, "default" )

        QueueEvent( "DissolveEntityRequest", entity, 0.5, 0 )

        return
    end
end)