---
layout: default
title: MapGenerator
has_children: false
parent: Class
grand_parent: Game Reflection
---
# MapGenerator
Description 

## Fields

| Type | Name |
|:----------|:--------------|
| [Aabb](/riftbreaker-wiki/docs/game-reflection/classes/aabb/) | playable_bounds |
| [Random](/riftbreaker-wiki/docs/game-reflection/components/random/) | random |
| [uint64](/riftbreaker-wiki/docs/game-reflection/components/uint64/) | generator_seed |
| [MissionDef](/riftbreaker-wiki/docs/game-reflection/classes/mission_def/) | generator_params |
| [ResourceHandle_MissionDef](/riftbreaker-wiki/docs/game-reflection/classes/resource_handle__mission_def/) | mission |
| [ResourceHandle_BiomeDef](/riftbreaker-wiki/docs/game-reflection/classes/resource_handle__biome_def/) | biome |
| Container< [Pair_MaterialHolder_MaterialHolder](/riftbreaker-wiki/docs/game-reflection/classes/pair__material_holder__material_holder/) > | shared_materials |
| [TileGrid](/riftbreaker-wiki/docs/game-reflection/classes/tile_grid/) | tile_grid |
| Container< [Pair_TypeHash_Set_IdString](/riftbreaker-wiki/docs/game-reflection/classes/pair__type_hash__set__id_string/) > | precached_resources |
| [Vector3](/riftbreaker-wiki/docs/game-reflection/classes/vector3/) | spawn_position |
| [Entity](/riftbreaker-wiki/docs/game-reflection/classes/entity/) | initial_spawn |
| Container< [Entity](/riftbreaker-wiki/docs/game-reflection/classes/entity/) > | spawned_treasures |
| [uint64](/riftbreaker-wiki/docs/game-reflection/components/uint64/) | spawned_treasures_count |
| Container< [Entity](/riftbreaker-wiki/docs/game-reflection/classes/entity/) > | spawned_resources |
| [uint64](/riftbreaker-wiki/docs/game-reflection/components/uint64/) | spawned_resources_count |

