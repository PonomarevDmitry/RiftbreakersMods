local loot_collector_drone_point_picker_tools_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    local buildingSystemCampaignInfoComponentRef = reflection_helper( buildingSystemCampaignInfoComponent )

    local hasBuilding = false

    local unlocks = buildingSystemCampaignInfoComponentRef.unlocks

    for i=1,unlocks.count do

        local unlocked = unlocks[i]

        if ( unlocked == "loot_collector_drone_point_picker" ) then
            return
        end

        if ( unlocked == "loot_collector" ) then
            hasBuilding = true
        end
    end

    if (hasBuilding) then

        BuildingService:UnlockBuilding("buildings/tools/loot_collector_drone_point_picker")
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    loot_collector_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    loot_collector_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    loot_collector_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    local awardName = evt:GetName()

    if ( awardName == "buildings/resources/loot_collector" ) then

        BuildingService:UnlockBuilding("buildings/tools/loot_collector_drone_point_picker")
    end
end)