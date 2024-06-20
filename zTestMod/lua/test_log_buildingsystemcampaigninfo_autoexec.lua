require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

ConsoleService:RegisterCommand( "test_log_buildingsystemcampaigninfo", function( args )

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")

    if ( buildingSystemCampaignInfoComponent == nil ) then

        LogService:Log("BuildingSystemCampaignInfoComponent is nil")
        return
    end

    local buildingSystemCampaignInfoComponentRef = reflection_helper( buildingSystemCampaignInfoComponent )

    LogService:Log(tostring(buildingSystemCampaignInfoComponentRef))
end)