require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'drexolian' ( base_unit )

function drexolian:__init()
	base_unit.__init(self, self)
end

function drexolian:OnInit()
	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )

	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function drexolian:OnShootEvent( evt )
	WeaponService:ShootOnce( self.entity )
end

return drexolian
