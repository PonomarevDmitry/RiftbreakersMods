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

    if ( mapperName ~= "NeutralUnitHealingToolHeal" ) then
        return
    end

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive(entity) ) then
        return
    end

    HealthService:SetHealth( entity, HealthService:GetMaxHealth( entity ) )

    local heal_effectArray = {

        "effects/buildings_generic/building_repair_big",
        "effects/items/potion"
    }

    for effectName in Iter(heal_effectArray) do

        EffectService:SpawnEffect( entity, effectName )
    end
end)