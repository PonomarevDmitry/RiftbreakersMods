require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'gulgor' ( base_unit )

function gulgor:__init()
	base_unit.__init(self, self)
end

function gulgor:OnInit()
	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )
	self.wreck_type = "wreck_small";
	self.wreckMinSpeed = 8

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function gulgor:OnShootEvent( evt )

	WeaponService:ShootOnce( self.entity )

end

function gulgor:OnAnimationMarkerReached( evt )

	local markerName = evt:GetMarkerName() 
	if ( markerName == "dig_up" ) then
		EntityService:SetVisible( self.entity, true );
	end

	return true;
end

return gulgor
