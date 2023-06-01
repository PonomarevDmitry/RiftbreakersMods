class 'wave_ground' ( LuaGraphNode )
require( "lua/utils/table_utils.lua")
require( "lua/utils/numeric_utils.lua")
require( "lua/utils/find_utils.lua")

local SURVIVAL_BORDER_GROUPS = 
{
	"spawn_enemy_border_east",
	"spawn_enemy_border_west",
	"spawn_enemy_border_south",
	"spawn_enemy_border_north",
}

local FIND_TYPE_RANDOM_BORDER 	= "RandomBorder"
local FIND_TYPE_CLOSEST_BORDER 	= "ClosestBorder"
local FIND_TYPE_DIRECTION 		= "Direction"
local FIND_TYPE_CREATE_DYNAMIC 	= "CreateDynamic"

function wave_ground:__init()
    LuaGraphNode.__init(self, self)	
end

function wave_ground:init()
	local spawnGroups = Copy(SURVIVAL_BORDER_GROUPS)

	local spawnDirections = 
	{
		"spawn_direction_1",
		"spawn_direction_2",
		"spawn_direction_3",
		"spawn_direction_4",		
	}

	while #spawnGroups > 0 do
		local randomNumber = RandInt( 1, #spawnGroups )
		local spawnPointName = spawnGroups[randomNumber]
		self.data:SetString( spawnDirections[randomNumber], spawnPointName )	
		table.remove(spawnGroups, randomNumber)
		table.remove(spawnDirections, randomNumber)		
	end	
end

function wave_ground:SpawnWaveIndicator(spawnPoint)
	local indicatorID = EntityService:SpawnEntity( "effects/messages_and_markers/wave_marker", spawnPoint, "no_team" )
	local indicatorDuration = self.data:GetIntOrDefault("spawn_indicator_duration", 45)	
	EntityService:CreateLifeTime( indicatorID, indicatorDuration, "normal" )
end

function wave_ground:SelectSpawnPoint()
	local spawn_type = self.data:GetStringOrDefault( "spawn_type", FIND_TYPE_NAME )
	local spawn_direction = self.data:GetStringOrDefault( "spawn_direction", "" )
	local spawn_target_name = self.data:GetStringOrDefault( "target_name", "" )
	local spawn_target_type = self.data:GetStringOrDefault( "target_type", FIND_TYPE_NAME )
	local spawn_target_max_radius = self.data:GetFloatOrDefault( "search_radius", 0.0 )
	local spawn_target_min_radius = self.data:GetFloatOrDefault( "search_min_radius", 0.0 )
	local spawn_count = self.data:GetIntOrDefault( "search_count", 1 )

	if spawn_type == FIND_TYPE_NAME and self.spawn_point == "" then
		if self.spawn_group ~= "" then
			spawn_type = FIND_TYPE_GROUP
			self.spawn_point = self.spawn_group
		elseif spawn_direction ~= "" then
			spawn_type = FIND_TYPE_GROUP
			self.spawn_point = self.data:GetString( spawn_direction )
		elseif self.data:GetIntOrDefault("random_spawn", 0) == 1 then
			spawn_type = FIND_TYPE_RANDOM_BORDER
		elseif spawn_target_name ~= "" then
			spawn_type = FIND_TYPE_CLOSEST_BORDER
		end
	end

	if spawn_type == FIND_TYPE_DIRECTION then
		spawn_type = FIND_TYPE_GROUP
		self.spawn_point = self.data:GetString( self.spawn_point )
	elseif spawn_type == FIND_TYPE_RANDOM_BORDER then
		spawn_type = FIND_TYPE_GROUP
		self.spawn_point = SURVIVAL_BORDER_GROUPS[ RandInt(1, #SURVIVAL_BORDER_GROUPS) ]
	end

	Assert(spawn_type ~= "", "ERROR: invalid spawn_type: '" .. spawn_type .. "'");

	local entities = {}
	if spawn_type == FIND_TYPE_CREATE_DYNAMIC then
		local target = FindEntities( spawn_target_type, spawn_target_name )
		if Assert( #target > 0, "ERROR: failed to find target: " .. spawn_target_type .. "=" .. spawn_target_name .. " for wave: '" .. self.self_id .. "'" ) then
			entities = UnitService:CreateDynamicSpawnPoints( target[1], spawn_target_min_radius, spawn_target_max_radius, spawn_count )
		end
	elseif spawn_type == FIND_TYPE_CLOSEST_BORDER then
		local selector = { distance = nil, group_name = ""}
		for group_name in Iter(SURVIVAL_BORDER_GROUPS) do
			local border_entities, targets = FindEntitiesByTarget(FIND_TYPE_GROUP, group_name, spawn_target_min_radius, spawn_target_max_radius, spawn_target_type, spawn_target_name)
			if #targets > 0 then
				for i=1,spawn_count do
					local result = FindClosestEntityWithDistance(targets[1], border_entities)
					if result.entity ~= INVALID_ID and selector.group_name ~= group_name then
						if selector.distance == nil or selector.distance > result.distance then
							selector.distance = result.distance
							selector.group_name = group_name
							entities = {};
						end
					end

					if selector.group_name == group_name then
						table.remove(border_entities, result.entity)
						table.insert(entities, result.entity)
					end
				end
			end
		end
	else
		entities = FindEntitiesByTarget(spawn_type, self.spawn_point, spawn_target_min_radius, spawn_target_max_radius, spawn_target_type, spawn_target_name)
	end

	local selected = {}
	for i=1,spawn_count do
		if #entities > 0 then
			local index = RandInt(1, #entities)
			table.insert( selected, entities[index] )
			table.remove( entities, index)
		end
	end

	if self.data:GetIntOrDefault("spawn_indicator", 0) == 1 then
		for entity in Iter(selected) do
			self:SpawnWaveIndicator(entity)
		end
	end

	if Assert( #selected > 0, "ERROR: failed to find spawnpoints with: " .. spawn_type .. "=" .. self.spawn_point  .. " for wave: '" .. self.self_id .. "'") then
    	return selected;
	else
		return {}
	end
end

return wave_ground