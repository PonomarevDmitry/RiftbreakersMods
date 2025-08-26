require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

class 'mission_survival' ( LuaGraphNode )

function mission_survival:__init()
    LuaGraphNode.__init(self,self)
end

function mission_survival:RemoveSpawnersAroundSpawnPoint( spawn_point, distance )
    local spawners = { "units/volume_canoptrix_spawner", "units/volume_kafferroceros_spawner", "units/volume_arachnoid_sentinel_spawner" };
    local sizes = { "_small", "_medium", "_big" };
    local types = { "", "_aggressive" };

    for spawner in Iter( spawners ) do
        for size in Iter( sizes ) do
            for type in Iter( types ) do
                local blueprint = spawner .. size .. type;
                local entities = FindService:FindEntitiesByBlueprintInRadius( spawn_point, blueprint, distance );

                for entity in Iter( entities ) do
                    EntityService:RemoveEntity( entity )
                end
            end
        end
    end
end

function mission_survival:SelectWaveSpawnPoints()
    local playable_min = MissionService:GetPlayableRegionMin();
    local playable_max = MissionService:GetPlayableRegionMax();
    local world_min = MissionService:GetWorldBoundsMin();
    local world_max = MissionService:GetWorldBoundsMax();

    -- FIND ENTITIES ON MAP BORDER AND ASSIGN THEM PROPER GROUPS,
    -- SO DOM_SURVIVAL_DEMO CAN USE THEM

    local groupBounds = 
    {
		-- Due to camera rotation -x,x is not left right and -z,z is not down up
        [ "spawn_enemy_border_west" ] =
        {
            min = { x = playable_min.x,    y = -10,    z = world_min.z },
            max = { x = playable_max.x,    y = 10,     z = playable_min.z } 
        },
        [ "spawn_enemy_border_east" ] =
        {
            min = { x = playable_min.x,     y = -10,    z = playable_max.z },
            max = { x = playable_max.x,     y = 10,     z = world_max.z } 
        },
        [ "spawn_enemy_border_north" ] =
        {
            min = { x = playable_max.x,     y = -10,    z = playable_min.z },
            max = { x = world_max.x,        y = 10,     z = playable_max.z } 
        },
        [ "spawn_enemy_border_south" ] =
        {
            min = { x = world_min.x,        y = -10,    z = playable_min.z },
            max = { x = playable_min.x,     y = 10,     z = playable_max.z } 
        },
    };

    for group,bounds in pairs( groupBounds ) do
        local entities = FindService:FindEntitiesByBlueprintInBox("logic/spawn_enemy", bounds.min, bounds.max );
        Assert( #entities > 0, "Failed to find entities for: `" .. group .. "` in bounds:\nMin: " .. tostring(bounds.min.x) .. "," ..tostring(bounds.min.y) .."," ..tostring(bounds.min.z) .. "\nMax: " .. tostring(bounds.max.x) .. "," ..tostring(bounds.max.y) .."," ..tostring(bounds.max.z) )

        for entity in Iter( entities ) do
            EntityService:SetName( entity, group .. "/" .. tostring(entity) );
            EntityService:SetGroup( entity, group );
        end
    end
end

function mission_survival:OnLoad()
end

function mission_survival:init()
    -- local playable_min = MissionService:GetPlayableRegionMin();
    -- local playable_max = MissionService:GetPlayableRegionMax();
    -- local world_min = MissionService:GetWorldBoundsMin();
    -- local world_max = MissionService:GetWorldBoundsMax();

    -- *--------------------1
    -- |                    |
    -- |   *------------3   |
    -- |   |xxxxxxxxxxxx|   |
    -- |   |xxxxxxxxxxxx|   |
    -- |   |xxxxxxxxxxxx|   |
    -- |   |xxxxxxxxxxxx|   |
    -- |   2------------*   |
    -- |                    |
    -- 0--------------------|

    -- 0 - world_min, 1 - world_max
    -- 2 - playable_min, 3 - playable_max
    -- x - playable region between playable_min & playable_max

    local spawn_point = MapGenerator:SelectSpawnPoint();
    if not Assert( spawn_point ~= INVALID_ID, "Failed to select spawn point!") then
        return
    end

    MapGenerator:SetInitialSpawnPoint( spawn_point );

    self:RemoveSpawnersAroundSpawnPoint( spawn_point, 128.0 );
    self:SelectWaveSpawnPoints();

end

return mission_survival
