require ( "lua/utils/table_utils.lua" )
require ( "lua/utils/numeric_utils.lua" )
class 'spreader' ( LuaEntityObject )

function spreader:__init()
	LuaEntityObject.__init(self,self)
end

function spreader:UpdateRootsCount( value )
	local roots = _G["roots_count"] or 0
	_G["roots_count"] = roots + value
end

function spreader:CanSpawnRoot( )
	local roots = _G["roots_count"] or 0
	return roots < 1000
end

function spreader:init()	
	self.version = 1
	self.blueprint = self.data:GetString( "blueprint");
	self.root_blueprint = self.data:GetStringOrDefault( "root_blueprint",  EntityService:GetBlueprintName( self.entity ));
	self.min_spread = self.data:GetFloatOrDefault( "min_spread_interval", 0.1 );
	
	self.ancestor = self.data:GetIntOrDefault("ancestor", self.entity )
	self.max_radius = self.data:GetFloatOrDefault( "spread_radius", 50);
	self.grow_size = 2;
	self.type = self.data:GetStringOrDefault("collision_detection", "vegetation" );
	self.spread_interval = self.data:GetFloatOrDefault( "spread_interval", 1);
	if ( self.ancestor == self.entity ) then
		self.spread_interval = self.spread_interval * RandFloat(0.75,1.25)
	end
	self.spread_interval = math.max( self.spread_interval,self.min_spread)
	self.spread_root_interval = self.data:GetFloatOrDefault( "spread_root_interval", 30);
	self.spread_child_interval_multiplier = self.data:GetFloatOrDefault( "spread_child_interval_multiplier", 1 );
	self.initial_spread = self.data:GetFloatOrDefault( "initial_spread", 0);
	self.min_root_spawn_chance = self.data:GetFloatOrDefault( "min_root_spawn_chance", 0.25);
	self.max_branch_interval = self.data:GetFloatOrDefault( "max_branch_interval", 1 );
	self.collapse_interval = self.data:GetFloatOrDefault( "collapse_interval", 1 );
	self.stop_on_remove = self.data:GetStringOrDefault("stop_component", "BurningComponent" );
	self.terrainExclude = self.data:GetStringOrDefault("terrain_exclude", "acid_floor");
	self.currentIdx = 1

	self.branches = {};
	self.root_chance = 0.5;
	self.toBaseChance = 0.9;
	self.childGroup = "##creeper_root##"

	self.machine = self:CreateStateMachine();
	self.machine:AddState( "spreader", { execute="OnSpreadExecute", interval=self.spread_interval  } );
	self.machine:AddState( "collapse", { execute="OnCollapseExecute", interval=self.collapse_interval  } );
	
	if ( self.initial_spread > 0 ) then
		local spots = FindService:FindEmptySpotsInRadius(  self.entity, 0, self.initial_spread, self.type, self.terrainExclude )
		for position in Iter( spots )
		do
			self:SpawnBlueprint( self.blueprint, position, false )
		end
	end	

	self.machine:ChangeState( "spreader" );
	
	self:RegisterHandler( self.entity, "DestroyRequest", "OnDestroyRequest" );
	self:RegisterHandler( self.entity, "EntityScanningEndEvent", "OnEntityScanningEndEvent" );
	self:RegisterHandler( self.entity, "EntityScanningStartEvent", "OnEntityScanningStartEvent" );
	self.burningComponent  = EntityService:GetComponentId( self.stop_on_remove );
	self.spots = FindService:GetSpotsInRadius( self.entity, 0, self.max_radius )
	
	self.scanning = false;
	self.ancestorAlive = EntityService:IsAlive(self.ancestor) and (EntityService:GetDatabase(self.ancestor):GetIntOrDefault( "alive", 1) == 1 ) 
	self:UpdateRootsCount(1)
end

local function RandPosition( position )
	position.x = position.x + RandFloat( -0.5, 0.5)
	position.z = position.z + RandFloat( -0.5, 0.5)
	return position
end

function spreader:ClearFloors( spawned, position )
	local size = EntityService:GetBoundsSize( spawned )
	size = VectorMul(size, { x=0.5, y=0.5, z=0.5 })
    self.predicate = self.predicate or {
        signature="BuildingComponent",
        filter = function(entity)
			local buildingType = BuildingService:GetBuildingType(entity)
			local terrainType = EnvironmentService:GetTerrainTypeUnderEntity( entity )
			return  buildingType == "floor" and terrainType ~= "acid_floor"
        end
    };

	local entities = FindService:FindEntitiesByPredicateInBox( VectorSub(position,size), VectorAdd(position, size), self.predicate )
	for ent in Iter(entities) do
		EntityService:DissolveEntity( ent, 1.0 )
		local children = EntityService:GetChildren( ent, false )
		for child in Iter(children) do
			EntityService:DissolveEntity( child, 1.0 )
		end
	end
end

function spreader:SpawnBlueprint( bp, position, resetDatabase )
	local spawned = EntityService:SpawnEntity( bp, RandPosition(position), EntityService:GetTeam( "enemy") );
	self:ClearFloors(spawned, position)

	if (resetDatabase == true ) then
		local database = EntityService:GetDatabase( spawned );
		if ( database ~= nil ) then
			database:SetFloat( "spread_interval", math.max( math.min( self.spread_interval * self.spread_child_interval_multiplier, self.max_branch_interval )  , self.min_spread ) );
			database:SetFloat( "initial_spread", 0  );
			database:SetFloat( "max_branch_interval", self.max_branch_interval  );
			database:SetInt( "ancestor", self.ancestor  );
		end
	else
		Insert( self.branches, spawned )
		self:RegisterHandler( spawned, "DestroyRequest", "OnChildDestroyRequest" )
	end
	local toDestroy = FindService:FindEntitiesByTypeInRadius( spawned, "prop", 1.5 )
	for prop in Iter( toDestroy )
	do
		QueueEvent( "DamageRequest", prop, HealthService:GetMaxHealth(prop), "creeper", 0, 0 )
	end
	
	EntityService:FadeEntity( spawned, DD_FADE_IN, 1.0 )
	EffectService:AttachEffects(spawned, "spawn")
	EntityService:Rotate( spawned, 0, 1, 0, RandFloat( 0, 360) );
	EntityService:RemoveTypesInEntityBounds( spawned, "prop" )
	return spawned 
end

function spreader:Spread( state )
	if ( self.scanning == true ) then
		self.data:SetInt("scanning",1)
		return
	end
	self.data:SetInt("scanning",0)

	if self.currentIdx > #self.spots then
		self.currentIdx = 1
	end

	if #self.spots == 0 then
		self.spots = FindService:GetSpotsInRadius( self.entity, 0, self.max_radius )
		self.currentIdx = 1

		if #self.spots == 0 then
			return
		end
	end

	local blocked = false
	for i=self.currentIdx,#self.spots 
	do
		blocked = BuildingService:IsSpaceOccupied( self.spots[i], self.type, self.terrainExclude ) or FindService:IsGridMarkedWithLayer( self.spots[i], "SpreaderCullerLayerComponent")
		if ( blocked == false ) then
			self.currentIdx = i
			break
		end
	end

	local ancestorAlive = (EntityService:IsAlive(self.ancestor) and (EntityService:GetDatabase(self.ancestor):GetIntOrDefault( "alive", 1) == 1 )) or self.ancestor == -1   
	if ( blocked == false and ancestorAlive == true ) then
		self:SpawnBlueprint( self.blueprint, self.spots[self.currentIdx], false );		
		state:SetUpdateInterval( self.spread_interval * RandFloat(0.75,1.25) );
	else
		if (self.ancestorAlive == true ) then
			self.ancestorAlive = ancestorAlive
			if ( self.ancestorAlive == false ) then
				self.machine:ChangeState("collapse");
				self.currentIdx = 1
			else
				if ( self.ancestor == -1 ) then
					self.currentIdx = 1
					return
				end
				if ( not self:CanSpawnRoot()) then
					return
				end
				local spawn_root = RandFloat( 0, 1 )
				
				if ( spawn_root < self.root_chance ) then
					--local found = FindService:FindEmptySpotInRadius( self.entity, self.max_radius + self.grow_size , self.type , self.terrainExclude );
					local spots = {}

					local testSpots = FindService:FindEmptySpotsInRadius(  self.entity, 0,  self.max_radius + self.grow_size, self.type, self.terrainExclude, 0.0, 0.0, 3 )
					for spot in Iter( testSpots ) do
						if not FindService:IsGridMarkedWithLayer( spot, "SpreaderCullerLayerComponent") then
							table.insert(spots, spot)
						end
					end

					local exists = #spots ~= 0;
					if ( state ~= nil ) then
						state:SetUpdateInterval( self.spread_root_interval * RandFloat(0.75,1.25) );
					end
					if ( exists == true ) then
						
						local selectedSpot = spots[RandInt(1,#spots)]
						-- Found buildings selecting nearest spot:
						if ( self.ancestor ~= self.entity ) then
							local toBase = RandFloat( 0, 1 )
							
							if (  toBase < self.toBaseChance ) then
								
								local found = FindService:FindNearestBuilding( self.entity )
								
								if ( found.first ~= INVALID_ID ) then
									local distance = nil;

									for position in Iter(spots) do
										local nearbyRoot = FindService:FindEntityByGroupInDistanceFromPos( position, self.childGroup, (self.max_radius / 3.0) * 2.0 )
										
										if ( nearbyRoot == INVALID_ID ) then
											local newDistance = Distance( position, found.second) 

											if ( distance == nil or newDistance < distance ) then
												selectedSpot = position
												distance = newDistance
											end
										end
									end
								end
							end
						end

						local nearbyRoot = FindService:FindEntityByGroupInDistanceFromPos( selectedSpot, self.childGroup, (self.max_radius / 3.0) * 2.0 )
						if ( nearbyRoot == INVALID_ID ) then
							local root = self:SpawnBlueprint( self.root_blueprint, selectedSpot, true );
							EntityService:SetGroup(root, self.childGroup)
							self.root_chance = math.max( self.root_chance / 2, self.min_root_spawn_chance );
						end
					else 
						self.currentIdx = 1
					end
				end;
			end			
		end
	end
	
end

function spreader:OnCollapseExecute( state )
	for i=#self.branches,1,-1 do
		
		local toDestroy = self.branches[ i ];
		Remove(self.branches, toDestroy);

		if ( EntityService:IsAlive( toDestroy ) and HealthService:IsAlive( toDestroy )  ) then
			EntityService:DissolveEntity( toDestroy, 1 )
			break
		end
	end

	if ( #self.branches == 0 ) then
		EntityService:DissolveEntity(self.entity, 1 )
		state:Exit();
		return;
	end
end

function spreader:OnSpreadExecute( state )
	self:Spread( state );
	
	if ( EntityService:GetComponent( self.entity, "BurningComponent" ) ~= nil) then
		self.machine:ChangeState("collapse");
		self.data:SetInt( "alive", 0 );
		EntityService:RemoveComponent( self.entity, "TeamComponent" )
	end

end

function spreader:OnComponentRemovedEvent( evt ) -- must be here for old saves files, do not remove!
end

function spreader:OnDestroyRequest( evt )
	EntityService:RemoveComponent( self.entity, "TeamComponent" )
	self.data:SetInt( "alive", 0 );
	local cleaner = EntityService:SpawnEntity( "units/ground/creeper_cleaner", self.entity, "" );
	local data = EntityService:GetDatabase(cleaner)
	for i=1,#self.branches do
		data:SetInt( "branch_" .. tostring(i), self.branches[i])
	end
	data:SetFloat( "collapse_interval" , self.collapse_interval )
	
	EntityService:RevealVegetation( self.entity )
	EntityService:DissolveEntity(self.entity, 1)
end

function spreader:OnEntityScanningEndEvent( evt )
	self.scanning = false;
end

function spreader:OnEntityScanningStartEvent( evt )
	self.scanning = true;
end

function spreader:OnChildDestroyRequest( evt )
	self.currentIdx = 1;
	local child = evt:GetEntity();
	Remove(self.branches, child)
	if ( EntityService:IsAlive( child ) and EntityService:GetType(child) == "ground_unit" ) then
		EntityService:RemoveComponent( child, "TypeComponent" )
		EntityService:ChangeType( child, "prop" )
		EntityService:RemoveComponent( child, "TeamComponent" )
	end	
	EntityService:DissolveEntity( child, 1.0, 15.0 )
	if ( EntityService:GetComponent( child, "VegetationComponent") == nil) then
		EntityService:RequestDestroyPattern( child, "default")
	end

	EntityService:RevealVegetation( child )
	self:UnregisterHandler( child, "DestroyRequest", "OnChildDestroyRequest" )
end

function spreader:OnLoad()
	self:UpdateRootsCount(1)
	if ( self.version == nil or self.version < 1 ) then
		self.spots = FindService:GetSpotsInRadius( self.entity, 0, self.max_radius )
		self.version = 1
	end
	self.predicate = nil
	self.min_spread = self.min_spread or self.data:GetFloatOrDefault( "min_spread_interval", 0.05 );
	
end

function spreader:OnRelease()
	self:UpdateRootsCount(-1)
end

return spreader