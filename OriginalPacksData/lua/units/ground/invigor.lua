require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'invigor' ( base_unit )

function invigor:__init()
	base_unit.__init(self, self)
end

function invigor:OnInit()
	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4

	self.firstTimeDig = true
end

function invigor:OnAnimationMarkerReached( evt )
	local markerName = evt:GetMarkerName() 
	if ( ( markerName == "dig_down" ) and ( self.firstTimeDig  == true ) ) then
		self.firstTimeDig  = false
		return false
	end

	return true
end

return invigor
