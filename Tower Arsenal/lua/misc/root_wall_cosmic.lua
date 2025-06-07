class 'root_wall_cosmic' ( LuaEntityObject )

function root_wall_cosmic:__init()
	LuaEntityObject.__init(self,self)
end

function root_wall_cosmic:init()

	self.originToStopAboveGroundHeight = self.data:GetFloatOrDefault( "origin_to_stop_above_ground_height", 0.0 )
	self.lifeTime = self.data:GetFloatOrDefault( "life_time", 10.0 )
	self.acceleration = self.data:GetFloatOrDefault( "speed_acceleration", 15.0 )

	self.sm = self:CreateStateMachine()
	self.sm:AddState( "wait", { enter="OnWaitEnter", exit="OnWaitExit" } )
	self.sm:AddState( "move", { enter="OnMoveEnter", execute="OnMoveExecute" } )
	self.sm:AddState( "remove", { enter="OnRemoveEnter", exit="OnRemoveExit" } )
	self.sm:ChangeState( "wait" )

	self.angle = RandInt( 0, 360 );
	self.currentSpeed = 0
	self.onTrigger = false

	EntityService:SetOrientation( self.entity, 0.0, 1.0, 0.0, self.angle );
end

function root_wall_cosmic:OnWaitEnter( state )

	local min = 0.0
	local max = 0.4
	local duration = min + math.random() * ( max - min )

	state:SetDurationLimit( duration )
end

function root_wall_cosmic:OnWaitExit( state )
	self.sm:ChangeState( "move" )
end

function root_wall_cosmic:OnMoveEnter( state )
	self.position = EntityService:GetPosition( self.entity )
end

function root_wall_cosmic:OnMoveExecute( state, dt )

	self.currentSpeed = self.currentSpeed +( self.acceleration * dt );
	EntityService:SetPosition( self.entity, self.position.x, self.position.y  + ( ( self.currentSpeed * self.currentSpeed ) * dt ), self.position.z )

	self.position = EntityService:GetPosition( self.entity )

	if ( self.position.y > self.originToStopAboveGroundHeight ) then
		self.sm:ChangeState( "remove" )
	end

	-- remove this later
	if ( self.onTrigger == false ) and ( self.position.y > ( self.originToStopAboveGroundHeight - 3.0 ) ) then 
		
		local rocksCount = RandInt( 5, 10)
		for i =1,rocksCount do
			local ent = ItemService:SpawnLoot( self.entity, "units/ground/drexolian/wall_debris", 30.0, 6000, 12000, "normal" )
			EffectService:AttachEffect( ent, "effects/destructibles/tree_leafs_destruction_big_gold" )
			EntityService:DissolveEntity( ent, 1.0, 3.0 )
		end
		
		self.onTrigger = true
	end

end

function root_wall_cosmic:OnRemoveEnter( state )
	state:SetDurationLimit( self.lifeTime )
end

function root_wall_cosmic:OnRemoveExit( state )
	EntityService:DissolveEntity( self.entity, 1.0 )
end


return root_wall_cosmic
 