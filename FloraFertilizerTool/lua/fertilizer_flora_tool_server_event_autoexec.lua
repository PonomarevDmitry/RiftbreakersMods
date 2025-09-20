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

    if ( mapperName ~= "FloraFertilizerToolRequest" ) then
        return
    end

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive(entity) ) then
        return
    end

    if ( EntityService:HasComponent( entity, "VegetationLifecycleEnablerComponent" ) ) then

        EntityService:RemoveComponent(entity, "VegetationLifecycleComponent")

        EntityService:CreateComponent(entity, "VegetationLifecycleComponent") -- create new component that will trigger re-growth on next update

        EffectService:SpawnEffect( entity, "effects/fertilizer_flora_tool/fertilize_big" )
    end

end)