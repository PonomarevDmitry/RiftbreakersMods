require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_swamp_forest' ( mission_base )

function mission_swamp_forest:__init()
    mission_base.__init(self,self)
end

local function ForcePlayerSpawn( spawn_point_name )
    local entity = FindService:FindEntityByName(spawn_point_name )
    if not Assert( entity ~= INVALID_ID, "ERROR: missing requested player spawn point: '" .. spawn_point_name .. "'") then
        return
    end

    local players = PlayerService:GetConnectedPlayers()
    for player in Iter(players) do
        local pawn = PlayerService:GetPlayerControlledEnt( player )
        EntityService:Teleport( pawn, entity )
    end
     players = PlayerService:GetAllPlayers()
     for  player in Iter(players) do
        PlayerService:SetTempPlayerSpawnPoint( player, INVALID_ID )
    end
end

function mission_swamp_forest:UpdateMissionProgress()
    -- -----------------------------------------
    -- | S4 | S4 | S4 | S4 | S4 | S4 | S4 | S4 |     3
    -- | S4 | S4 | S4 | S4 | S4 | S4 | S4 | S4 |     2
    -- | S2 | S2 |    |    |    |    | S3 | S3 |     1
    -- | S2 | S2 |    |    |    |    | S3 | S3 |     0
    -- | S2 | S2 |    |    |    |    | S3 | S3 |    -1
    -- | S2 | S2 |    |    |    |    | S3 | S3 |    -2
    -- | S2 | S2 |    |    |    |    | S3 | S3 |    -3
    -- | S2 | S2 |    |    |    |    | S3 | S3 |    -4
    -- -----------------------------------------
    --  -4    -3   -2   -1   0    1    2    3

    local mission_stages = 
    {
        -- STAGE 2
        { 
            mission_name = "swamp_forest_cave",
            data_source = "missions/campaigns/dlc_3/swamp_forest_stage_2.mission",
            world_region = self:GetTileRegionBounds( { x = -3, y = -5 }, { x = 2, y = 5 } ),
            player_spawn_point = "logic/spawn_player_forest_cave_exit"
        },        
    }

    for stage in Iter( mission_stages ) do
        if not self[stage.mission_name] then
            if CampaignService:GetMissionStatus(stage.mission_name, false) == MISSION_STATUS_WIN then
                self[stage.mission_name] = true

                MissionService:RemoveMissionVolumeCreatures();

                if stage.world_region then
                    self:SetAccessibleWorldRegion(stage.world_region.min, stage.world_region.max);
                end

                if stage.player_spawn_point then
                    ForcePlayerSpawn( stage.player_spawn_point )
                end

                MissionService:SpawnMissionVolumeCreatures( stage.data_source );
                MissionService:UpdateMissionNeutralCreatures( stage.data_source );
                MissionService:SpawnMissionObjects( stage.data_source );
            end

            return
        end
    end
end

function mission_swamp_forest:OnLoad()
    mission_base.OnLoad(self)

    self:UpdateMissionProgress()
end

function mission_swamp_forest:init()
    mission_base.init(self)

	--STAGE 1
	local world_region = self:GetTileRegionBounds( { x = -3, y = -1 }, { x = 2, y = 5 } )
	--STAGE 2
    --local world_region = self:GetTileRegionBounds( { x = -3, y = -5 }, { x = 2, y = 5 } )	    
    self:SetAccessibleWorldRegion( world_region.min, world_region.max )
    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/dlc_3/swamp_forest.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/dlc_3/dom_swamp_forest_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_swamp_forest