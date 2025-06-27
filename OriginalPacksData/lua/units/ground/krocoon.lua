require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'krocoon' ( base_unit )

function krocoon:__init()
	base_unit.__init(self, self)
end

function krocoon:OnInit()
	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 0
    self.normalExplodeProbability = 1
	self.leaveBodyProbability = 7
end

function krocoon:OnAnimationMarkerReached( evt )
	local markerName = evt:GetMarkerName() 
	if ( markerName == "eat" ) then
		self.food = UnitService:GetCurrentTarget( self.entity, "food" )

		if ( self.food ~= INVALID_ID ) then
			EntityService:DissolveEntity( self.food, 2.5 )
		end	
	end

	return true
end

return krocoon
