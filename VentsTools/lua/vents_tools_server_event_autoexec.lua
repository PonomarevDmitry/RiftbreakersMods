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

local VentsToolsUtils = require("lua/utils/vents_tools_utils.lua")

RegisterGlobalEventHandler("OperateActionMapperRequest", function(evt)

    if ( not is_server ) then
        return
    end





    local mapperName = evt:GetMapperName()

    local stringNumber = string.find( mapperName, "VentRespawnRequest" )

    if ( stringNumber == 1 ) then

        local globalPlayerEntity = evt:GetEntity()

        if ( not EntityService:IsAlive(globalPlayerEntity) ) then
            return
        end

        local splitArray = Split( mapperName, "|" )

        if ( #splitArray ~= 5 ) then
            return
        end
        
        local resourceName = splitArray[2]

        if ( resourceName == nil or resourceName == "" ) then
            return
        end

        if ( not ResourceManager:ResourceExists( "GameplayResourceDef", resourceName ) ) then
            return
        end

        local positionXString = splitArray[3]
        local positionYString = splitArray[4]
        local positionZString = splitArray[5]
        
        local positionX = tonumber( positionXString )
        local positionY = tonumber( positionYString )
        local positionZ = tonumber( positionZString )

        if ( positionX == nil or positionY == nil or positionZ == nil ) then
            return
        end

        local position = {}

        position.x = positionX
        position.y = positionY
        position.z = positionZ

        local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )
        if ( globalPlayerEntityDB == nil ) then
            return
        end

        local parameterName = "$VentStore"

        local storeResourceVents = VentsToolsUtils:GetStoredBlueprints(globalPlayerEntityDB, parameterName)

        if ( storeResourceVents == nil ) then
            return
        end

        storeResourceVents[resourceName] = storeResourceVents[resourceName] or 0



        local entityEmptySpace = ResourceService:FindEmptySpace(50, 500)

        EntityService:CreateOrSetLifetime( entityEmptySpace, 30.0, "normal" )

        EntityService:SetPosition(entityEmptySpace, position.x, position.y, position.z)

        ResourceService:SpawnResourcesInfinite( entityEmptySpace, "resources/vents_tools/volume_template_resource", resourceName )



        local team = EntityService:GetTeam( "player" )
        local effectEntity = EntityService:SpawnEntity("effects/enemies_lesigian/lightning_explosion", position, team)
        EntityService:CreateOrSetLifetime( effectEntity, 1.0, "normal" )



        if not ( mod_vents_respawn_tool_unlimited ~= nil and mod_vents_respawn_tool_unlimited == 1 ) then
                
            storeResourceVents[resourceName] = storeResourceVents[resourceName] - 1
        end

        if ( storeResourceVents[resourceName] <= 0 ) then
            storeResourceVents[resourceName] = nil
        end

        VentsToolsUtils:SaveStoredBlueprints(globalPlayerEntity, globalPlayerEntityDB, parameterName, storeResourceVents)

        return
    end





    local stringNumber = string.find( mapperName, "VentStoreRequest" )

    if ( stringNumber == 1 ) then

        local splitArray = Split( mapperName, "|" )

        if ( #splitArray ~= 2 ) then
            return
        end

        local playerIdStr = splitArray[2]

        local playerId = tonumber(playerIdStr)
        if ( playerId == nil ) then
            return
        end

        local entity = evt:GetEntity()

        if ( not EntityService:IsAlive(entity) ) then
            return
        end

        local globalPlayerEntity = PlayerService:GetGlobalPlayerEntity( playerId )
        if ( globalPlayerEntity == nil or globalPlayerEntity == INVALID_ID ) then
            return
        end

        local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )
        if ( globalPlayerEntityDB == nil ) then
            return
        end

        local parameterName = "$VentStore"

        local storeResourceVents = VentsToolsUtils:GetStoredBlueprints(globalPlayerEntityDB, parameterName)

        if ( storeResourceVents == nil ) then
            return
        end


        local resourceVolumeComponent = EntityService:GetComponent( entity, "ResourceVolumeComponent" )
        if ( resourceVolumeComponent == nil ) then
            return
        end

        local resourceName = ""

        local resourceVolumeComponentRef = reflection_helper( resourceVolumeComponent )
        if ( resourceVolumeComponentRef.type ~= nil and resourceVolumeComponentRef.type.resource ~= nil and resourceVolumeComponentRef.type.resource.id ~= nil ) then
            resourceName = resourceVolumeComponentRef.type.resource.id or ""
        end

        if ( resourceName == "" or resourceName == nil ) then
            return
        end



        local oldValue = storeResourceVents[resourceName] or 0

        local entityDB = EntityService:GetOrCreateDatabase( entity )
        if ( entityDB == nil ) then
            return
        end

        if ( entityDB:HasInt("$VentStore_Destroy") ) then
            return
        end

        local changeValue = 1

        if ( entityDB:HasInt("$VentRespawned") ) then

            if ( oldValue ~= 0 and mod_vents_respawn_tool_unlimited ~= nil and mod_vents_respawn_tool_unlimited == 1 ) then

                changeValue = 0
            end

        else
            
            if ( mod_vents_preserve_tool_x_10 ~= nil and mod_vents_preserve_tool_x_10 == 1 ) then
                
                changeValue = changeValue * 10
            end

            if ( mod_vents_preserve_tool_x_5 ~= nil and mod_vents_preserve_tool_x_5 == 1 ) then

                changeValue = changeValue * 5
            end
        end

        entityDB:SetInt("$VentStore_Destroy", 1)



        local position = EntityService:GetWorldTransform( entity ).position

        local childrenList = EntityService:GetChildren( entity, false )

        for childResource in Iter( childrenList ) do

            local resourceComponent = EntityService:GetComponent( childResource, "ResourceComponent" )
            if ( resourceComponent ~= nil ) then

                local resourceComponentRef = reflection_helper( resourceComponent )

                if ( resourceComponentRef.type ~= nil and resourceComponentRef.type.resource ~= nil and resourceComponentRef.type.resource.id ~= nil ) then

                    local resourceId = resourceComponentRef.type.resource.id or ""

                    if ( resourceId == resourceName ) then
                        
                        position = EntityService:GetWorldTransform( childResource ).position
                    end
                end
            end

            RemoveGameplayResourceComponents(childResource)

            EntityService:RemoveEntity(childResource)
        end

        RemoveGameplayResourceComponents(entity)



        local team = EntityService:GetTeam( "player" )
        local effectEntity = EntityService:SpawnEntity("effects/enemies_lesigian/lightning_explosion", position, team)
        EntityService:CreateOrSetLifetime( effectEntity, 1.0, "normal" )



        QueueEvent( "DissolveEntityRequest", entity, 0.2, 0 )



        newValue = oldValue + changeValue

        storeResourceVents[resourceName] = newValue

        VentsToolsUtils:SaveStoredBlueprints(globalPlayerEntity, globalPlayerEntityDB, parameterName, storeResourceVents)

        return
    end
end)