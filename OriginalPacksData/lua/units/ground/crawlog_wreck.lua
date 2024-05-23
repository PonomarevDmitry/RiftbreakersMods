local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'crawlog_wreck' ( wreck_ground_unit )

function crawlog_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function crawlog_wreck:initParams()
	if ( UnitService:IsOnHeightGround( self.entity ) == true ) then
		self.normalExplodeProbability = 1
		self.leaveBodyProbability = 0
	else
		self.normalExplodeProbability = 2
		self.leaveBodyProbability = 10
	end

	self.resurrect = self:CreateStateMachine()
	self.resurrect:AddState( "resurrect", { enter="OnEnterResurrect", exit= "OnExitResurrect" } )
	self.resurrect:AddState( "start_grow_crystal", { execute="OnExecuteStartGrowCrystal" } )
	self.resurrect:AddState( "spawn_crystal", { enter="OnEnterSpawnCrystal" } )

	local ressurectRoll = math.random( 1, 100 )

	if ( ( self.data:HasString( "resurrect_bp" ) ) and ( ressurectRoll <= self.data:GetFloatOrDefault( "resurrect_chance", 100 ) ) ) then
		EntityService:RemoveComponent( self.entity, "WreckTeamComponent" );
		self.resurrect:ChangeState( "resurrect" )
	end

	self.resurrectState = "resurrect_1"
	self.canResurrect = false
end

function crawlog_wreck:OnEnterResurrect( state )
	EntityService:RemoveComponent( self.entity,"UniformComponent" );
	HealthService:SetHealth( self.entity, 5 )
	EntityService:CreateComponent( self.entity,"DeadStateComponent" );
	local time = math.random( self.data:GetFloat( "resurrect_min_time" ), self.data:GetFloat( "resurrect_max_time" ) )
	state:SetDurationLimit( time )
end

function crawlog_wreck:OnExitResurrect( state )

	if ( self.canResurrect == true ) then
		EntityService:RemoveComponent( self.entity, "PhysicsComponent" )
		local entity = EntityService:SpawnEntity( self.data:GetString( "resurrect_bp" ), self.entity, "wave_enemy" )
		UnitService:SetInitialState( entity, UNIT_RESSURECT );
		EntityService:SetVisible( entity, false );

		EffectService:AttachEffects( entity, "resurrect"  )
		local data = EntityService:GetBlueprintDatabase( self.entity )
		local scaleMin = data:GetFloatOrDefault( "min_scale", 1.0 )
		local scaleMax = data:GetFloatOrDefault( "max_scale", 1.0 )

		local db = EntityService:GetDatabase( entity )

		db:SetString( "resurrect_name", self.resurrectState )

		db:SetFloat( "min_scale", scaleMin )
		db:SetFloat( "max_scale", scaleMax )

		db:SetInt( "is_resurrecting", 1 )

		EntityService:DissolveEntity( self.entity, 0.1 )
	end
end

function crawlog_wreck:_OnDestroyRequest( state )
    EntityService:RequestDestroyPattern( self.entity, "resurrect" )
end

function crawlog_wreck:_OnAnimationStateChanged( evt )
    local stateName = evt:GetNewStateName() 
    
	if ( stateName == "death_1" ) then
		self.resurrectState = "resurrect_1"
		self.canResurrect = true
	elseif ( stateName == "death_2" ) then
		self.resurrectState = "resurrect_2"
		self.canResurrect = true
	elseif ( stateName == "death_running_1" ) then
		self.resurrectState = "resurrect_running_1"
		self.canResurrect = true
	elseif ( stateName == "death_running_2" ) then
		self.resurrectState = "resurrect_running_2"
		self.canResurrect = true
	end
end

return crawlog_wreck