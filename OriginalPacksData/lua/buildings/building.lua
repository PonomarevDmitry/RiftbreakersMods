local building_base = require("lua/buildings/building_base.lua");

class 'building' ( building_base )

function building:__init()
	building_base.__init(self)
end

function building:init()
	building_base.init(self)	
	self:RegisterHandler( self.entity, "AnimationMarkerReached", "OnAnimationMarkerReached" ) 
	self:RegisterHandler( self.entity, "DamageEvent", "OnDamageEvent" )

	self.resourceMissing = {}
end

function building:OnAnimationMarker( markerName )

end

function building:OnAnimationMarkerReached(evt)
	EffectService:AttachEffects(self.entity, evt:GetMarkerName())
	self:OnAnimationMarker( evt:GetMarkerName())
end

function building:OnDamage( evt )
end

function building:OnDamageEvent(evt)
	self:OnDamage(evt)
end


return building