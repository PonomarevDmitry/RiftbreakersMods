if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

local PowerWellsToolsUtils = require("lua/utils/power_wells_tools_utils.lua")

RegisterGlobalEventHandler("OperateActionMapperRequest", function(evt)

    if ( not is_server ) then
        return
    end





    local mapperName = evt:GetMapperName()

    local stringNumber = string.find( mapperName, "PowerWellRespawnRequest" )

    if ( stringNumber == 1 ) then

        local globalPlayerEntity = evt:GetEntity()

        if ( not EntityService:IsAlive(globalPlayerEntity) ) then
            return
        end

        local splitArray = Split( mapperName, "|" )

        if ( #splitArray ~= 7 ) then
            return
        end
        
        local blueprintName = splitArray[2]

        if ( blueprintName == nil or blueprintName == "" ) then
            return
        end

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
            return
        end

        local positionXString = splitArray[3]
        local positionYString = splitArray[4]
        local positionZString = splitArray[5]
        local orientationYString = splitArray[6]
        local orientationWString = splitArray[7]
        
        local positionX = tonumber( positionXString )
        local positionY = tonumber( positionYString )
        local positionZ = tonumber( positionZString )

        local orientationY = tonumber( orientationYString )
        local orientationW = tonumber( orientationWString )

        if ( positionX == nil or positionY == nil or positionZ == nil or orientationY == nil or orientationW == nil ) then
            return
        end

        local position = {}

        position.x = positionX
        position.y = positionY
        position.z = positionZ

        local orientation = {}

        orientation.x = 0
        orientation.y = orientationY
        orientation.z = 0
        orientation.w = orientationW

        local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )
        if ( globalPlayerEntityDB == nil ) then
            return
        end

        local parameterName = "$PowerWellStore"

        local storeBlueprints = PowerWellsToolsUtils:GetStoredBlueprints(globalPlayerEntityDB, parameterName)

        if ( storeBlueprints == nil ) then
            return
        end

        storeBlueprints[blueprintName] = storeBlueprints[blueprintName] or 0

        local team = EntityService:GetTeam( "player" )

        local newPowerWell = EntityService:SpawnEntity(blueprintName, position, team )
        EntityService:SetOrientation( newPowerWell, orientation )

        local newPowerWellDB = EntityService:GetOrCreateDatabase( newPowerWell )
        if ( newPowerWellDB ~= nil ) then
            newPowerWellDB:SetInt("$PowerWellRespawned", 1)
        end

        if not ( mod_power_wells_respawn_tool_unlimited ~= nil and mod_power_wells_respawn_tool_unlimited == 1 ) then
                
            storeBlueprints[blueprintName] = storeBlueprints[blueprintName] - 1
        end

        if ( storeBlueprints[blueprintName] <= 0 ) then
            storeBlueprints[blueprintName] = nil
        end

        PowerWellsToolsUtils:SaveStoredBlueprints(globalPlayerEntity, globalPlayerEntityDB, parameterName, storeBlueprints)

        return
    end





    local stringNumber = string.find( mapperName, "PowerWellStoreRequest" )

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

        local parameterName = "$PowerWellStore"

        local storeBlueprints = PowerWellsToolsUtils:GetStoredBlueprints(globalPlayerEntityDB, parameterName)

        if ( storeBlueprints == nil ) then
            return
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local oldValue = storeBlueprints[blueprintName] or 0

        local entityDB = EntityService:GetDatabase( entity )
        if ( entityDB == nil ) then
            return
        end

        if ( entityDB:HasInt("$PowerWellStore_Destroy") ) then
            return
        end

        local changeValue = 1

        if ( entityDB:HasInt("$PowerWellRespawned") ) then

            if ( oldValue ~= 0 and mod_power_wells_respawn_tool_unlimited ~= nil and mod_power_wells_respawn_tool_unlimited == 1 ) then

                changeValue = 0
            end

        else
            
            if ( mod_power_wells_preserve_tool_x_10 ~= nil and mod_power_wells_preserve_tool_x_10 == 1 ) then
                
                changeValue = changeValue * 10
            end

            if ( mod_power_wells_preserve_tool_x_5 ~= nil and mod_power_wells_preserve_tool_x_5 == 1 ) then

                changeValue = changeValue * 5
            end
        end

        entityDB:SetInt("$PowerWellStore_Destroy", 1)
        entityDB:SetInt("working", 0)

        if ( EffectService:HasEffectByGroup( entity, "container") ) then

            EffectService:DestroyDelayedEffectsByGroup( entity, "container", 1.0 )
        end
        
        EntityService:RequestDestroyPattern( entity, "interact", false )

        EntityService:RemoveEntity(entity, 2.0)

        newValue = oldValue + changeValue

        storeBlueprints[blueprintName] = newValue

        PowerWellsToolsUtils:SaveStoredBlueprints(globalPlayerEntity, globalPlayerEntityDB, parameterName, storeBlueprints)

        return
    end



    local stringNumber = string.find( mapperName, "PowerWellActivateRequest" )
    if ( stringNumber == 1 ) then

        local entity = evt:GetEntity()

        if ( not EntityService:IsAlive(entity) ) then
            return
        end

        local splitArray = Split( mapperName, "|" )
        if ( #splitArray ~= 2 ) then
            return
        end

        local playerIdStr = splitArray[2]

        local playerId = tonumber(playerIdStr)
        if ( playerId == nil ) then
            return
        end

        local player = PlayerService:GetPlayerControlledEnt( playerId )
        if ( player == nil or player == INVALID_ID ) then
            return
        end

        local entityDB = EntityService:GetDatabase( entity )
        if ( entityDB == nil ) then
            return
        end

        if ( entityDB:HasInt("$PowerWellStore_Destroy") ) then
            return
        end

        entityDB:SetInt("$PowerWellStore_Destroy", 1)
        entityDB:SetInt("working", 0)

        ItemService:InteractWithEntity( entity, player )

        EffectService:AttachEffects( entity, "treasure" )

        return
    end
end)