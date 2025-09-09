if ( not is_server ) then
    return
end

local shield_generator_center_point_picker_tools_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    local buildingSystemCampaignInfoComponentRef = reflection_helper( buildingSystemCampaignInfoComponent )

    local hasBuilding = false

    local unlocks = buildingSystemCampaignInfoComponentRef.unlocks

    for i=1,unlocks.count do

        local unlocked = unlocks[i]

        if ( unlocked == "shield_generator_center_point_picker" ) then
            return
        end

        if ( unlocked == "shield_generator" ) then
            hasBuilding = true
        end
    end

    if (hasBuilding) then

        BuildingService:UnlockBuilding("buildings/tools/shield_generator_center_point_picker")
    end
end

--RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
--
--    shield_generator_center_point_picker_tools_autoexec(evt)
--end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    shield_generator_center_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    shield_generator_center_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    if ( not is_server ) then
        return
    end

    local awardName = evt:GetName()

    if ( awardName == "buildings/defense/shield_generator" ) then

        BuildingService:UnlockBuilding("buildings/tools/shield_generator_center_point_picker")
    end
end)