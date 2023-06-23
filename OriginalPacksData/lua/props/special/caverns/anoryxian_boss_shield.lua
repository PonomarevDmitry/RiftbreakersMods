class 'anoryxian_boss_shield' ( LuaEntityObject )

function anoryxian_boss_shield:__init()
	LuaEntityObject.__init(self,self)
end

function anoryxian_boss_shield:init()	
	self:RegisterHandler( self.entity, "AnimationMarkerReached", "OnAnimationMarkerReached" )

	self.maxDustCount = 9
end

function anoryxian_boss_shield:OnAnimationMarkerReached( evt )
	
	local markerName = evt:GetMarkerName() 

    if ( markerName == "shield_down" ) then
		EntityService:DissolveEntity( self.entity, 0.5 )
    elseif ( markerName == "dust" ) then
		for i = 1, self.maxDustCount do	
			EffectService:AttachEffects( self.entity, "dust_" .. tostring( i ) )
		end
	else
        EffectService:AttachEffects( self.entity, markerName  )
    end

end


return anoryxian_boss_shield