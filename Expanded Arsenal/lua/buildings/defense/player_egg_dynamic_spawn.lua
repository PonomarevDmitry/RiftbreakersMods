require("lua/utils/table_utils.lua")
require("lua/units/units_utils.lua")

class 'player_egg_dynamic_spawn' ( LuaEntityObject )

function player_egg_dynamic_spawn:__init()
	LuaEntityObject.__init(self, self)
end

function player_egg_dynamic_spawn:init()
	
	self.bp = self.data:GetStringOrDefault("spawn_bp", "")
	self.bp_count = self.data:GetIntOrDefault("spawn_amount", 1)
	self.minForce = self.data:GetFloatOrDefault("min_dynamic_force", 1500 )
	self.maxForce = self.data:GetFloatOrDefault("max_dynamic_force", 2500 )
	
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "Spawn", { enter="OnSpawnEnter", exit="OnSpawnExit"} )
	self.fsm:ChangeState( "Spawn" )
end

function player_egg_dynamic_spawn:OnSpawnEnter( state )
	
	local origin = EntityService:GetPosition( self.entity )

	for i = 1, self.bp_count do            
		local object_bp = EntityService:SpawnEntity( self.bp, origin.x, origin.y, origin.z, "" )
		EntityService:SetTeam( object_bp, "player")
		EntityService:PhysicsSleepNotify( object_bp, true )
		UnitService:AddDynamicForce( object_bp, self.minForce, self.maxForce )
	end
end

function player_egg_dynamic_spawn:OnSpawnExit( state )
	EntityService:RemoveEntity( self.entity )
end

return player_egg_dynamic_spawn