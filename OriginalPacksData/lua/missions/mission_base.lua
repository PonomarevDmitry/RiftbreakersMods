require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/find_utils.lua")

class 'mission_base' ( LuaGraphNode )

function mission_base:__init()
    LuaGraphNode.__init(self,self)
end

function mission_base:GetNonPlayableRegions()
    local playable_min = MissionService:GetPlayableRegionMin();
    local playable_max = MissionService:GetPlayableRegionMax();
    local world_min = MissionService:GetWorldBoundsMin();
    local world_max = MissionService:GetWorldBoundsMax();

    return
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
end

function mission_base:RemoveBlueprintsOutOfPlayableBounds(blueprints)
    local groupBounds = self:GetNonPlayableRegions()
    for group,bounds in pairs( groupBounds ) do
        for blueprint in Iter(blueprints) do
            local entities = FindService:FindEntitiesByBlueprintInBox(blueprint, bounds.min, bounds.max );

            for entity in Iter( entities ) do
                EntityService:RemoveEntity( entity );
            end
        end
    end
end

function mission_base:SelectWaveSpawnPoints()
    local groupBounds = self:GetNonPlayableRegions()
    for group,bounds in pairs( groupBounds ) do
        local entities = FindService:FindEntitiesByBlueprintInBox("logic/spawn_enemy", bounds.min, bounds.max );
        Assert( #entities > 0, "Failed to find entities for: `" .. group .. "` in bounds:\nMin: " .. tostring(bounds.min.x) .. "," ..tostring(bounds.min.y) .."," ..tostring(bounds.min.z) .. "\nMax: " .. tostring(bounds.max.x) .. "," ..tostring(bounds.max.y) .."," ..tostring(bounds.max.z) )

        for entity in Iter( entities ) do
            EntityService:SetName( entity, group .. "/" .. tostring(entity) );
            EntityService:SetGroup( entity, group );
            EntityService:SpawnAndAttachEntity("logic/spawn_enemy_grid_culler", entity)
        end
    end
end

function mission_base:SelectPlayerSpawnpointNearPosition(spawnPoints)
    local spawn_near_position = self.data:GetStringOrDefault("spawn_near_position", "");
    if IsNullOrEmpty(spawn_near_position) then
        return INVALID_ID
    end

    local tokens = Split(spawn_near_position,",")
    if not Assert( #tokens == 3, "ERROR: invalid format of 'spawn_near_position='" .. spawn_near_position .. "'" ) then
        return INVALID_ID
    end

    local pos = {
        x = tonumber(tokens[1]),
        y = tonumber(tokens[2]),
        z = tonumber(tokens[3]),
    }

    LogService:Log("[MapGenerator] spawn_near_position: " .. tostring(pos.x) .. "," .. tostring(pos.y) .. "," .. tostring(pos.z))

    local temp = EntityService:SpawnEntity("logic/spawn_player", pos.x, pos.y, pos.z, "")

    local result = FindClosestEntityWithDistance(temp,spawnPoints)
    if Assert( result.entity ~= INVALID_ID, "ERROR: failed to find spawn near requested position!" ) then
        local targetPos = EntityService:GetPosition(result.entity)
        LogService:Log("[MapGenerator] spawn found: " .. tostring(targetPos.x) .. "," .. tostring(targetPos.y) .. "," .. tostring(targetPos.z) .. " distance: " .. tostring(result.distance) )
    end

    EntityService:RemoveEntity( temp )

    return result.entity
end

function mission_base:SelectPlayerSpawnpointForObjectiveTile(spawnPoints)
    local objectiveTile = self.data:GetStringOrDefault("objective_tile", "");
    if IsNullOrEmpty(objectiveTile) then
        return INVALID_ID
    end

    local objectiveMinDistance = self.data:GetFloatOrDefault("objective_min_distance", 0.0);
    local objectiveMaxDistance = self.data:GetFloatOrDefault("objective_max_distance", 10000000000000.0);
    
    local tilePositions = MapGenerator:GetTilePositions( objectiveTile );
    if #tilePositions == 0 then
        return INVALID_ID
    end

    local validSpawns = {}
    local farthestSpawn = {
        distance = 0.0,
        entity = INVALID_ID
    };

    for spawnPoint in Iter( spawnPoints ) do
        local spawnPos = EntityService:GetPosition( spawnPoint );

        local minDistance = 10000000000000.0
        for tileCenter in Iter( tilePositions ) do
            local distance = Distance( spawnPos, tileCenter )
            if distance > farthestSpawn.distance then
                farthestSpawn.distance = distance;
                farthestSpawn.entity = spawnPoint;
            end

            minDistance = math.min( minDistance, distance );
        end

        if minDistance > objectiveMinDistance and minDistance < objectiveMaxDistance then
            Insert(validSpawns, spawnPoint)
        end
    end

    if Assert( #validSpawns > 0, "ERROR: failed to find spawnpoint within objective distance: " .. tostring( objectiveMinDistance ) .. " " .. tostring( objectiveMaxDistance )) then
        local index = RandInt( 1, #validSpawns );
        return validSpawns[ index ];
    end

    return farthestSpawn.entity;
end

function mission_base:SelectPlayerSpawnPoint()
    local spawnPoints = FindService:FindPlayerSpawnPoints();
    if not Assert( #spawnPoints > 0,"ERROR: no player spawn points on map?") then
        return INVALID_ID;
    end

    local spawn_point = self:SelectPlayerSpawnpointForObjectiveTile(spawnPoints)
    if spawn_point ~= INVALID_ID then
        return spawn_point;
    end
    
    spawn_point = self:SelectPlayerSpawnpointNearPosition(spawnPoints)
    if spawn_point ~= INVALID_ID then
        return spawn_point;
    end

    return MapGenerator:SelectSpawnPoint();
end

function mission_base:PrepareSpawnPoints(safeRadius)
    local spawn_point = self:SelectPlayerSpawnPoint();
    MissionService:SetPlayerSpawnPoint( spawn_point );

    self:SelectWaveSpawnPoints();

    self:RemoveBlueprintsOutOfPlayableBounds({ "logic/spawn_objective" });

    return spawn_point
end

function mission_base:init()
    self:PrepareSpawnPoints();
end

return mission_base