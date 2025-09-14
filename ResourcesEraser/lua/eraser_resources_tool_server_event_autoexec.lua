if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

local RemoveGameplayResourceComponents = function(entity)

    local cellIndexes = FindService:GetEntityCellIndexes(entity)

    for cellId in Iter( cellIndexes ) do

        if ( not EntityService:HasComponent( cellId, "GameplayResourceLayerComponent" ) ) then
            goto labelContinue
        end

        local gameplayResourceLayerComponentRef = reflection_helper( EntityService:GetComponent( cellId, "GameplayResourceLayerComponent" ) )

        if ( gameplayResourceLayerComponentRef.ent == nil ) then
            goto labelContinue
        end

        local linkedResourceId = gameplayResourceLayerComponentRef.ent

        if ( linkedResourceId.id ) then

            linkedResourceId = linkedResourceId.id
        end

        if ( linkedResourceId == nil ) then
            goto labelContinue
        end

        if ( linkedResourceId ~= entity ) then
            goto labelContinue
        end

        EntityService:RemoveComponent( cellId, "GameplayResourceLayerComponent" )

        if ( not EntityService:HasComponent( cellId, "GridFlagLayerComponent" ) ) then
            goto labelContinue
        end

        local gridFlagLayerComponentRef = reflection_helper( EntityService:GetComponent( cellId, "GridFlagLayerComponent" ) )

        if ( gridFlagLayerComponentRef.mask ~= 0 ) then

            gridFlagLayerComponentRef.mask = 0
        end

        ::labelContinue::
    end
end

RegisterGlobalEventHandler("OperateActionMapperRequest", function(evt)

    if ( not is_server ) then
        return
    end

    local mapperName = evt:GetMapperName()

    if ( mapperName ~= "ResourcesEraserToolRequest" ) then
        return
    end

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive(entity) ) then
        return
    end

    if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

        local childrenList = EntityService:GetChildren( entity, false )

        for childResource in Iter( childrenList ) do

            RemoveGameplayResourceComponents(childResource)

            EntityService:RemoveEntity(childResource)
        end
    end

    RemoveGameplayResourceComponents(entity)

    QueueEvent( "DissolveEntityRequest", entity, 0.5, 0 )
end)