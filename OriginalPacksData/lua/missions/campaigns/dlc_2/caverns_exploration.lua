require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_caverns_exploration' ( mission_base )

function mission_caverns_exploration:__init()
    mission_base.__init(self,self)
end

--function mission_caverns_exploration:UpdateMissionProgress()
--    local mission_progress = 
--    {
--        { mission_name = "metallic_crash_site", data_source = "missions/campaigns/dlc_1/metallic_outpost_stage_2.mission" },
--        { mission_name = "metallic_factory",    data_source = "missions/campaigns/dlc_1/metallic_outpost_stage_3.mission" }
--    }
--
--    for item in Iter( mission_progress ) do
--        if not self[item.mission_name] then
--            if CampaignService:GetMissionStatus(item.mission_name, false) == MISSION_STATUS_WIN then
--                self[item.mission_name] = true
--
--                MissionService:RemoveMissionVolumeCreatures();
--
--                MissionService:SpawnMissionVolumeCreatures( item.data_source );
--                MissionService:UpdateMissionNeutralCreatures( item.data_source );
--                MissionService:SpawnMissionObjects( item.data_source );
--            end
--
--            return
--        end
--    end
--end

--function mission_caverns_exploration:OnLoad()
--    self:UpdateMissionProgress()
--end

function mission_caverns_exploration:init()
    mission_base.init(self)

    self:PrepareSpawnPoints();

	MissionService:SetSkipSpawnPortalSequence(true)
    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/dlc_2/caverns_exploration.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/dlc_2/dom_caverns_exploration_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_caverns_exploration