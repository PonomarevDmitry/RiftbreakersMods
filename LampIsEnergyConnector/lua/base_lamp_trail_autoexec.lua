RegisterGlobalEventHandler("PlayerCreatedEvent", function(arg)

    local player = PlayerService:GetPlayerControlledEnt( 0 )

    if	( player == nil ) then
        return
    end

    local skillName = "items/skills/base_lamp_trail"

    if ( ItemService:GetItemCount( player, skillName ) > 0 ) then
        return
    end

    PlayerService:AddItemToInventory( 0, skillName )
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
