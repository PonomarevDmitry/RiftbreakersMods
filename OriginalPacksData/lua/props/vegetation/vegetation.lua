require("lua/utils/numeric_utils.lua")

class 'vegetation' ( LuaEntityObject )

function vegetation:__init()
	LuaEntityObject.__init(self,self)
end

function vegetation:init()	
    self:RegisterHandler( self.entity, "TargetHasChangedEvent", "OnTargetHasChangedEvent" )
	self:RegisterHandler( self.entity, "AnimationMarkerReached", "OnAnimationMarkerReached" )
	self:RegisterHandler( self.entity, "AttachEffectGroupRequest", "OnAttachEffectGroupRequest" )

	self.isBurned = false;
	
	self.currDir = { x=1, y=0, z=0 }
	local db = EntityService:GetDatabase( self.entity )
	db:SetVector( "target_pos", self.currDir )

	self:UpdateState( INVALID_ID )
end

function vegetation:UpdateState( target )
	if self.isBurned then 
		return
	end
	self.target = target
	local db = EntityService:GetDatabase( self.entity )
	local isInverted = db:GetIntOrDefault( "inverted", 0 ) == 1
	local hasTarget = self.target ~= INVALID_ID
	if ( isInverted and hasTarget ) or ( not isInverted and not hasTarget ) then
		EffectService:DestroyEffectsByGroup( self.entity, "visible" )
		EffectService:AttachEffects( self.entity, "hidden" )
		db:SetInt( "is_visible", 0 )
		if db:GetIntOrDefault( "immortal_on_hide", 0 ) ~= 0  then 
			EntityService:DisableCollisions( self.entity );
			HealthService:SetImmortality( self.entity, true );
		end	
	else
		EffectService:DestroyEffectsByGroup( self.entity, "hidden" )
		EffectService:AttachEffects( self.entity, "visible" )
		db:SetInt( "is_visible", 1 )
		if db:GetIntOrDefault( "immortal_on_hide", 0 ) ~= 0  then 
			EntityService:EnableCollisions( self.entity );
			HealthService:SetImmortality( self.entity, false );
		end
	end

	if db:GetIntOrDefault( "target_aiming", 0 ) ~= 0 then 
		if self.target ~= INVALID_ID then
			if ( self.fsm == nil ) then
				self.fsm = self:CreateStateMachine()
				self.fsm:AddState( "aiming", { from="*", execute="OnAimingExecute" } )
				self.fsm:ChangeState( "aiming" )
				db:SetInt( "is_aiming", 1 )
			end
		else
			self:DisableStateMachine()
		end
	end
end

function vegetation:DisableStateMachine()
	if ( self.fsm ~= nil ) then
		self:DestroyStateMachine( self.fsm )
		self.fsm = nil
	end
end

function vegetation:SetBurningState()
	self:DisableStateMachine()
	EntityService:RemoveComponent( self.entity, "AnimationGraphComponent" );
	self.isBurned = true
end

function vegetation:OnAimingExecute( state, dt )
	if self.target ~= INVALID_ID and self.target ~= self.entity  then
		local db = EntityService:GetDatabase( self.entity )
		local dir = EntityService:GetLocalDirTo( self.entity, self.target )
		self.currDir = EntityService:LerpTwoDirections( self.currDir, dir, 90.0, dt )
		db:SetVector( "target_pos", self.currDir )
	end
end

function vegetation:OnTargetHasChangedEvent( evt )
	self:UpdateState( evt:GetTarget() )
end

function vegetation:OnAttachEffectGroupRequest( evt )
	if evt:GetGroup() == CalcHash("time_damage_fire") then
		self:SetBurningState()
	end
end

function vegetation:OnDestroyRequest( evt )
	local db = EntityService:GetDatabase( self.entity )
	if ( self.isBurned ) then
		if ( db:GetIntOrDefault( "is_visible", 1 ) == 1 ) then
			EntityService:RequestDestroyPattern( self.entity, "burned" )
		else
			EntityService:RequestDestroyPattern( self.entity, "hidden_burned" )
		end
	else
		if ( db:GetIntOrDefault( "is_visible", 1 ) == 1 ) then
			EntityService:RequestDestroyPattern( self.entity, "default" )
		else
			EntityService:RequestDestroyPattern( self.entity, "hidden" )
		end
	end
end

function vegetation:OnAnimationMarkerReached( evt )
	EffectService:AttachEffects( self.entity, evt:GetMarkerName() )
end

return vegetation
