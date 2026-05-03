if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

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

        local resourceName = EntityService:GetresourceName( entity )

        local oldValue = storeResourceVents[resourceName] or 0

        local entityDB = EntityService:GetDatabase( entity )
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
        entityDB:SetInt("working", 0)

        if ( EffectService:HasEffectByGroup( entity, "container") ) then

            EffectService:DestroyDelayedEffectsByGroup( entity, "container", 1.0 )
        end
        
        EntityService:RequestDestroyPattern( entity, "interact", false )

        EntityService:RemoveEntity(entity, 2.0)

        newValue = oldValue + changeValue

        storeResourceVents[resourceName] = newValue

        VentsToolsUtils:SaveStoredBlueprints(globalPlayerEntity, globalPlayerEntityDB, parameterName, storeResourceVents)

        return
    end
end)