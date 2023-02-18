require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_magma_scout' ( mission_base )

function mission_magma_scout:__init()
    mission_base.__init(self,self)
end

function mission_magma_scout:init()
    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/story/magma_scout.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/story/v2/magma/dom_magma_scout_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

function mission_magma_scout:OnLoad()
    local cryo_blueprints = {
        "props/special/cryo_plant/cryo_plant_big_01",
        "props/special/cryo_plant/cryo_plant_big_02",
        "props/special/cryo_plant/cryo_plant_big_03"
    }

    local blueprintsCount = 0
    for blueprint in Iter( cryo_blueprints ) do
        local entities = FindService:FindEntitiesByBlueprint(blueprint);
        blueprintsCount = blueprintsCount + #entities
    end

    if blueprintsCount < 20 then
        blueprintsCount = 0;

        local spawns = {}

        local entities = FindService:FindEntitiesByBlueprint("logic/spawn_special_object");
        for entity in Iter( entities ) do
            local spot = FindService:FindEmptySpotInRadius( entity, 10.0, "", "cryo_ground,magnetic_rock");
            if spot.first then
                Insert(spawns, spot.second)
            end
        end

        while blueprintsCount < 20 do
            if #spawns <= 0 then
                return
            end

            local position = spawns[RandInt(1, #spawns)]
            Remove(spawns,position);

            local blueprint = cryo_blueprints[RandInt(1, #cryo_blueprints)];

            local plant = EntityService:SpawnEntity(blueprint,position.x, position.x, position.z, "")
            EntityService:EnableVegetationChain( plant );

            blueprintsCount = blueprintsCount + 1
        end
    end
end

return mission_magma_scout