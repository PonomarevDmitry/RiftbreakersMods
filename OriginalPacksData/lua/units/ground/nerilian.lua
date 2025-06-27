require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'nerilian' ( base_unit )

function nerilian:__init()
	base_unit.__init(self, self)
end

function nerilian:OnInit()
	self.data:SetInt( "skip_dig_up", 1 )

	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 0

	self.firstTimeDig = true
end

function nerilian:OnAnimationMarkerReached( evt )
	local markerName = evt:GetMarkerName() 
	if ( ( markerName == "dig_down" ) and ( self.firstTimeDig  == true ) ) then
		self.firstTimeDig  = false
		return false
	end

	return true
end

return nerilian
