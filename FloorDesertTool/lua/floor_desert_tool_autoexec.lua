RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")

    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    local buildingSystemCampaignInfoComponentRef = reflection_helper( buildingSystemCampaignInfoComponent )

    local hasFloor = false

    local unlocks = buildingSystemCampaignInfoComponentRef.unlocks

    for i=1,unlocks.count do

        local unlocked = unlocks[i]

        if ( unlocked == "floor_desert_tool" ) then
            return
        end

        if ( unlocked == "floor_desert_1x1" ) then
            hasFloor = true
        end
    end

    if (hasFloor) then

        BuildingService:UnlockBuilding("buildings/decorations/floor_desert_tool")
    end
end)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    local awardName = evt:GetName()

    if ( awardName == "buildings/decorations/floor_desert_1x1" ) then

        BuildingService:UnlockBuilding("buildings/decorations/floor_desert_tool")
    end
end)