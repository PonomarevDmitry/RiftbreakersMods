class 'slash' ( LuaEntityObject )

function slash:__init()
	LuaEntityObject.__init(self,self)
end

function slash:init()
	self.duration = self.data:GetFloatOrDefault( "duration", 1.0 )
	self.range = self.data:GetFloatOrDefault( "range", 1.0 )
	self.parent = self.data:GetIntOrDefault( "parent", INVALID_ID )

	self.range = self.range * 0.9
	self.duration = self.duration * 1.75

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "working", { enter="OnEnter", execute="OnExecute", exit="OnExit" } )
	self.fsm:ChangeState( "working" )

	self:SetProgress( 0.0 )
end

function slash:SetProgress( progress )
	if progress < 0.25 then
		scale = 0.9 * math.sin( ( 4.0 * progress ) * ( 3.14 / 2.0 ) )
		EntityService:SetScale( self.entity, self.range * scale, scale, scale )
	else
		scale = 0.9 + 0.1 * ( ( progress - 0.25 ) / 0.75 )
		EntityService:SetScale( self.entity, self.range * scale, scale, scale )
	end

	EntityService:SetGraphicsUniform( self.entity, "cTime", progress )
	local children =  EntityService:GetChildren( self.entity, false )
	for child in Iter(children) do
		EntityService:SetGraphicsUniform( child, "cTime", progress )
	end
end

function slash:OnEnter( state )
	state:SetDurationLimit( self.duration )

	EntityService:CreateOrSetLifetime( self.entity, self.duration, "normal" )

	local speed = ( self.range * 0.25 ) / self.duration
	local forward = EntityService:GetForward( self.entity )
	MoveService:MoveInDirection( self.entity, speed, speed, 0.0, forward )
end

function slash:OnExecute( state, dt )
	local duration = state:GetDuration()
	local progress = duration / self.duration
	self:SetProgress( progress )

	if self.parent ~= INVALID_ID then 
		if EntityService:IsAlive( self.parent ) then 
			local pos = EntityService:GetPosition( self.parent )
			EntityService:SetPosition( self.entity, pos.x, pos.y, pos.z )
		end
	end
end

function slash:OnExit( state )

end

return slash
 