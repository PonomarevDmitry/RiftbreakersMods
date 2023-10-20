RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")

    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    local buildingSystemCampaignInfoComponentRef = reflection_helper( buildingSystemCampaignInfoComponent )

    local hasBuilding = false

    local unlocks = buildingSystemCampaignInfoComponentRef.unlocks

    for i=1,unlocks.count do

        local unlocked = unlocks[i]

        if ( unlocked == "pipe_area_tool" ) then
            return
        end

        if ( unlocked == "pipeline" ) then
            hasBuilding = true
        end
    end

    if (hasBuilding) then

        LogService:Log("Unlock pipe_area_tool in PlayerCreatedEvent")

        BuildingService:UnlockBuilding("buildings/resources/pipe_area_tool")
    end
end)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    local awardName = evt:GetName()

    if ( awardName == "buildings/resources/pipe_straight" ) then

        LogService:Log("Unlock pipe_area_tool in NewAwardEvent")

        BuildingService:UnlockBuilding("buildings/resources/pipe_area_tool")
    end
end)