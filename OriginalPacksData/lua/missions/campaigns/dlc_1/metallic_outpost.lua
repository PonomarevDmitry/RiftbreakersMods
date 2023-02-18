require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_metallic_outpost' ( mission_base )

function mission_metallic_outpost:__init()
    mission_base.__init(self,self)
end

function mission_metallic_outpost:UpdateMissionProgress()
    local mission_progress = 
    {
        { mission_name = "metallic_crash_site", data_source = "missions/campaigns/dlc_1/metallic_outpost_stage_2.mission" },
        { mission_name = "metallic_factory",    data_source = "missions/campaigns/dlc_1/metallic_outpost_stage_3.mission" }
    }

    for item in Iter( mission_progress ) do
        if not self[item.mission_name] then
            if CampaignService:GetMissionStatus(item.mission_name, false) == MISSION_STATUS_WIN then
                self[item.mission_name] = true

                MissionService:RemoveMissionVolumeCreatures();

                MissionService:SpawnMissionVolumeCreatures( item.data_source );
                MissionService:UpdateMissionNeutralCreatures( item.data_source );
                MissionService:SpawnMissionObjects( item.data_source );
            end

            return
        end
    end
end

function mission_metallic_outpost:OnLoad()
    self:UpdateMissionProgress()
end

function mission_metallic_outpost:init()
    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/dlc_1/metallic_outpost.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/dlc_1/dom_metallic_outpost_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_metallic_outpost