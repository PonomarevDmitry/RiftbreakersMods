require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'carnicinth' ( base_unit )

function carnicinth:__init()
	base_unit.__init(self, self)
end

function carnicinth:OnInit()	
	
	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )

	self.wreck_type = "wreck_small"
	self.wreckMinSpeed = 10

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function carnicinth:OnShootEvent( evt )

	WeaponService:ShootOnce( self.entity )

end

return carnicinth
