local floor_desert_tool_autoexec = function(evt)

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

    local hasFloor1 = false
    local hasFloor2 = false
    local hasFloor3 = false
    local hasFloor4 = false
    local hasBuilding = false

    local unlocks = buildingSystemCampaignInfoComponentRef.unlocks

    for i=1,unlocks.count do

        local unlocked = unlocks[i]

        if ( unlocked == "floor_desert_tool_1" ) then
            hasFloor1 = true
        end

        if ( unlocked == "floor_desert_tool_2" ) then
            hasFloor2 = true
        end

        if ( unlocked == "floor_desert_tool_3" ) then
            hasFloor3 = true
        end

        if ( unlocked == "floor_desert_tool_4" ) then
            hasFloor4 = true
        end

        if ( unlocked == "floor_desert_1x1" ) then
            hasBuilding = true
        end
    end

    if ( hasFloor1 and hasFloor2 and hasFloor3 and hasFloor4 ) then
        return
    end

    if (hasBuilding) then

        BuildingService:UnlockBuilding("buildings/decorations/floor_desert_tool_1")
        BuildingService:UnlockBuilding("buildings/decorations/floor_desert_tool_2")
        BuildingService:UnlockBuilding("buildings/decorations/floor_desert_tool_3")
        BuildingService:UnlockBuilding("buildings/decorations/floor_desert_tool_4")
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    floor_desert_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    floor_desert_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    local awardName = evt:GetName()

    if ( awardName == "buildings/decorations/floor_desert_1x1" ) then

        BuildingService:UnlockBuilding("buildings/decorations/floor_desert_tool_1")
        BuildingService:UnlockBuilding("buildings/decorations/floor_desert_tool_2")
        BuildingService:UnlockBuilding("buildings/decorations/floor_desert_tool_3")
        BuildingService:UnlockBuilding("buildings/decorations/floor_desert_tool_4")
    end
end)