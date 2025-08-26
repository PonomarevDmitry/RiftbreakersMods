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
	self.wreckMinSpeed = 8
    self.normalExplodeProbability = 2
	self.leaveBodyProbability = 8

	self.projectileBp = ""

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function flurian:OnShootArtilleryEvent( evt )
	local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), evt:GetTargetTag() )
	targetOrigin.y = targetOrigin.y + 1.0
	WeaponService:UpdateGrenadeAiming( self.entity, targetOrigin )
	WeaponService:ShootOnce( self.entity )

end

function flurian:OnPrepareArtilleryEvent( evt )
	self.projectileBp = evt:GetPrepareBlueprint()
end

return flurian
