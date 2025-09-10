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

    local stringNumber = string.find( mapperName, "LightsSwitchToolsSwitchPlayer" )
    if ( stringNumber == 1 ) then

        local splitArray = Split( mapperName, "_" )

        if ( #splitArray ~= 2 ) then
            return
        end

        local playerIdStr = splitArray[2]

        local playerId = tonumber(playerIdStr)
        if ( playerId == nil ) then
            return
        end

        local player = PlayerService:GetPlayerControlledEnt(playerId)
        if ( playerId == nil or playerId == INVALID_ID ) then
            return
        end

        if ( not EntityService:IsAlive(player) ) then
            return
        end

        if ( EffectService:HasEffectByGroup(player, "sunset_night_sunrise") ) then

            EffectService:DestroyEffectsByGroup(player, "sunset_night_sunrise")
        else

            EffectService:AttachEffects(player, "sunset_night_sunrise")
        end

        return
    end





    if ( mapperName == "LightsSwitchToolsEntityTurnOn" or mapperName == "LightsSwitchToolsEntityTurnOff" ) then

        local entity = evt:GetEntity()
        if ( entity == nil or entity == INVALID_ID ) then
            return
        end

        if ( not EntityService:IsAlive(entity) ) then
            return false
        end

        local setPower = false

        if ( mapperName == "LightsSwitchToolsEntityTurnOn" ) then

            setPower = true

        elseif ( mapperName == "LightsSwitchToolsEntityTurnOff" ) then

            setPower = false
        end



        local blueprintName = EntityService:GetBlueprintName( entity )

        local lowName = BuildingService:FindLowUpgrade( blueprintName )

        if ( lowName == "base_lamp" or lowName == "crystal_lamp" ) then

            if( setPower ) then

                if ( not EffectService:HasEffectByGroup(entity, "working") ) then

                    BuildingService:BlinkBuilding(entity)

                    EffectService:AttachEffects(entity, "working")
                end
            else

                if ( EffectService:HasEffectByGroup(entity, "working") ) then

                    BuildingService:BlinkBuilding(entity)

                    EffectService:DestroyEffectsByGroup(entity, "working")
                end
            end

        else

            if( setPower ) then

                if ( not EffectService:HasEffectByGroup(entity, "lamp") ) then

                    BuildingService:BlinkBuilding(entity)

                    EffectService:AttachEffects(entity, "lamp")
                end
            else

                if ( EffectService:HasEffectByGroup(entity, "lamp") ) then

                    BuildingService:BlinkBuilding(entity)

                    EffectService:DestroyEffectsByGroup(entity, "lamp")
                end
            end
        end

        return
    end
end)