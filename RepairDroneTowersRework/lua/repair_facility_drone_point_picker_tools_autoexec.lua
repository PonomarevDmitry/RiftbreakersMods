local repair_facility_drone_point_picker_tools_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    local buildingSystemCampaignInfoComponentRef = reflection_helper( buildingSystemCampaignInfoComponent )

    local hasBuilding = false

    local unlocks = buildingSystemCampaignInfoComponentRef.unlocks

    for i=1,unlocks.count do

        local unlocked = unlocks[i]

        if ( unlocked == "repair_facility_drone_point_picker" ) then
            return
        end

        if ( unlocked == "repair_facility" ) then
            hasBuilding = true
        end
    end

    if (hasBuilding) then

        BuildingService:UnlockBuilding("buildings/tools/repair_facility_drone_point_picker")
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    repair_facility_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    repair_facility_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    repair_facility_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    local awardName = evt:GetName()

    if ( awardName == "buildings/defense/repair_facility" ) then

        BuildingService:UnlockBuilding("buildings/tools/repair_facility_drone_point_picker")
    end
end)