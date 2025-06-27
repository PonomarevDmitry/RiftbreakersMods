local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'gulgor_wreck' ( wreck_ground_unit )

function gulgor_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function gulgor_wreck:initParams()
	self.spawner = self:CreateStateMachine()
	self.spawner:AddState( "wait", { enter="OnEnterWait", exit= "OnExitWait" } )
	self.spawner:AddState( "start_grow_crystal", { execute="OnExecuteStartGrowCrystal" } )
	self.spawner:AddState( "spawn_crystal", { enter="OnEnterSpawnCrystal" } )
	self.spawner:ChangeState( "wait" )

	self.growCrystalScale = 0.0
	self.crystalGrowSpeed = self.data:GetFloatOrDefault( "crystal_grow_speed", 1 )

	self.origin = EntityService:GetPosition( self.entity )

	self.growCrystal = EntityService:SpawnEntity( self.data:GetStringOrDefault( "crystal_grow_bp", "units/ground/gulgor/grow_crystal" ), self.origin.x, self.origin.y, self.origin.z, "none" )
	EntityService:SetScale( self.growCrystal, 0.01, 0.01, 0.01 )
end

function gulgor_wreck:OnEnterWait( state )
	state:SetDurationLimit( 0.3 )
end

function gulgor_wreck:OnExitWait( state )
	self.spawner:ChangeState( "start_grow_crystal" )
end

function gulgor_wreck:OnExecuteStartGrowCrystal( state, dt )
	if ( self.growCrystalScale >= 1.0 ) then
		self.spawner:ChangeState( "spawn_crystal" )
	else
		self.growCrystalScale = self.growCrystalScale + ( ( 1.0 / self.crystalGrowSpeed ) * dt )
		EntityService:SetScale( self.growCrystal, self.growCrystalScale, self.growCrystalScale, self.growCrystalScale )
	end
end

function gulgor_wreck:OnEnterSpawnCrystal( state )
	local meshName = EntityService:GetMeshName( self.growCrystal )

	EntityService:RemoveEntity( self.growCrystal )

	local entity =  EntityService:SpawnEntity( self.data:GetStringOrDefault( "crystal_bp", "units/ground/gulgor/crystal" ), self.origin.x, self.origin.y, self.origin.z, "none" )
	EntityService:ChangeMesh( entity, meshName )
	EntityService:ChangeMaterial( entity, "units/ground/gulgor_crystal" )
end

return gulgor_wreck