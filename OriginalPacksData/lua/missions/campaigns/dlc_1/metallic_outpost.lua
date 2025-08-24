require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")
require("lua/utils/enumerables.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_metallic_outpost' ( mission_base )

function mission_metallic_outpost:__init()
    mission_base.__init(self,self)
end

function mission_metallic_outpost:EnsureInfluencePylonsObjective()
    local objective_id = ObjectiveService:FindMatchingObjectiveIdsFromUniqueName("influence_pylon.activate")[1] or INVALID_OBJECTIVE_ID
    if objective_id == INVALID_OBJECTIVE_ID then
        return
    end

    local objective_status = ObjectiveService:GetObjectiveStatus( objective_id )
    if objective_status ~= OBJECTIVE_IN_PROGRESS then
        return
    end

    local objective_data = ObjectiveService:GetObjectiveDatabase( objective_id )
    if objective_data == nil then
        return
    end

    local progress = objective_data:GetIntOrDefault( "progress_current", 0 )
    local progress_max = objective_data:GetIntOrDefault( "progress_max", 0 )

    local pylons = FindService:FindEntitiesByName( "influence_pylon" )
    local missing_count = (progress_max - progress) - #pylons
    for i=1,missing_count do
        local entity = MissionService:SpawnMissionObjective("props/special/alien_structures/influence_pylon", true)
        EntityService:SetName( entity, "influence_pylon")
    end
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
    mission_base.OnLoad(self)

    self:UpdateMissionProgress()
    self:EnsureInfluencePylonsObjective()
end

function mission_metallic_outpost:init()
    mission_base.init(self)

    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/dlc_1/metallic_outpost.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/dlc_1/dom_metallic_outpost_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_metallic_outpost