class 'canoptrix_anim' ( LuaEntityObject )

function canoptrix_anim:__init()
	LuaEntityObject.__init(self,self)
end

function canoptrix_anim:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "idle", { from="*", execute="UpdateIdle" } )
	self.fsm:AddState( "run", { from="*", execute="UpdateRun" } )
	self.fsm:AddState( "attack", { from="*", execute="UpdateAttack" } )

	LogService:Log( "canoptrix_anim:init()" )
	self.fsm:ChangeState( "idle" )	

end

function canoptrix_anim:OnEnter( state )	
	LogService:Log( "canoptrix_anim:enter" )
end

function canoptrix_anim:UpdateRun( state, dt )
	AnimationService:ResetPose( self.entity );
	local animTime = state:GetDuration() % AnimationService:GetAnimDuration(self.entity, "walk1");
	local speed = self.data:GetFloat( "speed" );
	local anim_weight = speed / 6.0;
	anim_weight = math.min( anim_weight, 1.0 );
	AnimationService:AddAnim( self.entity, "walk1", animTime, 1.0 - anim_weight );
	AnimationService:AddAnim( self.entity, "walk2", animTime, anim_weight );

	if  speed == 0 then
		self.fsm:ChangeState( "idle" )
	end
end

function canoptrix_anim:UpdateAttack( state, dt )
	AnimationService:ResetPose( self.entity );
	local animTime = state:GetDuration() % AnimationService:GetAnimDuration(self.entity, "attack1");
	local is_attacking = self.data:GetInt( "is_attacking" );
	AnimationService:AddAnim( self.entity, "attack1", animTime, 1.0 );

	if  is_attacking == 0 then
		self.fsm:ChangeState( "idle" )
	end
end


function canoptrix_anim:UpdateIdle( state, dt )
	AnimationService:ResetPose( self.entity );
	local animTime = state:GetDuration() % AnimationService:GetAnimDuration(self.entity, "idle");
	local speed = self.data:GetFloat( "speed" );
	local is_attacking = self.data:GetInt( "is_attacking" );
	AnimationService:AddAnim( self.entity, "idle", animTime, 1.0 );

	if  is_attacking == 1 then
		self.fsm:ChangeState( "attack" )
	end 
	if  speed > 0.1 then
		self.fsm:ChangeState( "run" )
	end
end

function canoptrix_anim:OnExit( state )	
	LogService:Log( "canoptrix_anim:enter" )
end

return canoptrix_anim
