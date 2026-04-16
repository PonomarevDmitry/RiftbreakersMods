if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local floor_acid_under_buildings_tool_autoexec = function(evt)

    if ( not is_server ) then
        return
    end

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    local buildingSystemCampaignInfoComponentRef = reflection_helper( buildingSystemCampaignInfoComponent )

    local hasFloorUnderBuildings = false
    local hasBuilding = false

    local unlocks = buildingSystemCampaignInfoComponentRef.unlocks

    for i=1,unlocks.count do

        local unlocked = unlocks[i]

        if ( unlocked == "floor_acid_under_buildings_tool" ) then
            hasFloorUnderBuildings = true
        end

        if ( unlocked == "floor_acid_1x1" ) then
            hasBuilding = true
        end
    end

    if ( hasFloorUnderBuildings ) then
        return
    end

    if (hasBuilding) then
    
        BuildingService:UnlockBuilding("buildings/decorations/floor_acid_under_buildings_tool")
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    floor_acid_under_buildings_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    floor_acid_under_buildings_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    floor_acid_under_buildings_tool_autoexec(evt)
end)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    if ( not is_server ) then
        return
    end

    local awardName = evt:GetName()

    if ( awardName == "buildings/decorations/floor_acid_1x1" ) then
    
        BuildingService:UnlockBuilding("buildings/decorations/floor_acid_under_buildings_tool")
    end
end)