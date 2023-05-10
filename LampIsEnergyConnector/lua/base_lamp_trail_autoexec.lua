RegisterGlobalEventHandler("PlayerCreatedEvent", function(arg)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if	( player == nil ) then
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

    local blueprint = evt:GetBlueprint()

    local lowName = BuildingService:FindLowUpgrade( blueprint )

    if ( lowName ~= "base_lamp" ) then
        return
    end

    local selector = evt:GetEntity()
    
    if ( selector == nil ) then
        return
    end

    local selectorDB = EntityService:GetDatabase( selector )

    selectorDB:SetString("$base_lamp_trail_blueprint", blueprint)
end)
