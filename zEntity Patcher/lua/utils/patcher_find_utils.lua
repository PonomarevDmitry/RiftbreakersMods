require( "lua/utils/find_utils.lua" )
require( "lua/utils/table_utils.lua" )

-- function FindFarthestEntity( source, entities )
--     local farthest_entity = INVALID_ID
--     local farthest_distance = -1

--     for entity in Iter( entities ) do
--         local distance = EntityService:GetDistanceBetween( source, entity );
--         if distance > farthest_distance then
--             farthest_entity = entity;
--             farthest_distance = distance;
--         end
--     end

--     return farthest_entity;
-- end

function FindEntitiesInDinstance( findType, findValue, findTarget, searchMinRadius, searchMaxRadius )
    -- LogService:Log( "FindEntitiesInDinstance: " .. findType .. ":" .. findValue .. ":" .. tostring(findTarget) .. ":" .. tostring(searchRadius) )

    local targets = type( findTarget ) == "table" and findTarget or {
        findTarget
    }

    local FilterEntities = function( source, entities )
        if searchMinRadius == 0 then
            return entities
        end

        local selected = {}
        for i = 1, #entities do
            local entity = entities[i]
            if EntityService:GetDistanceBetween( source, entity ) > searchMinRadius then
                selected[#selected + 1] = entity
            end
        end

        return selected
    end

    local Searcher
    if findType == FIND_TYPE_NAME then
        Searcher = FindService.FindEntitiesByNameInRadius
    elseif findType == FIND_TYPE_GROUP then
        Searcher = FindService.FindEntitiesByGroupInRadius
    elseif findType == FIND_TYPE_TYPE then
        Searcher = FindService.FindEntitiesByTypeInRadius
    elseif findType == FIND_TYPE_BLUEPRINT then
        Searcher = FindService.FindEntitiesByBlueprintInRadius
    else
        return {}
    end

    local found = {}

    for _, target in ipairs( targets ) do
        ConcatUnique( found, FilterEntities( target, Searcher( FindService, target, findValue, searchMaxRadius ) ) )
    end

    return found
end

function FindClosestEntity( source, entities )
    local closest_entity = INVALID_ID
    local closest_distance = math.huge

    for entity in Iter( entities ) do
        local distance = EntityService:GetDistanceBetween( source, entity )
        if distance < closest_distance then
            closest_entity = entity
            closest_distance = distance
        end
    end

    return closest_entity
end

function FindClosestEntityWithDistance( source, entities )
    local closest_entity = INVALID_ID
    local closest_distance = math.huge

    for entity in Iter( entities ) do
        local distance = EntityService:GetDistanceBetween( source, entity )
        if distance < closest_distance then
            closest_entity = entity
            closest_distance = distance
        end
    end

    return {
        entity = closest_entity,
        distance = closest_distance
    }
end
