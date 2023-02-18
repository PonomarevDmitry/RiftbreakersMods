class 'wave_ground' ( LuaGraphNode )
require( "lua/utils/table_utils.lua")
require( "lua/utils/numeric_utils.lua")


function wave_ground:__init()
    LuaGraphNode.__init(self, self)	
end

function wave_ground:init()
	self.spawnGroups = 
	{
		"spawn_enemy_border_east",
		"spawn_enemy_border_west",
		"spawn_enemy_border_south",
		"spawn_enemy_border_north",
	}
	
	self.spawnDirections = 
	{
		"spawn_direction_1",
		"spawn_direction_2",
		"spawn_direction_3",
		"spawn_direction_4",		
	}
	while #self.spawnGroups > 0 do
		local randomNumber = RandInt( 1, #self.spawnGroups )
		local spawnPointName = self.spawnGroups[randomNumber]
		self.data:SetString( self.spawnDirections[randomNumber], spawnPointName )	
		table.remove(self.spawnGroups, randomNumber)
		table.remove(self.spawnDirections, randomNumber)		
	end	
end

function wave_ground:SpawnWaveIndicator(spawnPoint)
	--LogService:Log( "SpawnWaveIndicator" )	
	--local spawnPoint = self.data:GetString( "spawn_point" )	
	local indicatorID = EntityService:SpawnEntity( "effects/messages_and_markers/wave_marker", spawnPoint, "no_team" )
	local indicatorDuration = self.data:GetIntOrDefault("spawn_indicator_duration", 45)	
	EntityService:CreateLifeTime( indicatorID, indicatorDuration, "normal" )
end

function wave_ground:SelectRandomBorderSpawnpoint()
	local spawn_groups = 
	{
		"spawn_enemy_border_east",
		"spawn_enemy_border_west",
		"spawn_enemy_border_south",
		"spawn_enemy_border_north",
	}

	local spawn_points = {}
	for group in Iter(spawn_groups) do 
		local entities = FindService:FindEntitiesByGroup( group );
		for entity in Iter(entities) do
			table.insert(spawn_points, entity)
		end
	end

	if #spawn_points == 0 then
		return INVALID_ID
	end

	return spawn_points[ RandInt( 1, #spawn_points ) ];
end

function wave_ground:SelectSpawnPoint()	
    local wave_start_point = INVALID_ID;
	local spawnDirection = self.data:GetStringOrDefault( "spawn_direction", "" )
	

    if self.spawn_point ~= "" then
        wave_start_point = FindService:FindEntityByName( self.spawn_point );
    end

    if wave_start_point == INVALID_ID and self.spawn_group ~= "" then
        local entities = FindService:FindEntitiesByGroup( self.spawn_group );
        if Assert( #entities > 0, "ERROR: not entities for group: " .. self.spawn_group ) then
        	wave_start_point = entities[ RandInt( 1, #entities ) ]
		end
    end
	
	if wave_start_point == INVALID_ID and spawnDirection ~= "" then		
		local entities = FindService:FindEntitiesByGroup( self.data:GetString( spawnDirection ) );
        if Assert( #entities > 0, "ERROR: not entities for direction: " .. spawnDirection ) then
        	wave_start_point = entities[ RandInt( 1, #entities ) ]
		end
    end

	local targetSpawnName = self.data:GetStringOrDefault( "target_name", "" )
	if wave_start_point == INVALID_ID and targetSpawnName ~= "" then	
		local min = nil
		
		local target = FindService:FindEntityByName( targetSpawnName )
		if Assert( target ~= INVALID_ID, "ERROR: No target entity found with name: " .. targetSpawnName ) then
			local targetPos = EntityService:GetPosition( target ) 
			local spawnGroups = 
			{
				"spawn_enemy_border_east",
				"spawn_enemy_border_west",
				"spawn_enemy_border_south",
				"spawn_enemy_border_north",
			}

			for group in Iter(spawnGroups ) do 
				local entities = FindService:FindEntitiesByGroup( group );

				for ent in Iter(entities) do
					local currentPos = EntityService:GetPosition( ent ) 
					local dist = Distance( currentPos, targetPos )
					if ( min == nil or min > dist ) then
						min = dist
						wave_start_point = ent
					end
				end
			end
		end
	end
	
    if wave_start_point == INVALID_ID and self.data:GetIntOrDefault("random_spawn", 0) then
        wave_start_point = self:SelectRandomBorderSpawnpoint()
    end

    if not Assert(wave_start_point ~= INVALID_ID, "ERROR: spawn point NOT found for: " .. self.spawn_point .. " / " .. self.spawn_group ) then
		wave_start_point = self:SelectRandomBorderSpawnpoint()
	end

	if wave_start_point == INVALID_ID then
		return wave_start_point
	end

	if self.data:GetIntOrDefault("spawn_indicator", 0) == 1 then
		self:SpawnWaveIndicator(wave_start_point)	
	end
	
    return wave_start_point;
end

--function wave_ground:Activated()
    --self:SpawnWaveIndicator(self.spawn_entity)	
--end

return wave_ground