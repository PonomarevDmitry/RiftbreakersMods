class 'root_wall' ( LuaEntityObject )

function root_wall:__init()
	LuaEntityObject.__init(self,self)
end

function root_wall:init()

	self.originToStopAboveGroundHeight = self.data:GetFloatOrDefault( "origin_to_stop_above_ground_height", 0.0 )
	self.lifeTime = self.data:GetFloatOrDefault( "life_time", 10.0 )
	self.acceleration = self.data:GetFloatOrDefault( "speed_acceleration", 15.0 )
	self.dynamicSpace = self.data:GetIntOrDefault( "dynamic_space", 0 )

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

function root_wall:OnLoad()
	self.freeSpace = self.data:GetFloatOrDefault( "free_space", 0 )
end

function root_wall:OnWaitEnter( state )

	local min = 0.0
	local max = 0.4
	local duration = min + math.random() * ( max - min )

	state:SetDurationLimit( duration )
end

function root_wall:OnWaitExit( state )
	self.sm:ChangeState( "move" )
end

function root_wall:OnMoveEnter( state )
	self.position = EntityService:GetPosition( self.entity )
end

function root_wall:OnMoveExecute( state, dt )

	self.currentSpeed = self.currentSpeed +( self.acceleration * dt );
	EntityService:SetPosition( self.entity, self.position.x, self.position.y  + ( ( self.currentSpeed * self.currentSpeed ) * dt ), self.position.z )

	self.position = EntityService:GetPosition( self.entity )

	if ( self.position.y > self.originToStopAboveGroundHeight ) then
		self.sm:ChangeState( "remove" )
	end

	-- remove this later
	if ( self.onTrigger == false ) and ( self.position.y > ( self.originToStopAboveGroundHeight - 3.0 ) ) then 
		
		EntityService:RequestDestroyPattern( self.entity, "waller", false )

		self.onTrigger = true

		if ( self.dynamicSpace == 1 ) then

			EntityService:SpawnEntity( "units/ground/drexolian/wall_explosion", self.entity, "enemy" )			
			EntityService:RemoveEntity( self.entity )
		end
	end

end

function root_wall:OnRemoveEnter( state )
	state:SetDurationLimit( self.lifeTime )
end

function root_wall:OnRemoveExit( state )
	EntityService:DissolveEntity( self.entity, 1.0 )
end


return root_wall
 