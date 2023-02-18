class 'underground_rock' ( LuaEntityObject )

function underground_rock:__init()
	LuaEntityObject.__init(self,self)
end

function underground_rock:init()

	self.damageBp = self.data:GetString( "damage_bp" )
	self.originToStopAboveGroundHeight = self.data:GetFloatOrDefault( "origin_to_stop_above_ground_height", 2.0 )
	self.acceleration = self.data:GetFloatOrDefault( "speed_acceleration", 10.0 )

	self.sm = self:CreateStateMachine()
	self.sm:AddState( "move", { enter="OnMoveEnter", execute="OnMoveExecute" } )
	self.sm:AddState( "remove", { enter="OnRemoveEnter" } )
	self.sm:ChangeState( "move" )

	self.angle = RandInt( 0, 360 );
	self.currentSpeed = 0
	self.onTrigger = false

	EntityService:SetOrientation( self.entity, 0.0, 1.0, 0.0, self.angle );
end

function underground_rock:OnMoveEnter( state )
	self.position = EntityService:GetPosition( self.entity )
end

function underground_rock:OnMoveExecute( state, dt )

	self.currentSpeed = self.currentSpeed +( self.acceleration * dt );
	EntityService:SetPosition( self.entity, self.position.x, self.position.y  + ( ( self.currentSpeed * self.currentSpeed ) * dt ), self.position.z )

	self.position = EntityService:GetPosition( self.entity )

	if ( self.position.y > self.originToStopAboveGroundHeight ) then
		self.sm:ChangeState( "remove" )
	end

	if ( self.onTrigger == false ) and ( self.position.y > ( self.originToStopAboveGroundHeight - 3.0 ) ) then 
		EntityService:SpawnEntity( self.damageBp, self.entity, EntityService:GetTeam( self.entity ) )
		
		local rocksCount = RandInt( 5, 10)
		for i =1,rocksCount do
			local ent = ItemService:SpawnLoot( self.entity, "units/ground/gnerot/gnerot_rock_debris", 30.0, 6000, 12000, "normal" )
			EffectService:AttachEffect( ent, "effects/enemies_generic/blood_trail_dust" )
			EntityService:DissolveEntity( ent, 1.0, 3.0 )
		end
		self.onTrigger = true
	end

end

function underground_rock:OnRemoveEnter( state )	
	EntityService:DissolveEntity( self.entity, 1.0 )
end

return underground_rock
 