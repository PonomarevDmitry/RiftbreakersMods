local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_pulse_wave' ( base_skill )

function skill_pulse_wave:__init()
	base_skill.__init(self, self)
end

function skill_pulse_wave:OnInit()
	self.waveBp			    = self.data:GetString( "wave_bp" )
	self.warningBp			= self.data:GetStringOrDefault( "warning_bp", "error" )
	self.waveSpawnEffect	= self.data:GetStringOrDefault( "wave_spawn_effect", "error" )
	self.spawnAttachment	= self.data:GetStringOrDefault( "spawn_attachment", "error" )
	self.spawnMinTime	    = self.data:GetFloat( "spawn_min_time" )
	self.spawnMaxTime	    = self.data:GetFloat( "spawn_max_time" )
	self.speed				= self.data:GetFloat( "speed" )
	self.warningTime		= self.data:GetFloatOrDefault( "warning_time", 0.0 )	
	self.elementsCount	    = self.data:GetInt( "elements_count" )	
	self.radius				= self.data:GetInt( "radius" )	
	self.angle				= self.data:GetInt( "angle" )	
	self.spread				= self.data:GetIntOrDefault( "spread", 0 )
	

    self.spawner = self:CreateStateMachine()
	self.spawner:AddState( "spawn_pulse", { execute="OnExecuteSpawnPulse" } )
    self.spawner:AddState( "spawn_warning", { execute="OnExecuteSpawnWarning" } )

	self:SetSpawnTime()

	self.warningEnt = INVALID_ID
	self.warningTimer = self.warningTime

	self.additionalHeight = 2.0
end

function skill_pulse_wave:SetSpawnTime()
	self.spawnTimer = RandFloat( self.spawnMinTime, self.spawnMaxTime );
end

function skill_pulse_wave:OnExecuteSpawnWarning( state, dt )
	self.spawnTimer = self.spawnTimer - dt

	if ( self.spawnTimer <= 0.0 ) then

		if ( self.currentTarget ~= INVALID_ID ) then

			if ( self.warningBp ~= "error" ) then
				self.warningEnt = WeaponService:SpawnDangerMarker( self.warningBp, { x = 0.0, y = 0.0, z = 0.0 } , self.radius / 2.0, self.warningTime )			
				EntityService:AttachEntity( self.warningEnt, self.entity )

				local db = EntityService:GetDatabase( self.warningEnt  )
				db:SetFloat( "override_angle", self.angle )
			end

			self.warningTimer = self.warningTime

			self.spawner:ChangeState( "spawn_pulse" )
		end
	end
end

function skill_pulse_wave:CreateOnSpawnEffect( parent )
	if ( self.waveSpawnEffect ~= "error" ) then
		if ( EntityService:HasBone( parent, self.spawnAttachment ) == true ) then
			EntityService:SpawnAndAttachEntity( self.waveSpawnEffect, parent, self.spawnAttachment, "" )
		else
			EntityService:SpawnAndAttachEntity( self.waveSpawnEffect, parent )
		end
	end
end

function skill_pulse_wave:OnExecuteSpawnPulse( state, dt )
	self.warningTimer = self.warningTimer - dt

	local parent = EntityService:GetParent( self.entity )

	if ( self.warningTimer <= 0.0 ) then

		if ( self.currentTarget ~= INVALID_ID ) then
						
			local myOrigin = {}
			
			if ( EntityService:HasBone( parent, self.spawnAttachment ) == true ) then
				myOrigin = EntityService:GetPosition( parent, self.spawnAttachment )
			else
				myOrigin = EntityService:GetPosition( self.entity )
			end

			local targetOrigin = EntityService:GetPosition( self.currentTarget )

			local dir = VectorSub( targetOrigin, myOrigin )
			dir = Normalize( dir )

			local forwardAngle = math.atan2( dir.z, dir.x )
			local halfConeAngle = math.rad( self.angle / 2 ) 

			local velocity = UnitService:GetCurrentVelocity( parent )
			velocity = VectorMulByNumber( velocity, 0.3 )

			local originForward = VectorAdd( myOrigin, velocity )

			self:CreateOnSpawnEffect( parent )

			for i = 1, self.elementsCount do

				local randomOffset = math.rad( RandInt( 0, self.spread ) ) * ( RandInt( 0, 1 ) * 2 - 1 )		

				local angle = forwardAngle + halfConeAngle * ( ( i - 1 ) / ( self.elementsCount - 1 ) * 2 - 1 ) + randomOffset

				local origin = {}

				origin.x = originForward.x + self.radius * math.cos( angle )

				if ( EntityService:HasBone( parent, self.spawnAttachment ) == false ) then
					origin.y = self.additionalHeight
				else
					origin.y = myOrigin.y
				end

				origin.z = originForward.z + self.radius * math.sin( angle )

				local waveEntity = WeaponService:ShootEntityOnTargetOrigin( originForward, parent, origin.x, origin.y, origin.z, self.speed, "", self.waveBp )
					
				if ( waveEntity ~= INVALID_ID ) then
					EntityService:SetTeam( waveEntity, EntityService:GetTeam( self.entity ) )

					if ( EntityService:GetComponent( waveEntity ,"LifeTimeComponent") == nil ) then				
						EntityService:CreateOrSetLifetime( waveEntity, self.radius / self.speed, "normal" )
					end
				end
			
			end

			self.spawner:ChangeState( "spawn_warning" )
			self:SetSpawnTime()	
		end			
	end

end

function skill_pulse_wave:OnUnitAggressiveStateEvent( evt )
	self.spawner:ChangeState( "spawn_warning" )
	self:CleanWarning()
end

function skill_pulse_wave:CleanWarning()
	if ( self.warningEnt ~= INVALID_ID ) then
		EntityService:RemoveEntity( self.warningEnt )
		self.warningEnt = INVALID_ID
	end
end

function skill_pulse_wave:OnUnitNotAggressiveStateEvent( evt )
	local state  = self.spawner:GetState( self.spawner:GetCurrentState() )
	if( state ~= nil ) then
		state:Exit()
	end
end

function skill_pulse_wave:OnUnitDeadStateEvent( evt )
	self:CleanWarning()
	EntityService:RemoveEntity( self.entity )
end

return skill_pulse_wave