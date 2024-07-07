local flora_cultivator_drone_point_picker_tools_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    local buildingSystemCampaignInfoComponentRef = reflection_helper( buildingSystemCampaignInfoComponent )

    local hasBuilding = false

    local unlocks = buildingSystemCampaignInfoComponentRef.unlocks

    for i=1,unlocks.count do

        local unlocked = unlocks[i]

        if ( unlocked == "flora_cultivator_drone_point_picker" ) then
            return
        end

        if ( unlocked == "flora_cultivator" ) then
            hasBuilding = true
        end
    end

    if (hasBuilding) then

        BuildingService:UnlockBuilding("buildings/tools/flora_cultivator_drone_point_picker")
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    flora_cultivator_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    flora_cultivator_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    flora_cultivator_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    local awardName = evt:GetName()

    if ( awardName == "buildings/resources/flora_cultivator" ) then

        BuildingService:UnlockBuilding("buildings/tools/flora_cultivator_drone_point_picker")
    end
end)