require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'necrodon' ( base_unit )

function necrodon:__init()
	base_unit.__init(self, self)
end

function necrodon:OnInit()
	self:RegisterHandler( self.entity, "FinishResurrectEvent",  "OnFinishResurrectEvent" )
	self:RegisterHandler( self.entity, "StartLeechEvent",  "OnStartLeechEvent" )
	self:RegisterHandler( self.entity, "EndLeechEvent",  "OnEndLeechEvent" )
	
	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4

	self.resurrectEffect = false; 
	self.currentLeechTarget = INVALID_ID
	self.leechDmg = 0

	self.leechFSM = self:CreateStateMachine()
	self.leechFSM:AddState( "start_leech", { execute="OnLeechExecute" } )
	self.leechFSM:AddState( "stop_leech", {  } )
end

function necrodon:OnFinishResurrectEvent( evt )
	
	if ( self.resurrectEffect == true ) then
		EffectService:DestroyEffectsByGroup( self.entity, "resurrect_effect"  )
		self.resurrectEffect = false
	end

end

function necrodon:OnLeechExecute( state, dt )
	if ( self.currentLeechTarget ~= INVALID_ID ) then
		QueueEvent( "DamageRequest", self.currentLeechTarget, self.leechDmg * dt, "energy", 1, 0 )
	end
end

function necrodon:OnStartLeechEvent( evt )
	local target = UnitService:GetCurrentTarget( evt:GetEntity(), evt:GetTargetTag() )

	if ( ( target ~= self.currentLeechTarget ) and ( self.currentLeechTarget ~= INVALID_ID ) ) then

		if ( EffectService:HasEffectByGroup( self.currentLeechTarget, "leech" ) == true ) then
			EffectService:DestroyEffectsByGroup( self.currentLeechTarget, "leech" )
		end

	end

	self.currentLeechTarget = target
	self.leechDmg = evt:GetLeechDamage()

	if ( self.currentLeechTarget ~= INVALID_ID ) then
		if ( EffectService:HasEffectByGroup( self.currentLeechTarget, "leech" ) == false ) then
			EffectService:AttachEffects( self.currentLeechTarget, "leech" )

		self.leechFSM:ChangeState( "start_leech" )
		end
	end
end

function necrodon:OnEndLeechEvent( evt )
	if ( EffectService:HasEffectByGroup( self.currentLeechTarget, "leech" ) == true ) then
		EffectService:DestroyEffectsByGroup( self.currentLeechTarget, "leech" )
	end

	self.leechFSM:ChangeState( "stop_leech" )
end

function necrodon:OnAnimationStateChanged( evt )
	local stateName = evt:GetNewStateName() 
	if ( stateName == "resurrect_loop" ) then
		EffectService:AttachEffects( self.entity, "resurrect_effect"  )
		self.resurrectEffect = true
	end
end

return necrodon
