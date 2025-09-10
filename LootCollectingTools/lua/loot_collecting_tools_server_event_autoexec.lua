if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

local LootCollectingToolValidateTarget = function( entity, pawn )

    if ( not EntityService:IsAlive(entity) ) then
        return false, nil
    end

    local test_entity = EntityService:GetParent( entity )
    if ( test_entity == INVALID_ID ) then
        test_entity = entity
    end

    if (not EntityService:HasComponent( test_entity, "PhysicsComponent")) then
        return false, nil
    end

    local result = ItemService:CanFitResourceGiver( pawn, test_entity )

    return result, test_entity
end

RegisterGlobalEventHandler("OperateActionMapperRequest", function(evt)

    if ( not is_server ) then
        return
    end

    local mapperName = evt:GetMapperName()

    local stringNumber = string.find( mapperName, "LootCollectingToolsSingle" )
    if ( stringNumber == 1 ) then

        local entity = evt:GetEntity()
        if ( entity == nil or entity == INVALID_ID ) then
            return
        end

        if ( not EntityService:IsAlive(entity) ) then
            return false
        end

        local splitArray = Split( mapperName, "_" )

        if ( #splitArray ~= 2 ) then
            return
        end

        local playerIdStr = splitArray[2]

        local playerId = tonumber(playerIdStr)
        if ( playerId == nil ) then
            return
        end

        local player = PlayerService:GetPlayerControlledEnt(playerId)
        if ( playerId == nil or playerId == INVALID_ID ) then
            return
        end

        if ( not EntityService:IsAlive(player) ) then
            return
        end

        local checkResult, test_entity = LootCollectingToolValidateTarget(entity, player)

        if (not checkResult or test_entity == nil or test_entity == INVALID_ID) then
            return
        end

        EffectService:SpawnEffect(test_entity, "effects/loot_collecting_tool/select")

        EffectService:SpawnEffects(test_entity, "loot_collect")

        ItemService:FlyItemToInventory(player, test_entity)

        return
    end





    local stringNumber = string.find( mapperName, "LootCollectingToolsAll" )
    if ( stringNumber == 1 ) then

        local splitArray = Split( mapperName, "_" )

        if ( #splitArray ~= 2 ) then
            return
        end

        local playerIdStr = splitArray[2]

        local playerId = tonumber(playerIdStr)
        if ( playerId == nil ) then
            return
        end

        local player = PlayerService:GetPlayerControlledEnt(playerId)
        if ( playerId == nil or playerId == INVALID_ID ) then
            return
        end

        if ( not EntityService:IsAlive(player) ) then
            return
        end



        local predicate = {

            signature = "BlueprintComponent,IdComponent,ParentComponent",

            filter = function(entity)

                local entity_name = EntityService:GetName(entity);
                if ( entity_name ~= "#loot#" ) then
                    return false;
                end

                local checkResult, test_entity = LootCollectingToolValidateTarget(entity, player)

                return checkResult
            end
        };

        local world_min = MissionService:GetWorldBoundsMin();
        local world_max = MissionService:GetWorldBoundsMax();

        world_min.y = -100.0
        world_max.y = 100.0

        local tempCollection = FindService:FindEntitiesByPredicateInBox( world_min, world_max, predicate )

        local possibleSelectedEnts = {}

        for entity in Iter( tempCollection ) do

            if ( entity == nil ) then
                goto continue
            end

            if ( IndexOf( possibleSelectedEnts, entity ) ~= nil ) then
                goto continue
            end

            Insert( possibleSelectedEnts, entity )

            ::continue::
        end

        local distances = {}

        for entity in Iter( possibleSelectedEnts ) do
            distances[entity] = EntityService:GetDistanceBetween( player, entity )
        end

        local sorter = function( lh, rh )
            return distances[lh] < distances[rh]
        end

        table.sort(possibleSelectedEnts, sorter)



        for entity in Iter( possibleSelectedEnts ) do

            local checkResult, test_entity = LootCollectingToolValidateTarget(entity, player)

            if ( checkResult and test_entity ~= nil and test_entity ~= INVALID_ID ) then

                EffectService:SpawnEffect(test_entity, "effects/loot_collecting_tool/select")

                EffectService:SpawnEffects(test_entity, "loot_collect")

                ItemService:FlyItemToInventory(player, test_entity)
            end
        end

        return
    end
end)