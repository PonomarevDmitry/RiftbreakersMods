require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'artigian' ( base_unit )

function artigian:__init()
	base_unit.__init(self, self)
end

function artigian:OnInit()	

	self:RegisterHandler( self.entity, "ShootArtilleryEvent",  "OnShootArtilleryEvent" )

	self.wreck_type = "wreck_small"
	self.wreckMinSpeed = 0
    self.normalExplodeProbability = 0
	self.leaveBodyProbability = 1

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function artigian:OnShootArtilleryEvent( evt )
	local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), evt:GetTargetTag() )

	WeaponService:ShootArtilleryOnTargetOrigin( self.entity, self.entity, targetOrigin.x, targetOrigin.y + 1.0, targetOrigin.z, "", "att_muzzle" )

end

return artigian
