require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_swamp_outpost' ( mission_base )

function mission_swamp_outpost:__init()
    mission_base.__init(self,self)
end

function mission_swamp_outpost:UpdateMissionProgress()
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

    local mission_progress = 
    {
        -- STAGE 2
        { 
            mission_name = "swamp_harvest",
            data_source = "missions/campaigns/dlc_3/swamp_outpost_stage_2.mission",
            world_region = self:GetTileRegionBounds( { x = -4, y = -2 }, { x = 0, y = 1 } )
            --world_region = self:GetTileRegionBounds( { x = -4, y = -4 }, { x = 0, y = 1} )
        },
        -- STAGE 3
        { 
            mission_name = "swamp_meadow",
            data_source = "missions/campaigns/dlc_3/swamp_outpost_stage_3.mission",
            world_region = self:GetTileRegionBounds( { x = -4, y = -4 }, { x = 0, y = 1 } ),
            --world_region = self:GetTileRegionBounds( { x = -4, y = -4 }, { x = 0, y = 3 } ),
			--mud_material = "resources/resource_mud_swamp_clean"
        },
        -- STAGE 4
        { 
            mission_name = "swamp_forest",
            data_source = "missions/campaigns/dlc_3/swamp_outpost_stage_4.mission",
            world_region = self:GetTileRegionBounds( { x = -4, y = -4 }, { x = 0, y = 3 } ),            
            --world_region = self:GetTileRegionBounds( { x = -4, y = -4 }, { x = 3, y = 3 } ),            
        },
    }

    for item in Iter( mission_progress ) do
        if not self[item.mission_name] then
            if CampaignService:GetMissionStatus(item.mission_name, false) == MISSION_STATUS_WIN then
                self[item.mission_name] = true

                MissionService:RemoveMissionVolumeCreatures();

                self:SetAccessibleWorldRegion(item.world_region.min, item.world_region.max);

                MissionService:SpawnMissionVolumeCreatures( item.data_source );
                MissionService:UpdateMissionNeutralCreatures( item.data_source );
                MissionService:SpawnMissionObjects( item.data_source );

                if item.mud_material ~= nil then
                    self:UpdateVolumeMaterial( item.mud_material )
				end
            end

            return
        end
    end
end

function mission_swamp_outpost:RemoveBrokenObjectiveSpawn()
    -- patch for Fungor spawner spawning outside of playable bounds
    local playable_min = MissionService:GetPlayableRegionMin();
    local playable_max = MissionService:GetPlayableRegionMax();

    local spawners = FindService:FindEntitiesByBlueprint("units/ground/spawner_swamp_fungor")
    for entity in Iter(spawners) do
        local entity_name = EntityService:GetName(entity)
        if string.find(entity_name, "objective") ~= nil then
            local position = EntityService:GetPosition( entity )
            if position.x < playable_min.x or position.x > playable_max.x or position.z < playable_min.z or position.z > playable_max.z then
                EntityService:RemoveEntity(entity)
            end
        end
    end
end

function mission_swamp_outpost:OnLoad()
    mission_base.OnLoad(self)

    self:UpdateMissionProgress()

    self:RemoveBrokenObjectiveSpawn()
end

function mission_swamp_outpost:init()
    mission_base.init(self)

    --STAGE 1
	local world_region = self:GetTileRegionBounds( { x = -4, y = -2 }, { x = 0, y = 1 } )
	--STAGE 2
    --local world_region = self:GetTileRegionBounds( { x = -4, y = -4 }, { x = 0, y = 1 } )
	--STAGE 3
    --local world_region = self:GetTileRegionBounds( { x = -4, y = -4 }, { x = 0, y = 3 } )
	--self:UpdateVolumeMaterial( "resources/resource_mud_swamp_clean" )
	--STAGE 4
    --local world_region = self:GetTileRegionBounds( { x = -4, y = -4 }, { x = 3, y = 3 } )
	--self:UpdateVolumeMaterial( "resources/resource_mud_swamp_clean" )
	--
    self:SetAccessibleWorldRegion( world_region.min, world_region.max )

    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/dlc_3/swamp_outpost.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/dlc_3/dom_swamp_outpost_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

function mission_swamp_outpost:UpdateVolumeMaterial( materialName )
    local playable_min = MissionService:GetPlayableRegionMin();
    local playable_max = MissionService:GetPlayableRegionMax();
    local predicate = {
        signature="ResourceVolumeComponent,MeshComponent",
        filter = function(entity)
            return ResourceService:GetResourceNameFromVein( entity ) == "mud_vein";
        end
    };

    local entities = FindService:FindEntitiesByPredicateInBox( playable_min, playable_max, predicate );
    for entity in Iter( entities ) do
        EntityService:ChangeMaterial( entity, materialName )
    end
end

return mission_swamp_outpost