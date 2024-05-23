require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'plutrodon' ( base_unit )

function plutrodon:__init()
	base_unit.__init(self, self)
end

function plutrodon:OnInit()
	self:RegisterHandler( self.entity, "ShootArtilleryEvent",  "OnShootArtilleryEvent" )
	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )

	UnitService:SetStateMachineParam( self.entity, "range_target_valid", 0 )
end

function plutrodon:OnShootArtilleryEvent( evt )
	local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), evt:GetTargetTag() )

	WeaponService:ShootSpikesOnTargetOrigin( self.entity, self.entity, targetOrigin.x, targetOrigin.y, targetOrigin.z, "att_shoot" )

end

return plutrodon
