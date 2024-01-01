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

        if ( unlocked == "tower_drone_attack_drone_point_picker" ) then
            return
        end

        if ( unlocked == "tower_drone_attack" ) then
            hasBuilding = true
        end
    end

    if (hasBuilding) then

        BuildingService:UnlockBuilding("buildings/tools/tower_drone_attack_drone_point_picker")
    end
end)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    local awardName = evt:GetName()

    if ( awardName == "buildings/defense/tower_drone_attack" ) then

        BuildingService:UnlockBuilding("buildings/tools/tower_drone_attack_drone_point_picker")
    end
end)