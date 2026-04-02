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

    if ( mapperName == "PowerWellReStoreRequest" ) then

        local entity = evt:GetEntity()

        if ( not EntityService:IsAlive(entity) ) then
            return
        end

        

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

        local player = PlayerService:GetGlobalPlayerEntity( playerId )
        if ( player == nil or player == INVALID_ID ) then
            return
        end

        local globalPlayerEntityDB = EntityService:GetDatabase( player )
        if ( globalPlayerEntityDB == nil ) then
            return
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local parameterName = "$PowerWellStore|" .. blueprintName

        local oldValue = globalPlayerEntityDB:GetIntOrDefault(parameterName, 0)

        local entityDB = EntityService:GetDatabase( entity )
        if ( entityDB == nil ) then
            return
        end

        if ( entityDB:HasInt("$PowerWellStore_Destroy") ) then
            return
        end

        entityDB:SetInt("$PowerWellStore_Destroy", 1)
        entityDB:SetInt("working", 0)

        if ( EffectService:HasEffectByGroup( entity, "container") ) then

            EffectService:DestroyDelayedEffectsByGroup( entity, "container", 1.0 )
        end
        
        EntityService:RequestDestroyPattern( entity, "interact", false )

        EntityService:RemoveEntity(entity, 2.0)

        newValue = oldValue + 1

        globalPlayerEntityDB:SetInt( parameterName, newValue )

        return
    end
end)