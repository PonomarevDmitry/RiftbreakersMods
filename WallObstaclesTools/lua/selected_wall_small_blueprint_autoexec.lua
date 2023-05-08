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

    selectorDB:SetString("$selected_wall_small_blueprint", blueprint)
end)