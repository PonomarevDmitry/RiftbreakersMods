class 'meteor_shower' ( LuaEntityObject )

function meteor_shower:__init()
	LuaEntityObject.__init(self, self)
end

function meteor_shower:init()
	self.meteorBp			= self.data:GetString( "meteor_blueprint" )
	self.type				= self.data:GetString( "type" )
	self.warningBp		    = self.data:GetString( "warning_bp" )
	self.duration			= self.data:GetInt( "duration" )
	self.spawnTime			= self.data:GetFloat( "spawn_time" )
	self.delay				= self.data:GetFloat( "delay" )
	self.radius				= self.data:GetInt( "radius" )
	self.meteorsInOneSpawn	= self.data:GetInt( "meteors_in_one_spawn" )
	self.speed				= self.data:GetFloatOrDefault( "speed", 140 )
	self.spread				= self.data:GetFloatOrDefault( "spread", 15 )

	self.timeBound = 4.0
	self.currentTime = 0

	self.interpolationFactor = 1
	self.timer = self.duration

    self.spawner = self:CreateStateMachine()
    self.spawner:AddState( "spawn", { enter="OnEnterSpawn", exit= "OnExitSpawn" } )
	self.spawner:ChangeState( "spawn" )

    self.interpolation = self:CreateStateMachine()
    self.interpolation:AddState( "interpolation", { execute="OnEecuteInterpolation" } )
	self.interpolation:ChangeState( "interpolation" )
end

function meteor_shower:OnLoad()
	self.speed				= self.data:GetFloatOrDefault( "speed", 140 )
	self.spread				= self.data:GetFloatOrDefault( "spread", 15 )
end

function meteor_shower:OnEecuteInterpolation( state, dt )

	self.timer = self.timer - dt
	self.currentTime = self.currentTime + dt

	if ( self.timer < 0  ) then
		self.timer = 0
	end

    local timeLeft = self.timer;
    local timePassed = self.duration - timeLeft;

    if ( timeLeft < self.timeBound ) then
        self.interpolationFactor = 1 - ( timeLeft / self.timeBound ); 
    end

    if ( timePassed < self.timeBound ) then
        self.interpolationFactor = 1 - ( timePassed / self.timeBound );
    end

	if ( self.interpolationFactor > 1 ) then
		self.interpolationFactor = 1
	end

	if ( self.interpolationFactor < 0 ) then
		self.interpolationFactor = 0
	end

end

function meteor_shower:OnEnterSpawn( state )
	state:SetDurationLimit( self.spawnTime + self.interpolationFactor )

	for i = 1, self.meteorsInOneSpawn, 1 do 
		if ( self.type == METEOR_SPAWN_IN_PLACE ) then
			MeteorService:SpawnMeteorInRadius( self.entity, self.meteorBp, self.radius, 50, self.speed, self.spread, self.delay, self.warningBp )
		elseif ( self.type == METEOR_FOLLOW_PLAYER ) then
			
			local player = PlayerService:GetPlayerControlledEnt( 0 )

			if ( player ~= INVALID_ID ) then
				MeteorService:SpawnMeteorInRadius( player, self.meteorBp, self.radius, 50, self.speed, self.spread, self.delay, self.warningBp )
			else
				MeteorService:SpawnMeteorInRadius( CameraService:GetActiveCamera(), self.meteorBp, self.radius, 50, self.speed, self.spread, self.delay, self.warningBp )
			end

		end
	end

end

function meteor_shower:OnExitSpawn( state )

	if ( self.currentTime > self.duration  ) then
		EntityService:RemoveEntity( self.entity ) 
	else
		self.spawner:ChangeState( "spawn" )
	end
end

return meteor_shower