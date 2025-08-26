require("lua/utils/table_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_generator' ( mission_base )

local g_property_handlers = {
    -- TileSpawnRule
    tile_coords = function( object, coords )
        for tile_coord in Iter(coords) do
            object:AddTileCoord(tile_coord.x, tile_coord.y)
        end
    end,

    -- ObjectSpawner
    spawner_type = function() end,

    spawn_pool = function( object, pools )
        if type(object) == "string" then
            pools = Split( pools, ",")
        end

        for pool_name in Iter(pools) do
            object:AddSpawnPool( pool_name )
        end
    end,

    spawn_min_distance_from_pools = function( object, pool_distances )
        for pool_name, distance in pairs(pool_distances) do
            object:AddSpawnMinDistanceFromPools(pool_name, distance)
        end
    end,

    spawn_max_distance_from_pools = function( object, pool_distances )
        for pool_name, distance in pairs(pool_distances) do
            object:AddSpawnMaxDistanceFromPools(pool_name, distance)
        end
    end,

    -- ObjectSpawner
    spawn_blueprints = function( object, object_spawns, path )
        for index, object_spawn in ipairs(object_spawns) do
            local spawn = object:AddObjectToSpawn()
            TableToObjectParams( spawn, object_spawn, path .. "[" .. tostring(index) .. "]" )
        end
    end,

    -- ObjectSpawn
    spawn_species = function( object, value )
        object.spawn_blueprint = value;
        object.spawn_type = 1
    end,
    database = function( object, values, path )
        local database = object.database
        for key, value in pairs(values) do
            local property_path = path .. "." .. key

            local value_type = type(value)
            if value_type == "string" then
                database:SetString( key, value )
            elseif value_type == "number" then
                database:SetFloat( key, value )
                database:SetInt( key, value )
            elseif value_type == "boolean" then
                local b = 0
                if value then b = 1 end

                database:SetInt( key, b )
            else
                Assert( false, "ERROR: unknown database value type: '" .. value_type .. "' used!( " .. property_path .. " = " .. tostring(value) .. ")");
            end
        end
    end,

    -- AmbientCreatureVolume
    species = function( object, value, path )
        for index, species in ipairs(value) do
            local spawn = object:CreateCreatureVolume()
            TableToObjectParams( spawn, species, path .. "[" .. tostring(index) .. "]" )
        end
    end
}

-- HELPERS
function TableToObjectParams( object, params, path )
    for key, value in pairs(params) do
        local property_path = path .. "." .. key

        local handler = g_property_handlers[ key ]
        if handler ~= nil then
            handler( object, value, property_path )
        else       
            local property = object[ key ]     
            if type(value) == 'table' then
                TableToObjectParams( object[ key ], value, property_path )
            elseif Assert( property ~= nil, "ERROR: object has no property named: '" .. property_path .. "'") then
                object[ key ] = value
            end
        end
    end
end

--[[
    local tile_spawn_rules = [
        { 
            tile_name = "biomes/magma/tiles/magma_plains_02/magma_plains_02.tile" 
            random_weight = 2.0
        }
    ]
]]

function mission_generator:CreateTileSpawnRules( tile_spawn_rules )
    if not Assert( type( tile_spawn_rules ) == 'table', "ERROR: table expected as an argument!") then return end

    for index,rule in ipairs(tile_spawn_rules) do
        local tile_name = rule.tile_name
        rule.tile_name = nil

        local tile_spawn = MapGenerator:CreateTileSpawnRule(tile_name)
        TableToObjectParams( tile_spawn, rule, "CreateTileSpawnRules[" .. tostring(index) .."]" )
    end
end

--[[
    local light_mask_materials = [
        { 
            tile_name = "biomes/magma/tiles/magma_plains_02/magma_plains_02.tile" 
            random_weight = 2.0
        }
    ]
]]

function mission_generator:CreateLightMaskMaterialsRules( light_mask_material )
    if not Assert( type( light_mask_material ) == 'table', "ERROR: table expected as an argument!") then return end

    for index,rule in ipairs(light_mask_material) do
        local tile_name = rule.tile_name
        rule.tile_name = nil

        local tile_spawn = MapGenerator:CreateLightMaskMaterialsRule(tile_name)
        TableToObjectParams( tile_spawn, rule, "CreateLightMaskMaterialsRules[" .. tostring(index) .."]" )
    end
end

--[[
    local destructible_volume_texture_patterns = [
        { 
            tile_name = "biomes/magma/tiles/magma_plains_02/magma_plains_02.tile" 
            random_weight = 2.0
        }
    ]
]]

function mission_generator:CreateDestructibleVolumePatternRules( destructible_volume_pattern )
    if not Assert( type( destructible_volume_pattern ) == 'table', "ERROR: table expected as an argument!") then return end

    for index,rule in ipairs(destructible_volume_pattern) do
        local tile_name = rule.tile_name
        rule.tile_name = nil

        local tile_spawn = MapGenerator:CreateDestructibleVolumePatternRule(tile_name)
        TableToObjectParams( tile_spawn, rule, "CreateDestructibleVolumePatternRules[" .. tostring(index) .."]" )
    end
end


--[[
    local creature_volumes_species = {
        neutral_units = [
            {
                creature_species = "morirot",
                volume_spawn_ratio = 3
            }
        ]
    }
]]

function mission_generator:CreateCreatureSpawnRules(creature_volumes_species)
    for volume_type, spawner_params in pairs(creature_volumes_species) do
        for index, params in ipairs( spawner_params ) do
            local spawner = MapGenerator:CreateCreatureSpawnRule( volume_type )
            TableToObjectParams( spawner, params, "CreateCreatureSpawnRules[" .. volume_type .. "][" .. tostring(index) .."]" )
        end
    end
end

function mission_generator:CreateAmbientCreatureSpawnRules(creature_volumes_species)
    for volume_type, params in pairs(creature_volumes_species) do
        local spawner = MapGenerator:CreateAmbientCreatureSpawnRule( volume_type )
        TableToObjectParams( spawner, params, "CreateAmbientCreatureSpawnRules[" .. volume_type .. "][" .. tostring(index) .."]" )
    end
end


--[[
    local mission_object_spawners = [
        {
            spawner_type    = "MarkerBlueprintSpawner",
            spawn_pool      = { "loot_containers", "random_pols" },
            spawn_at_marker = "logic/spawn_objective",

            spawn_min_distance_from_pools = 
            {
                player_spawn_point = 250.0,
                loot_containers    = 150.0,
				resource_volumes   = 10
            },

            spawn_instances_minmax = { min = 15, max = 20 },

            spawn_blueprints =
            [
                {
                    --spawn_species         = "canoptrix",
                    spawn_blueprint         = "spawners/magma_spawner_standard",
                    spawn_chance            = 0.5
                },
                {
                    spawn_blueprint         = "spawners/magma_spawner_advanced",
                    spawn_instances_minmax  = { min = 3, max = 5 }
                    spawn_chance            = 0.2
                },
                {
                    spawn_blueprint         = "spawners/magma_spawner_superior",
                    spawn_instances_minmax  = { min = 2, max = 3 }
                    spawn_chance            = 0.2
                },
                {
                    spawn_blueprint         = "spawners/magma_spawner_extreme",
                    spawn_instances_minmax  = { min = 1, max = 2 },
                    spawn_chance            = 0.1,
                }
            ]
        }
    ]
]]

function mission_generator:CreateMissionObjectSpawnRules(mission_object_spawners)
    if not Assert( type( mission_object_spawners ) == 'table', "ERROR: table expected as an argument!") then return end

    for index, spawner_params in ipairs(mission_object_spawners) do
        local object_spawner = nil
        if spawner_params.spawner_type == "MarkerBlueprintSpawner" then
            object_spawner = MapGenerator:CreateObjectMarkerSpawnRule()
        elseif spawner_params.spawner_type == "GridSpawner" then
            object_spawner = MapGenerator:CreateObjectGridSpawnRule()
        end

        if Assert( object_spawner ~= nil, "ERROR: unknown spawner_type='" .. tostring(object_spawner.spawner_type) .. "'") then
            TableToObjectParams( object_spawner, spawner_params, "CreateMissionObjectSpawnRules[" .. tostring(index) .."]" )
        end
    end
end

--[[
    local starting_resources = 
    {
        {
            resource                = "titanium_vein",
			
            min_resources           = 6000,
            max_resources           = 12000,

            is_infinite             = false,

            min_spawned_volumes     = 1,
            max_spawned_volumes     = 2,
        },
]]

function mission_generator:CreateRandomResourcesSpawnRules( resources )
    if not Assert( type( resources ) == 'table', "ERROR: table expected as an argument!") then return end

    for index,spawner_params in ipairs(resources) do
        local spawner = MapGenerator:CreateRandomResourceSpawnRule( spawner_params.resource )
        TableToObjectParams( spawner, spawner_params, "CreateRandomResourcesSpawnRules[" .. tostring(index) .."]" )
    end
end

function mission_generator:CreateStartupResourcesSpawnRules( resources )
    if not Assert( type( resources ) == 'table', "ERROR: table expected as an argument!") then return end

    for index, spawner_params in ipairs(resources) do
        local spawner = MapGenerator:CreateStartupResourceSpawnRule( spawner_params.resource )
        TableToObjectParams( spawner, spawner_params, "CreateStartupResourcesSpawnRules[" .. tostring(index) .."]"  )
    end
end

--[[ FUNCTIONS ARE DEFINED HERE IN ORDER OF EXECUTION ]]

--[[ Game: RandomizeMission ]]

function mission_generator:__init()
    mission_base.__init(self,self)
end

--[[ USABLE METHODS
    MapGenerator:SetMapSize( width, height )
    MapGenerator:SetMission( mission_name )
    MapGenerator:SetBiome( biome_name )
    MapGenerator:SetGeneratorSeed( seed )

    -- must be called after SetMission

    MapGenerator:SetPlayerDetectorEnabled
    MapGenerator:SetNavigationCullingEnabled
]]

function mission_generator:PrepareMapGenerator()
    mission_base.PrepareMapGenerator( self )
end

--[[ Game: PrepareMissionBiome ]]

--[[ USABLE METHODS
    MapGenerator:ClearTileSpawnRules
    MapGenerator:CreateTileSpawnRule( tile_name ) : TileSpawnRule
]]

function mission_generator:PrepareMissionTilesPool()
    mission_base.PrepareMissionTilesPool( self )
end

--[[ Game: SolveTileGridLayout ]]
--[[ Game: SpawnTileSceneEntities ]]

function mission_generator:init()
    mission_base.init( self )
end

--[[ Game: BlockInaccessibleCells ]]

--[[ USABLE METHODS
    MapGenerator:SetInitialSpawnPoint
]]

function mission_generator:PrepareSpawnPoints()
    mission_base.PrepareSpawnPoints( self )
end

--[[ USABLE METHODS
    MapGenerator:ClearRandomResourceSpawnRules
    MapGenerator:CreateRandomResourceVolumeSpawnRule( resource_type ) : ResourceVolume
    MapGenerator:SetStartupResourceSpawnDistance( min, max )
    MapGenerator:ClearStartupResourceSpawnRules
    MapGenerator:CreateStartupResourceVolumeSpawnRule( resource_type ) : ResourceVolume
    MapGenerator:CreateObjectGridSpawnRule
    MapGenerator:ClearObjectSpawnRules
    MapGenerator:CreateObjectMarkerSpawnRule
    MapGenerator:SetCreatureVolumesDistanceFromPlayerSpawn
    MapGenerator:SetCreatureVolumesDensity
    MapGenerator:ClearCreatureSpawnRules
    MapGenerator:CreateCreatureSpawnRule( volume_type ) : CreatureVolume
    MapGenerator:ClearAmbientCreatureSpawnRules
    MapGenerator:CreateAmbientCreatureSpawnRule( volume_type ) : AmbientCreatureVolume
]]

function mission_generator:PrepareMissionObjects()
    mission_base.PrepareMissionObjects( self )
end

--[[ Game: SpawnResourceVolumes ]]
--[[ Game: SpawnMissionObjects ]]
--[[ Game: SpawnCreatureVolumes ]]

--[[ USABLE METHODS
    MissionService:ActivateMissionFlow()
    MissionService:AddGameRule()
]]

function mission_generator:Activated()
    mission_base.Activated( self )
end

return mission_generator