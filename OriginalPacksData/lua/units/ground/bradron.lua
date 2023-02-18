require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'bradron' ( base_unit )

function bradron:__init()
	base_unit.__init(self, self)
end

function bradron:OnInit()
	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )
	self:RegisterHandler( self.entity, "StopShootEvent",  "OnStopShootEvent" )
	self:RegisterHandler( self.entity, "ChargeAttackStartEvent",  "OnChargeAttackStartEvent" )
	self:RegisterHandler( self.entity, "ChargeAttackEndEvent",  "OnChargeAttackEndEvent" )	

	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function bradron:OnShootEvent( evt )
	WeaponService:StartShoot( self.entity )
end

function bradron:OnStopShootEvent( evt )
	WeaponService:StopShoot( self.entity )
end

function bradron:OnChargeAttackStartEvent( evt )
	EffectService:AttachEffects( self.entity, "laser_pointer" )	
end

function bradron:OnChargeAttackEndEvent( evt )
	EffectService:DestroyEffectsByGroup( self.entity, "laser_pointer" )
end

return bradron
