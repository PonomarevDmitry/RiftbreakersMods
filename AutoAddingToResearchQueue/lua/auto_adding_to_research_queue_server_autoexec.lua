if ( not is_server ) then
    return
end

RegisterGlobalEventHandler("NewResearchAvailableEvent", function(evt)

    if ( not is_server ) then
        return
    end

    if (evt == nil) then
        return
    end

    local leadingPlayer = PlayerService:GetLeadingPlayer()

    local buildingBuild = BuildingService:HasBuildingWithBp("buildings/main/communications_hub")

    if ( not buildingBuild ) then
        return
    end

    local researchName = evt:GetName()

    QueueEvent( "AddToResearchRequest", INVALID_ID, researchName, leadingPlayer )
end)