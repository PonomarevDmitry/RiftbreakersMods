require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'necrodon' ( base_unit )

function necrodon:__init()
	base_unit.__init(self, self)
end

function necrodon:OnInit()
	self:RegisterHandler( self.entity, "FinishResurrectEvent",  "OnFinishResurrectEvent" )
	self:RegisterHandler( self.entity, "FinishSummonEvent",  "OnFinishSummonEvent" )
	
	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )
	self:RegisterHandler( self.entity, "StopShootEvent",  "OnStopShootEvent" )
	self:RegisterHandler( self.entity, "ChargeAttackStartEvent",  "OnChargeAttackStartEvent" )
	self:RegisterHandler( self.entity, "ChargeAttackEndEvent",  "OnChargeAttackEndEvent" )	

	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4

	self.resurrectEffect = false;
	self.summonEffect = false; 

	UnitService:SetStateMachineParam( self.entity, "corpses_target_valid", 0 )

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function necrodon:OnShootEvent( evt )
	WeaponService:StartShoot( self.entity )
end

function necrodon:OnStopShootEvent( evt )
	WeaponService:StopShoot( self.entity )
end

function necrodon:OnChargeAttackStartEvent( evt )
	EffectService:AttachEffects( self.entity, "laser_pointer" )	
end

function necrodon:OnChargeAttackEndEvent( evt )
	EffectService:DestroyEffectsByGroup( self.entity, "laser_pointer" )
end

function necrodon:OnFinishResurrectEvent( evt )
	
	if ( self.resurrectEffect == true ) then
		EffectService:DestroyEffectsByGroup( self.entity, "resurrect_effect"  )
		self.resurrectEffect = false
	end

end

function necrodon:OnFinishSummonEvent( evt )
	
	if ( self.summonEffect == true ) then
		EffectService:DestroyEffectsByGroup( self.entity, "summon_effect"  )
		self.summonEffect = false
	end

end


function necrodon:OnAnimationStateChanged( evt )
	local stateName = evt:GetNewStateName() 
	if ( stateName == "resurrect_loop" ) then
		EffectService:AttachEffects( self.entity, "resurrect_effect"  )
		self.resurrectEffect = true
	elseif ( stateName == "summon_loop" ) then
		EffectService:AttachEffects( self.entity, "summon_effect"  )
		self.summonEffect = true
	end
end

return necrodon
