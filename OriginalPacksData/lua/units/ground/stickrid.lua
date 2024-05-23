require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'stickrid' ( base_unit )

function stickrid:__init()
	base_unit.__init(self, self)
end

function stickrid:OnInit()

	self:RegisterHandler( self.entity, "ShootArtilleryEvent",  "OnShootArtilleryEvent" )

	self.wreck_type = "wreck_small";
	self.wreckMinSpeed = 100

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function stickrid:OnShootArtilleryEvent( evt )
	local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), evt:GetTargetTag() )

	WeaponService:ShootArtilleryOnTargetOrigin( self.entity, self.entity, targetOrigin.x, targetOrigin.y + 1.0, targetOrigin.z, "", "att_shoot" )

end

return stickrid
