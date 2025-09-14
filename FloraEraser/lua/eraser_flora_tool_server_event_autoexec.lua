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

    local mapperName = evt:GetMapperName()

    if ( mapperName ~= "FloraEraserToolRequest" ) then
        return
    end

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive(entity) ) then
        return
    end

    EntityService:RemoveComponent( entity, "VegetationLifecycleEnablerComponent" )

    EntityService:RequestDestroyPattern( entity, "default" )

    QueueEvent( "DissolveEntityRequest", entity, 2.0, 0 )

end)