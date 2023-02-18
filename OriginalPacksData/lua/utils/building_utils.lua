require("lua/utils/reflection.lua")

function HaveWorkingStabilizators( entity, radius, stabilizerCount, alienFactor)
		local magneticStabilizer = FindService:FindEntitiesByBlueprintInRadius( entity, "buildings/main/rift_magnetic_stabilizer", radius )
		local alienStabilizer    = FindService:FindEntitiesByBlueprintInRadius( entity, "buildings/main/rift_magnetic_stabilizer_alien" , radius )
		
		local workingStabilizators = 0
		
		for entity in Iter(magneticStabilizer) do			
			if BuildingService:IsWorking( entity ) then
				workingStabilizators = workingStabilizators + 1;
			end
		end	
			
		for entity in Iter(alienStabilizer) do			
			if BuildingService:IsWorking( entity ) then
				workingStabilizators = workingStabilizators + alienFactor;
			end
		end	
		
		if ( workingStabilizators < stabilizerCount ) then
			--LogService:Log( "Missing stabilizers!!" )
			return false;
		end	
	

		return true
end

function GetWorkingStabilizatorsCount( entity, radius, alienFactor )
		local magneticStabilizer = FindService:FindEntitiesByBlueprintInRadius( entity, "buildings/main/rift_magnetic_stabilizer", radius )
		local alienStabilizer    = FindService:FindEntitiesByBlueprintInRadius( entity, "buildings/main/rift_magnetic_stabilizer_alien" , radius )
		
		local workingStabilizators = 0
		
		for entity in Iter(magneticStabilizer) do			
			if BuildingService:IsWorking( entity ) then
				workingStabilizators = workingStabilizators + 1;
			end
		end	
			
		for entity in Iter(alienStabilizer) do			
			if BuildingService:IsWorking( entity ) then
				workingStabilizators = workingStabilizators + alienFactor;
			end
		end	
		
		return workingStabilizators
end

EVENT_SHOW_BUILDING_DISPLAY_RADIUS = "ShowBuildingDisplayRadius"
EVENT_HIDE_BUILDING_DISPLAY_RADIUS = "HideBuildingDisplayRadius"

function ShowBuildingDisplayRadiusAround( sender, entityOrBlueprint )
	local database = EntityService:GetBlueprintDatabase(entityOrBlueprint);
    if database then
        QueueEvent("LuaGlobalEvent", sender, EVENT_SHOW_BUILDING_DISPLAY_RADIUS, { display_radius_group = database:GetStringOrDefault("display_radius_group", tostring(entityOrBlueprint)) } );
        return true
    end

	return false
end

function HideBuildingDisplayRadiusAround( sender, entityOrBlueprint )
	local database = EntityService:GetBlueprintDatabase(entityOrBlueprint);
    if database then
        QueueEvent("LuaGlobalEvent", sender, EVENT_HIDE_BUILDING_DISPLAY_RADIUS, { display_radius_group = database:GetStringOrDefault("display_radius_group", tostring(entityOrBlueprint)) } );
		return true
    end
	return false
end

function GetBuildingDisplayRadius( entity )
	local database = EntityService:GetBlueprintDatabase(entity);
	if database ~= nil then
		for key in Iter({ "heal_radius", "range", "radius", "drone_search_radius" }) do
			if database:HasFloat( key ) then
				return 0, database:GetFloat( key )
			end
		end
	end

	local turretComponent = EntityService:GetComponent(entity, "TurretComponent")
	if turretComponent ~= nil then
		local component = reflection_helper(turretComponent)
		local aim_volume = component.turret_desc.aim_volume;

		return aim_volume.range_min, aim_volume.range_max
	end

	local resourceComponent = EntityService:GetComponent(entity, "ResourceConverterComponent")
	if resourceComponent ~= nil then
		local component = reflection_helper(resourceComponent)
		local resources_radius = component.resources_radius;
		if resources_radius.count > 0 then
			return resources_radius[1].value
		end
	end

	local blueprintName = EntityService:GetBlueprintName( entity )
	local blueprint = ResourceManager:GetBlueprint( blueprintName )
	if blueprint ~= nil then
		local turretComponent = blueprint:GetComponent("TurretDesc")
		if turretComponent ~= nil then
			local component = reflection_helper(turretComponent)
			local aim_volume = component.aim_volume;

			return aim_volume.range_min, aim_volume.range_max
		end
	end

	return nil, nil
end

function SetupBuildingScale( entity, database )
	local scaleMin = database:GetFloatOrDefault( "min_scale", 1 )
	local scaleMax = database:GetFloatOrDefault( "max_scale", 1 )
	local x = scaleMin + math.random() * ( scaleMax - scaleMin )
	EntityService:SetScale( entity, x, x, x )
	EntityService:SetPhysicsScale( entity, x, x, x )
	EntityService:SetNavMeshScale( entity, x, x, x )
	local children = EntityService:GetChildren(entity, true)
	for child in Iter(children) do
		EntityService:SetPhysicsScale( child, x, x, x )
	end

	database:SetFloat( "uniform_scale", x );
end