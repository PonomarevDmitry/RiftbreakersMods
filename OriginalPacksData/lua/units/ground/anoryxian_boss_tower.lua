require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'anoryxian_boss_tower' ( base_unit )

function anoryxian_boss_tower:__init()
	base_unit.__init(self, self)
end

function anoryxian_boss_tower:OnInit()	
	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )
	self:RegisterHandler( self.entity, "StopShootEvent",  "OnStopShootEvent" )
	self:RegisterHandler( self.entity, "ChargeAttackStartEvent",  "OnChargeAttackStartEvent" )
	self:RegisterHandler( self.entity, "ChargeAttackEndEvent",  "OnChargeAttackEndEvent" )	

	self.wreck_type = "wreck_small"
	self.wreckMinSpeed = 0

	self.data:SetInt( "is_unhiding", 1 )
	--EntityService:SetVisible( self.entity, false );

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function anoryxian_boss_tower:OnShootEvent( evt )
	WeaponService:StartShoot( self.entity )
end

function anoryxian_boss_tower:OnStopShootEvent( evt )
	WeaponService:StopShoot( self.entity )
end

function anoryxian_boss_tower:OnChargeAttackStartEvent( evt )
	EffectService:AttachEffects( self.entity, "laser_pointer" )	
end

function anoryxian_boss_tower:OnChargeAttackEndEvent( evt )
	EffectService:DestroyEffectsByGroup( self.entity, "laser_pointer" )
end

return anoryxian_boss_tower
