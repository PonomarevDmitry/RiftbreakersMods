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

        EntityService:RemoveComponent( entity, "VegetationLifecycleEnablerComponent" )

        EntityService:RequestDestroyPattern( entity, "default" )

        QueueEvent( "DissolveEntityRequest", entity, 0.5, 0 )

        return
    end
end)