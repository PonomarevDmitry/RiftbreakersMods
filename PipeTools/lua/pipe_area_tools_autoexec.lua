local pipe_area_tools_autoexec = function(evt)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    local buildingSystemCampaignInfoComponentRef = reflection_helper( buildingSystemCampaignInfoComponent )

    local hasAreaTool = false
    local hasDiagonalTool = false
    local hasPerimeterTool = false
    local hasPencilTool = false

    local hasBuilding = false

    local unlocks = buildingSystemCampaignInfoComponentRef.unlocks

    for i=1,unlocks.count do

        local unlocked = unlocks[i]

        if ( unlocked == "pipe_area_tool" ) then
            hasAreaTool = true
        end

        if ( unlocked == "pipe_diagonal_tool" ) then
            hasDiagonalTool = true
        end

        if ( unlocked == "pipe_pencil_tool" ) then
            hasPencilTool = true
        end

        if ( unlocked == "pipe_perimeter_tool" ) then
            hasPerimeterTool = true
        end

        if ( unlocked == "pipeline" ) then
            hasBuilding = true
        end
    end

    if (hasBuilding) then

        if ( not hasAreaTool ) then
            BuildingService:UnlockBuilding("buildings/resources/pipe_area_tool")
        end
        if ( not hasDiagonalTool ) then
            BuildingService:UnlockBuilding("buildings/resources/pipe_diagonal_tool")
        end
        if ( not hasPencilTool ) then
            BuildingService:UnlockBuilding("buildings/resources/pipe_pencil_tool")
        end
        if ( not hasPerimeterTool ) then
            BuildingService:UnlockBuilding("buildings/resources/pipe_perimeter_tool")
        end
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    pipe_area_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    pipe_area_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    pipe_area_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    local awardName = evt:GetName()

    if ( awardName == "buildings/resources/pipe_straight" ) then

        BuildingService:UnlockBuilding("buildings/resources/pipe_area_tool")
        BuildingService:UnlockBuilding("buildings/resources/pipe_diagonal_tool")
        BuildingService:UnlockBuilding("buildings/resources/pipe_pencil_tool")
        BuildingService:UnlockBuilding("buildings/resources/pipe_perimeter_tool")
    end
end)