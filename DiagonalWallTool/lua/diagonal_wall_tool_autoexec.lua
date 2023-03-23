RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    
    BuildingService:UnlockBuilding("buildings/defense/diagonal_wall_tool")
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

    selectorDB:SetString("$diagonal_wall_blueprint", blueprint)
end)