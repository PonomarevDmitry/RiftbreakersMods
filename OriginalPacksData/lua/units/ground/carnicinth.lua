require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'carnicinth' ( base_unit )

function carnicinth:__init()
	base_unit.__init(self, self)
end

function carnicinth:OnInit()	
	self.data:SetInt( "skip_dig_up", 1 )

	self.wreck_type = "wreck_small"
	self.wreckMinSpeed = 0

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end


return carnicinth
