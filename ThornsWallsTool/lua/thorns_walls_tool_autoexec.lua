RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    
    BuildingService:UnlockBuilding("buildings/defense/thorns_walls_tool")
end)

RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    local blueprint = evt:GetBlueprint()

    local lowName = BuildingService:FindLowUpgrade( blueprint )

    if ( lowName ~= "wall_small" ) then
        return
    end

    local selector = evt:GetEntity()
    
    if ( selector == nil ) then
        return
    end

    local selectorDB = EntityService:GetDatabase( selector )

    selectorDB:SetString("$thorns_walls_blueprint", blueprint)
end)