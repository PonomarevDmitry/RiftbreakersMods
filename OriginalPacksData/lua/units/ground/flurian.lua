require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'flurian' ( base_unit )

function flurian:__init()
	base_unit.__init(self, self)
end

function flurian:OnInit()
	self:RegisterHandler( self.entity, "ShootArtilleryEvent",  "OnShootArtilleryEvent" )
	self:RegisterHandler( self.entity, "PrepareArtilleryEvent",  "OnPrepareArtilleryEvent" )

	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4

	self.projectileBp = ""

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function flurian:OnShootArtilleryEvent( evt )
	local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), evt:GetTargetTag() )
	WeaponService:UpdateGrenadeAiming( self.entity,targetOrigin.x, targetOrigin.y + 1.0, targetOrigin.z )
	WeaponService:ShootOnce( self.entity )

end

function flurian:OnPrepareArtilleryEvent( evt )
	self.projectileBp = evt:GetPrepareBlueprint()
end

return flurian
