require ("lua/utils/table_utils.lua")
function SetupUnitScale( entity, database )
	local scaleMin = database:GetFloatOrDefault( "min_scale", 0.9 )
	local scaleMax = database:GetFloatOrDefault( "max_scale", 1.1 )
	local x = scaleMin + math.random() * ( scaleMax - scaleMin )
	EntityService:SetScale( entity, x, x, x )
	EntityService:SetPhysicsScale( entity, x, x, x )
	EntityService:SetNavMeshScale( entity, x, x, x )
	local children = EntityService:GetChildren(entity, true)
	for child in Iter(children) do
		EntityService:SetPhysicsScale( child, x, x, x )
	end

    QueueEvent("NetClearEntityComponentStateRequest", entity, "TransformComponent")
end

function SetupComponentFieldOverrides(entity, database)
    local biome_name = MissionService:GetCurrentBiomeName()
    if g_debug_change_biome_for_skill_overrides ~= "" then
        biome_name = g_debug_change_biome_for_skill_overrides
    end

    local key = "biome_override." .. biome_name
    if database:HasString( key ) then
        local spawner_component = EntityService:GetComponent( entity, "UnitsSpawnerComponent")
        if spawner_component ~= nil then
            spawner_component:GetField("blueprint"):SetValue( database:GetString( key ) )
        end

        local resurrect_component = EntityService:GetComponent( entity, "ResurrectUnitComponent")
        if resurrect_component ~= nil then
            resurrect_component:GetField("summon_bp"):SetValue( database:GetString( key ) )
        end
    end
end
