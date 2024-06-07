local shield_generator_center_point_picker_tools_autoexec = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
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

RegisterGlobalEventHandler("PlayerCreatedEvent", shield_generator_center_point_picker_tools_autoexec)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", shield_generator_center_point_picker_tools_autoexec)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    local awardName = evt:GetName()

    if ( awardName == "buildings/defense/shield_generator" ) then

        BuildingService:UnlockBuilding("buildings/tools/shield_generator_center_point_picker")
    end
end)