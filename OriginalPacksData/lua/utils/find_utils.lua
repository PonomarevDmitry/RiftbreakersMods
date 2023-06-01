require( "lua/utils/table_utils.lua")

FIND_TYPE_NAME        = "Name";
FIND_TYPE_GROUP       = "Group";
FIND_TYPE_BLUEPRINT   = "Blueprint";
FIND_TYPE_TYPE        = "Type";

function FindEntity( searchRadius, searchTargetName, targetName, targetGroup, targetType, targetBlueprint )  
	--LogService:Log("FindEntity: " .. tostring(searchRadius) .. ", " .. tostring(searchTarget) .. ", " .. tostring(targetName) .. ", " .. tostring(targetGroup) .. ", " .. tostring(targetType) .. ", " .. tostring(targetBlueprint) )   
    if ( searchTargetName ~= nil ) then
        searchTarget = FindService:FindEntitiesByName( searchTargetName )
    end
    
    if searchRadius == 0 then
        if targetName ~= "" then        
            return FindService:FindEntitiesByName( targetName )        
        elseif targetGroup ~= "" then        
            return FindService:FindEntitiesByGroup( targetGroup )        
        elseif targetType ~= "" then        
                return FindService:FindEntitiesByType( targetType )
        elseif targetBlueprint ~= "" then
            return FindService:FindEntitiesByBlueprint( targetBlueprint )        
        else
            return {}
        end
    else 
        local found = {}
        for target in Iter(searchTarget ) do
            if targetName ~= "" then        
                local ent = FindService:FindEntityByNameInDistance( target, targetName, searchRadius )
                if ( ent ~= INVALID_ID ) then
                    if ( IndexOf(found, ent ) == nil ) then
                        Insert(found, ent )
                    end
                end      
            elseif targetGroup ~= "" then        
                ConcatUnique( found, FindService:FindEntitiesByGroupInRadius( target, targetGroup, searchRadius ) )   
            elseif targetType ~= "" then                
                ConcatUnique( found, FindService:FindEntitiesByTypeInRadius( target, targetType, searchRadius ) )
            elseif targetBlueprint ~= "" then
                ConcatUnique( found, FindService:FindEntitiesByBlueprintInRadius( target, targetBlueprint, searchRadius ) )  
            end
        end
        return found
    end
end

function FindEntities( findType, findValue)  
    --LogService:Log( "PlainFindEntities: " .. findType .. ":" .. findValue )
    if ( findType == FIND_TYPE_NAME ) then
        return FindService:FindEntitiesByName( findValue )     
    elseif ( findType == FIND_TYPE_GROUP ) then
        return FindService:FindEntitiesByGroup( findValue )  
    elseif ( findType == FIND_TYPE_BLUEPRINT ) then
        return FindService:FindEntitiesByBlueprint( findValue )   
    elseif ( findType == FIND_TYPE_TYPE ) then
        return FindService:FindEntitiesByType( findValue )
    else
        Assert( false, "ERROR: Invalid or unsupported find type: '" .. findType .. "', find value: '" .. findValue .. "' returning empty list!")
        return {}
    end
end

function FindEntitiesInDinstance( findType, findValue, findTarget, searchMinRadius, searchMaxRadius)  
    --LogService:Log( "FindEntitiesInDinstance: " .. findType .. ":" .. findValue .. ":" .. tostring(findTarget) .. ":" .. tostring(searchRadius) )

    local targets = {}
    if (type(findTarget) == "table") then
        targets = findTarget
    else
        targets = { findTarget }
    end

    local FilterEntities = function( source, entities )
        if searchMinRadius == 0 then
            return entities
        end

        local selected = {}
        for entity in Iter( entities ) do
            if EntityService:GetDistanceBetween( source, entity ) > searchMinRadius then
                table.insert(selected,entity)
            end
        end

        return selected
    end

    local found = {}
    for target in Iter( targets ) do
        if ( findType == FIND_TYPE_NAME ) then   
            ConcatUnique( found, FilterEntities(target, FindService:FindEntitiesByNameInRadius( target, findValue, searchMaxRadius ) ))   
        elseif ( findType == FIND_TYPE_GROUP ) then       
            ConcatUnique( found, FilterEntities(target, FindService:FindEntitiesByGroupInRadius( target, findValue, searchMaxRadius ) ))   
        elseif ( findType == FIND_TYPE_TYPE ) then               
            ConcatUnique( found, FilterEntities(target, FindService:FindEntitiesByTypeInRadius( target, findValue, searchMaxRadius ) ))
        elseif ( findType == FIND_TYPE_BLUEPRINT ) then
            ConcatUnique( found, FilterEntities(target, FindService:FindEntitiesByBlueprintInRadius( target, findValue, searchMaxRadius ) ))  
        end
    end

    return found
end

function FindEntitiesByTarget( findType, findValue, searchMinRadius, searchMaxRadius, searchFindTargetType, searchFindTargetValue)  
	--LogService:Log("FindEntities: " .. tostring(searchFindTargetType) .. ", " .. tostring(searchFindTargetValue) .. ", " .. tostring(searchRadius) .. ", " .. tostring(findType) .. ", " .. tostring(findValue)  )   
    local searchTarget = {}
    if ( searchFindTargetType ~= nil and searchFindTargetType ~= "" ) then
        searchTarget = FindEntities( searchFindTargetType, searchFindTargetValue )
    end
    
    if searchMaxRadius == 0 and searchMinRadius == 0 then
        return FindEntities( findType, findValue ), searchTarget
    else
        if searchMaxRadius == 0 then
            searchMaxRadius = 1000000.0
        end

        return FindEntitiesInDinstance( findType, findValue, searchTarget, searchMinRadius, searchMaxRadius ), searchTarget
    end
end

function FindClosestEntity( source, entities )
    local closest = {
        entity = INVALID_ID,
        distance = nil
    };

    for entity in Iter( entities ) do
        local distance = EntityService:GetDistanceBetween( source, entity );
        if closest.entity == INVALID_ID or distance < closest.distance then
            closest.entity = entity;
            closest.distance = distance;
        end
    end

    return closest.entity;
end

function FindClosestEntityWithDistance( source, entities )
    local closest = {
        entity = INVALID_ID,
        distance = nil
    };

    for entity in Iter( entities ) do
        local distance = EntityService:GetDistanceBetween( source, entity );
        if closest.entity == INVALID_ID or distance < closest.distance then
            closest.entity = entity;
            closest.distance = distance;
        end
    end

    return closest;
end

function FindObjectiveSpot(borderMargin)
	local playable_min = MissionService:GetPlayableRegionMin();
    local playable_max = MissionService:GetPlayableRegionMax();

    if borderMargin then
        playable_min.x = playable_min.x + borderMargin
        playable_min.z = playable_min.z + borderMargin

        playable_max.x = playable_max.x - borderMargin
        playable_max.z = playable_max.z - borderMargin
    end

    local wave_start_point = INVALID_ID;
	local blueprint = "logic/spawn_objective"

	local entities = FindService:FindEntitiesByBlueprintInBox(blueprint, playable_min, playable_max );
    while #entities > 0 do	
        local randomNumber = RandInt( 1, #entities )			
        wave_start_point = entities[ randomNumber ]
        if FindService:FindEntityByTypeInDistance( wave_start_point, "player", 128 ) ~= INVALID_ID then			
            LogService:Log("OBJECTIVE TOO CLOSE TO THE PLAYER - DISCARDING")
            table.remove(entities, randomNumber)				
        elseif FindService:FindEntityByTypeInDistance( wave_start_point, "building", 128 ) ~= INVALID_ID then 
            LogService:Log("OBJECTIVE TOO CLOSE TO A BUILDING - DISCARDING")
            table.remove(entities, randomNumber)
        elseif FindService:FindEntityByGroupInDistance( wave_start_point, "objective", 128 ) ~= INVALID_ID then 
            LogService:Log("OBJECTIVE TOO CLOSE TO ANOTHER OBJECTIVE - DISCARDING")
            table.remove(entities, randomNumber)
        elseif FindService:FindEntityByGroupInDistance( wave_start_point, "loot_container", 128 ) ~= INVALID_ID then 
            LogService:Log("OBJECTIVE TOO CLOSE TO LOOT CONTAINER - DISCARDING")
            table.remove(entities, randomNumber)
        else
            LogService:Log("OBJECTIVE SPAWN LOCATION FOUND")
            return wave_start_point;
        end			
    end

    LogService:Log("OBJECTIVE LOCATION NOT FOUND")
	return INVALID_ID
end

function FindAllAvailableObjectiveSpots()
	local playable_min = MissionService:GetPlayableRegionMin();
    local playable_max = MissionService:GetPlayableRegionMax();
	
    local wave_start_point = INVALID_ID;
	local blueprint = "logic/spawn_objective"

	local entities = FindService:FindEntitiesByBlueprintInBox(blueprint, playable_min, playable_max );
	if Assert( #entities > 0, "ERROR: no entities for blueprint: " .. blueprint ) then
		for i = #entities,1,-1 do
			wave_start_point = entities[ i ]
			if FindService:FindEntityByTypeInDistance( wave_start_point, "player", 128 ) ~= INVALID_ID then			
				table.remove(entities, i)				
			elseif FindService:FindEntityByTypeInDistance( wave_start_point, "building", 128 ) ~= INVALID_ID then 
				table.remove(entities, i)
			elseif FindService:FindEntityByGroupInDistance( wave_start_point, "objective", 128 ) ~= INVALID_ID then 
				table.remove(entities, i)
			elseif FindService:FindEntityByGroupInDistance( wave_start_point, "loot_container", 128 ) ~= INVALID_ID then 
				table.remove(entities, i)
			end			
		end
	end

	return entities
end

function FindResourcePoolSpot( veins, specificType)
	local playable_min = MissionService:GetPlayableRegionMin();
    local playable_max = MissionService:GetPlayableRegionMax();
    local predicate = {
        signature="ResourceVolumeComponent",
        filter = function(entity)
            --LogService:Log(tostring( veins ) .. ":" .. tostring( #veins ))
            if ( veins ~= nil and #veins ~= 0 ) then
                local resourceName = ResourceService:GetResourceNameFromVein( entity )
                if ( IndexOf(veins, resourceName) ~= nil ) then
                    if ( specificType ~= "") then
                        return ResourceService:GetResourceSpecificTypeFromVein( entity ) == specificType;
                    end
                else
                    return false
                end
            elseif( specificType ~= "") then
                return ResourceService:GetResourceSpecificTypeFromVein( entity ) == specificType;
            end
            return true
        end
    };

	local entities = FindService:FindEntitiesByPredicateInBox( playable_min, playable_max, predicate );
	if Assert( #entities > 0, "ERROR: no pools in to find ") then
		local randomNumber = RandInt( 1, #entities )			
		wave_start_point = entities[ randomNumber ]
		return wave_start_point;
	end

	return INVALID_ID
end

function FindBuilding(findType, findValue, searchRadius, searchFindTargetType, searchFindTargetValue)
	local entities = {}
    if ( findType == "Blueprint") then
		if ( searchRadius > 0 and searchFindTargetType ~= nil and searchFindTargetType ~= "") then
			local targets = FindEntities( searchFindTargetType, searchFindTargetValue );
			for target in Iter(targets) do	
				ConcatUnique( entities, BuildingService:GetFinishedBuildingByBp( target, findValue, searchRadius ))
			end
		else
			entities = BuildingService:GetFinishedBuildingByBp(findValue)
		end
	else
		entities = FindEntitiesByTarget(findType, findValue, 0.0, searchRadius, searchFindTargetType, searchFindTargetValue);
	end    
    return entities
end
