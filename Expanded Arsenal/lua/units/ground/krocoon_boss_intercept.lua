require("lua/utils/table_utils.lua")

local alien_intercept = require("lua/units/ground/alien_intercept.lua")
class 'krocoon_boss_intercept' ( alien_intercept )

function krocoon_boss_intercept:__init()
	alien_intercept.__init(self, self)
end

function krocoon_boss_intercept:OnInit()
	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4
	
	alien_intercept.OnInit(self)
end

function krocoon_boss_intercept:_OnDestroyRequest( evt )

	EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(),self.wreck_type, self.wreckMinSpeed )
	self:ChangeSoundState("idle")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_on")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_off")

    if self.OnDestroyRequest then
        self:OnDestroyRequest(evt)
    end
end

function krocoon_boss_intercept:OnAnimationMarkerReached( evt )
	local markerName = evt:GetMarkerName() 
	if ( markerName == "eat" ) then
		self.food = UnitService:GetCurrentTarget( self.entity, "food" )

		if ( self.food ~= INVALID_ID ) then
			EntityService:DissolveEntity( self.food, 2.5 )
		end	
	end

	return true
end

return krocoon_boss_intercept
