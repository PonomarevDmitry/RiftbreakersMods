if ( not is_client ) then
    return
end

RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    if ( not is_client ) then
        return
    end

    local blueprintName = evt:GetBlueprint() or ""
    if ( blueprintName == "" or blueprintName == nil ) then
        return
    end

    local lowName = BuildingService:FindLowUpgrade( blueprintName )

    if ( lowName ~= "wall_small_floor" ) then
        return
    end

    local parameterName = "$selected_wall_small_floor_blueprint"

    local selector = evt:GetEntity()
    if ( selector and selector ~= INVALID_ID ) then

        local selectorDB = EntityService:GetOrCreateDatabase( selector )
        if ( selectorDB ) then
            selectorDB:SetString(parameterName, blueprintName)
        end

        local playerId = PlayerService:GetPlayerForEntity( selector )

        if ( playerId ~= nil and playerId ~= -1 ) then

            local globalPlayerEntity = PlayerService:GetGlobalPlayerEntity( playerId )

            if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

                if ( is_server and is_client ) then

                    local globalPlayerEntityDB = EntityService:GetOrCreateDatabase( globalPlayerEntity )

                    if ( globalPlayerEntityDB ) then
                        globalPlayerEntityDB:SetString( parameterName, blueprintName )
                    end
                else

                    local mapperName = "SetGlobalPlayerEntityDatabaseString|" .. parameterName .. "|" .. blueprintName

                    QueueEvent("OperateActionMapperRequest", globalPlayerEntity, mapperName, false )
                end
            end
        end
    end
end)