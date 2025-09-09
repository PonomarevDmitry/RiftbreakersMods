if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local tower_mine_drone_point_picker_tools_autoexec = function(evt)

    if ( not is_server ) then
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

        if ( unlocked == "tower_mine_drone_point_picker" ) then
            hasDronePointPicker = true
        end

        if ( unlocked == "tower_mine_slots_picker" ) then
            hasSlotsPicker = true
        end

        if ( unlocked == "tower_mine_slots_replacer" ) then
            hasSlotsReplacer = true
        end

        if ( unlocked == "tower_mine_layer" ) then
            hasBuilding = true
        end
    end

    if ( hasDronePointPicker and hasSlotsPicker and hasSlotsReplacer ) then
        return
    end

    if (hasBuilding) then

        BuildingService:UnlockBuilding("buildings/tools/tower_mine_drone_point_picker")
        BuildingService:UnlockBuilding("buildings/tools/tower_mine_slots_picker")
        BuildingService:UnlockBuilding("buildings/tools/tower_mine_slots_replacer")
    end
end

--RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
--
--    tower_mine_drone_point_picker_tools_autoexec(evt)
--end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    tower_mine_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    tower_mine_drone_point_picker_tools_autoexec(evt)
end)

RegisterGlobalEventHandler("NewAwardEvent", function(evt)

    if ( not is_server ) then
        return
    end

    local awardName = evt:GetName()

    if ( awardName == "buildings/defense/tower_mine_layer" ) then

        BuildingService:UnlockBuilding("buildings/tools/tower_mine_drone_point_picker")
        BuildingService:UnlockBuilding("buildings/tools/tower_mine_slots_picker")
        BuildingService:UnlockBuilding("buildings/tools/tower_mine_slots_replacer")
    end
end)