require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'alien_tower_EA' ( base_unit )

function alien_tower_EA:__init()
	base_unit.__init(self, self)
end

function alien_tower_EA:OnInit()
	SetupUnitScale( self.entity, self.data )
	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )
	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4
	
	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function alien_tower_EA:OnShootEvent( evt )

	WeaponService:ShootOnce( self.entity )

end

return alien_tower_EA
