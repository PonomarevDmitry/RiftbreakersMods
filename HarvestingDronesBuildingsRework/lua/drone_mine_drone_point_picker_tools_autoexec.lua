if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local drone_mine_drone_point_picker_tools_autoexec = function(evt)

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

        if ( unlocked == "drone_mine_drone_point_picker" ) then
            return
        end

        if ( unlocked == "drone_mine" ) then
            hasBuilding = true
        end
    end

    if (hasBuilding) then

        BuildingService:UnlockBuilding("buildings/tools/drone_mine_drone_point_picker")
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    drone_mine_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    drone_mine_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    drone_mine_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    if ( not is_server ) then
        return
    end

    local awardName = evt:GetName()

    if ( awardName == "buildings/resources/drone_mine" ) then

        BuildingService:UnlockBuilding("buildings/tools/drone_mine_drone_point_picker")
    end
end)