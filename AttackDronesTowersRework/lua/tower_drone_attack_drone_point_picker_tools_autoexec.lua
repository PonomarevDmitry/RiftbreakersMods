local tower_drone_attack_drone_point_picker_tools_autoexec = function(evt)

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

    local hasDronePointPicker = false
    local hasSlotsPicker = false
    local hasSlotsReplacer = false

    local hasBuilding = false

    local unlocks = buildingSystemCampaignInfoComponentRef.unlocks

    for i=1,unlocks.count do

        local unlocked = unlocks[i]

        if ( unlocked == "tower_drone_attack_drone_point_picker" ) then
            hasDronePointPicker = true
        end

        if ( unlocked == "tower_drone_attack_slots_picker" ) then
            hasSlotsPicker = true
        end

        if ( unlocked == "tower_drone_attack_slots_replacer" ) then
            hasSlotsReplacer = true
        end

        if ( unlocked == "tower_drone_attack" ) then
            hasBuilding = true
        end
    end

    if ( hasDronePointPicker and hasSlotsPicker and hasSlotsReplacer ) then
        return
    end

    if (hasBuilding) then

        BuildingService:UnlockBuilding("buildings/tools/tower_drone_attack_drone_point_picker")
        BuildingService:UnlockBuilding("buildings/tools/tower_drone_attack_slots_picker")
        BuildingService:UnlockBuilding("buildings/tools/tower_drone_attack_slots_replacer")
    end
end

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    tower_drone_attack_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    tower_drone_attack_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    local awardName = evt:GetName()

    if ( awardName == "buildings/defense/tower_drone_attack" ) then

        BuildingService:UnlockBuilding("buildings/tools/tower_drone_attack_drone_point_picker")
        BuildingService:UnlockBuilding("buildings/tools/tower_drone_attack_slots_picker")
        BuildingService:UnlockBuilding("buildings/tools/tower_drone_attack_slots_replacer")
    end
end)