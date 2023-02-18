require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'zorant' ( base_unit )

function zorant:__init()
	base_unit.__init(self, self)
end

function zorant:OnInit()
	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )
	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function zorant:OnShootEvent( evt )

	WeaponService:ShootOnce( self.entity )

end

return zorant
