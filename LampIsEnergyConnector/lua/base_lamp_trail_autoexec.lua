RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil ) then
        return
    end

    local skillName = "items/skills/base_lamp_trail"

    local itemCount = ItemService:GetItemCount( player, skillName )

    --LogService:Log("skillName " .. skillName .. " itemCount " .. tostring(itemCount))

    if ( itemCount > 0 ) then
        return
    end

    PlayerService:AddItemToInventory( playerId, skillName )
end)

RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    local blueprintName = evt:GetBlueprint()

    local lowName = BuildingService:FindLowUpgrade( blueprintName )

    if ( lowName ~= "base_lamp" ) then
        return
    end

    local parameterName = "$base_lamp_trail_blueprint"

    local selector = evt:GetEntity()
    if ( selector ) then

        local selectorDB = EntityService:GetDatabase( selector )
        if ( selectorDB ) then
            selectorDB:SetString(parameterName, blueprintName)
        end
    end

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase ) then
        campaignDatabase:SetString( parameterName, blueprintName )
    end
end)
