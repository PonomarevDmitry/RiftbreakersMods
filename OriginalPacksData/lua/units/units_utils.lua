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
end