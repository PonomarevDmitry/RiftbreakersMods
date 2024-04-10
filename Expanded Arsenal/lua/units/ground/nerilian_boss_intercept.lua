require("lua/utils/table_utils.lua")

local alien_intercept = require("lua/units/ground/alien_intercept.lua")
class 'nerilian_boss_intercept' ( alien_intercept )

function nerilian_boss_intercept:__init()
	alien_intercept.__init(self, self)
end

function nerilian_boss_intercept:OnInit()
	self.data:SetInt( "skip_dig_up", 1 )

	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4

	self.firstTimeDig = true
	
	alien_intercept.OnInit(self)
end

function nerilian_boss_intercept:_OnDestroyRequest( evt )

	EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(),self.wreck_type, self.wreckMinSpeed )
	self:ChangeSoundState("idle")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_on")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_off")

    if self.OnDestroyRequest then
        self:OnDestroyRequest(evt)
    end
end

function nerilian_boss_intercept:OnAnimationMarkerReached( evt )
	local markerName = evt:GetMarkerName() 
	if ( ( markerName == "dig_down" ) and ( self.firstTimeDig  == true ) ) then
		self.firstTimeDig  = false
		return false
	end

	return true
end

return nerilian_boss_intercept
