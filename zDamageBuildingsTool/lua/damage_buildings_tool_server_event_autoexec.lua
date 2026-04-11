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

    if ( mapperName ~= "DamageBuildingsToolRequest" ) then
        return
    end

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive(entity) ) then
        return
    end

    local damageValue = HealthService:GetHealth( entity ) / 4

    QueueEvent( "DamageRequest", entity, damageValue, "physical", 1, 0 )


    local database = EntityService:GetOrCreateDatabase( entity )
    if ( database and database:HasInt("number_of_activations")) then

        local currentNumberOfActivations =  database:GetInt("number_of_activations")

        --local blueprintDatabase = EntityService:GetBlueprintDatabase( entity )

        --local maxNumberOfActivations = blueprintDatabase:GetInt("number_of_activations")
        
        currentNumberOfActivations = math.ceil(currentNumberOfActivations / 4)

        database:SetInt("number_of_activations", math.max(1, currentNumberOfActivations))
    end

end)