class 'tower_gravity_portal_bomb' ( LuaEntityObject )

function tower_gravity_portal_bomb:__init()
	LuaEntityObject.__init(self,self)
end

function tower_gravity_portal_bomb:init()
	local pos = EntityService:GetPosition( self.entity )
	pos.y = math.min( 10.0, pos.y + 10 )
    EntityService:SetPosition( self.entity, pos.x, pos.y, pos.z )
	AnimationService:StartAnim( self.entity, "show_bomb", false )
	local animTime = AnimationService:GetAnimDuration( self.entity, "show_bomb" );
	EntityService:FadeEntity( self.entity, DD_FADE_IN, animTime )

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "working", { enter="OnEnter", execute="OnExecute", exit="OnExit" } )
	self.fsm:AddState( "falling", { execute="OnFallingExecute" } )
	self.fsm:ChangeState( "working" )
end

function tower_gravity_portal_bomb:OnEnter( state )
	self.portalEnergy = EntityService:SpawnAndAttachEntity( "buildings/defense/tower_gravity_portal_triangle", self.entity )
    EntityService:SetPosition( self.portalEnergy, 0, -1, 0 )
    EntityService:SetScale( self.portalEnergy, 0.33, 0.33, 0.33 )
	AnimationService:StartAnim( self.portalEnergy, "show_portal", false, 1.5 )
	self.randomDir = { x=RandFloat( 0.0, 1.0 ), y=0, z=RandFloat( 0.0, 1.0 ) }
	self.randomDir = Normalize( self.randomDir )
end

function tower_gravity_portal_bomb:OnExecute( state, dt )
    if not AnimationService:IsAnimActive( self.portalEnergy, "show_portal" ) then
    	local downDir = { x=0, y=-1, z=0 }
		MoveService:MoveInDirection( self.entity, 0, 30, 30, downDir )
		self.fsm:ChangeState( "falling" )
    end
end

function tower_gravity_portal_bomb:OnExit( state )
	AnimationService:StartAnim( self.portalEnergy, "hide_portal", false, 4.0 )
	local animTime = AnimationService:GetAnimDuration( self.portalEnergy, "hide_portal" );
	EntityService:DissolveEntity( self.portalEnergy, animTime / 4.0 )
end

function tower_gravity_portal_bomb:OnFallingExecute( state, dt )
	EntityService:Rotate( self.entity, self.randomDir.x, self.randomDir.y, self.randomDir.z, 7 )
end

return tower_gravity_portal_bomb
