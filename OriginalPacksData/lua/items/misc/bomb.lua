class 'bomb' ( LuaEntityObject )

function bomb:__init()
	LuaEntityObject.__init(self,self)
end

function bomb:init()

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "rotation", { enter="OnRotationEnter", execute="OnRotationExecute" } )

	local height = self.data:GetFloatOrDefault( "height_increase", 2.0 )
	if height > 0.0 then
		local pos = EntityService:GetPosition( self.entity )
		pos.y = pos.y + height
		EntityService:SetPosition( self.entity, pos.x, pos.y, pos.z )
		self.fsm:ChangeState( "rotation" )
	end

	AnimationService:StartAnim( self.entity, "show", false )
	local animTime = AnimationService:GetAnimDuration( self.entity, "show" );
	EntityService:FadeEntity( self.entity, DD_FADE_IN, animTime / 2.0 )
end

function bomb:OnRotationEnter( state, dt )
	self.randomDir = { x=RandFloat( 0.0, 1.0 ), y=0, z=RandFloat( 0.0, 1.0 ) }
	self.randomDir = Normalize( self.randomDir )
end

function bomb:OnRotationExecute( state, dt )
	EntityService:Rotate( self.entity, self.randomDir.x, self.randomDir.y, self.randomDir.z, 7 )
end

return bomb
