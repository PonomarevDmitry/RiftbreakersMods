require("lua/items/item.lua")
require("lua/units/units_utils.lua")

class 'player_egg_static_spawn' ( LuaEntityObject )

function player_egg_static_spawn:__init()
    LuaEntityObject.__init(self, self)
end

function player_egg_static_spawn:init()

    self.spawn_bp  = self.data:GetStringOrDefault("spawn_bp", "items/consumables/sentry_gun" )
	self.bp_count = self.data:GetIntOrDefault("spawn_count", 1 )
    self.timeout = self.data:GetFloatOrDefault("timeout", 10 )
    self.min_radius = self.data:GetFloatOrDefault("min_radius", 0 )
    self.max_radius = self.data:GetFloatOrDefault("max_radius", 5 )
	
	self.lifeTimeFSM = self:CreateStateMachine()
	self.lifeTimeFSM:AddState( "life_time", { execute="OnLifeTimeExecute" } )
    self:SpawnEntity()
end

function player_egg_static_spawn:SpawnEntity()

    local result = FindService:FindEmptySpotInRadius( self.entity, self.min_radius, self.max_radius, "", "")
	local blueprints = Split( self.spawn_bp, "," )
	local SpawnIdx = 0;
	
    if result.first then
        local position = result.second
		for i=1,self.bp_count do
			local CEP = RandFloat( -4.0, 4.0 )
			local new_position = { x = ( position.x + CEP ), y = position.y, z = ( position.z + CEP ) }
			local EntityToSpawn = blueprints[( SpawnIdx %#blueprints ) + 1]
			self.spawned_entity = EntityService:SpawnEntity( EntityToSpawn, new_position.x, new_position.y, new_position.z, "player" )
			SpawnIdx = SpawnIdx + 1
			EntityService:CreateLifeTime( self.spawned_entity, self.timeout, "" )
			self.lifeTimeFSM:ChangeState( "life_time" )
		end
	else
		ConsoleService:Write("Entity deployment failed.")
    end
end

function player_egg_static_spawn:OnLifeTimeExecute( state )

    local lifetime = EntityService:GetLifeTime( self.spawned_entity )
    if (lifetime <= 0.1) then
        EntityService:RequestDestroyPattern( self.spawned_entity , "default", true )
    end
end

return player_egg_static_spawn