require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'alien_tower_plasma' ( base_unit )

function alien_tower_plasma:__init()
	base_unit.__init(self, self)
end

function alien_tower_plasma:OnInit()
	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )
	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function alien_tower_plasma:OnShootEvent( evt )

	WeaponService:ShootOnce( self.entity )

end

return alien_tower_plasma
