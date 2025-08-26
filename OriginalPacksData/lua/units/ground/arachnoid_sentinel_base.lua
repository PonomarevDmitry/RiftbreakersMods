require("lua/utils/string_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'arachnoid_sentinel_base' ( base_unit )

function arachnoid_sentinel_base:__init()
	base_unit.__init(self,self)
end

function arachnoid_sentinel_base:OnInit()
	
	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )

	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4
	self.disallowDeathAnim = "death_3"

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function arachnoid_sentinel_base:OnShootEvent( evt )

	WeaponService:ShootOnce( self.entity )

end

return arachnoid_sentinel_base
