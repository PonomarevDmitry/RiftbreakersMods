
local loot_spawner = require( "lua/spawners/loot_spawner.lua")

class 'resource_spawner' ( loot_spawner )

function resource_spawner:__init()
	loot_spawner.__init(self,self)
end

function resource_spawner:init()
	local target_entity = self.entity
	local target_blueprint = "resources/volume_template_resource"

	if self.data:HasInt( "volume_entity" ) then
		target_entity = self.data:GetInt("volume_entity")
		target_blueprint = ""
	end

	local resource_name = self.data:GetString( "resource" )

	local is_infinite = self.data:GetStringOrDefault( "is_infinite", "0" )
	if is_infinite ~= "1" then
		local volume_amount_min = math.floor(self.data:GetFloatOrDefault( "min_resources", 0.0 ));
		local volume_amount_max = math.floor(self.data:GetFloatOrDefault( "max_resources", 0.0 ));
		
		ResourceService:SpawnResources( target_entity, target_blueprint, resource_name, volume_amount_min, volume_amount_max )
	else
		ResourceService:SpawnResourcesInfinite( target_entity, target_blueprint, resource_name  )
	end
	
	if self.data:HasString("blueprint") then
		loot_spawner.SpawnLoot( self )
	end
	
	if target_entity ~= self.entity then
		EntityService:RemoveEntity( self.entity )
	end
end

return resource_spawner
