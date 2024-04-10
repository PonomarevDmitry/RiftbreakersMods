class 'tower_lightning_spike_projectile' ( LuaEntityObject )

function tower_lightning_spike_projectile:__init()
	LuaEntityObject.__init(self,self)
end

function tower_lightning_spike_projectile:init()
	local pos = EntityService:GetPosition( self.entity )
	pos.y = math.min( 10.0, pos.y + 10 )
    EntityService:SetPosition( self.entity, pos.x, pos.y, pos.z )
	QueueEvent( "FadeEntityInRequest", self.entity, 1)
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "falling", { execute="OnFallingExecute" } )
	self.fsm:ChangeState( "falling" )
end

function tower_lightning_spike_projectile:OnFallingExecute( state )
	local downDir = { x=0, y=-1, z=0 }
	MoveService:MoveInDirection( self.entity, 0, 30, 30, downDir )
end

return tower_lightning_spike_projectile
