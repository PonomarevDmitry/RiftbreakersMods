require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_the_abys_boss_arena_01' ( mission_base )

function mission_the_abys_boss_arena_01:__init()
    mission_base.__init(self,self)
end

--function mission_the_abys_boss_arena_01:UpdateMissionProgress()
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

--function mission_the_abys_boss_arena_01:OnLoad()
--    self:UpdateMissionProgress()
--end

function mission_the_abys_boss_arena_01:init()
    mission_base.init(self)
    
    self:PrepareSpawnPoints();

	MissionService:SetSkipSpawnPortalSequence(true)
    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/story/the_abys_boss_arena_01.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/story/v2/the_abys/dom_the_abys_boss_arena_01_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_the_abys_boss_arena_01