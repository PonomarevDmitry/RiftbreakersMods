class 'building_addon' ( LuaEntityObject )

function building_addon:__init()
	LuaEntityObject.__init(self, self)
end

function building_addon:init()
	self.parent = EntityService:GetParent(self.entity)
	if not( Assert( self.parent ~= INVALID_ID, "ERROR: building_addon has no parent" )) then return end

	self:RegisterHandler( self.parent, "DestroyRequest", "OnDestroyRequest" )
	self:RegisterHandler( self.entity, "DamageEvent", "OnDamageEvent" )
	self:RegisterHandler( self.entity, "AnimationMarkerReached", "OnAnimationMarkerReached" ) 

	if ( self.data:GetIntOrDefault("working_from_parent", 1) == 1 ) then
		self:RegisterHandler( self.parent, "ActivateBuildingEvent",  "_OnActivate" )
		self:RegisterHandler( self.parent, "DeactivateBuildingEvent", "_OnDeactivate" )
	end
	
	EntityService:PropagateEntityOwner( self.entity, self.parent )
end

function building_addon:OnDestroyRequest( evt )
	QueueEvent( "DestroyRequest", self.entity, evt:GetDamageType(), evt:GetDamagePercentage() )
end

function building_addon:OnDamageEvent( evt )
	local parentHealth = HealthService:GetHealthInPercentage(self.parent) * 100.0

	local children = EntityService:GetChildren( self.parent, false )
	for child in Iter(children ) do
		local healthComponent = EntityService:GetComponent( child, "HealthComponent" )
		if (healthComponent ) then
			HealthService:SetHealthInPercentage( child, parentHealth )
		end
	end
end

function building_addon:_OnActivate()
	EffectService:AttachDelayedEffects(self.entity, "working", 0.1)	
	EffectService:AttachDelayedEffects(self.entity, "powered", 0.1)	
	self.working = true
	self.data:SetFloat("is_working", 1.0 )
	self.data:SetInt("power", 1.0 )
	self.data:SetInt("resource", 1.0 )
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 1 )
end

function building_addon:_OnDeactivate()
	EffectService:DestroyEffectsByGroup(self.entity, "powered")
	self.working = false;
	self.data:SetFloat("is_working", 0.0 )
	self.data:SetInt("power", 0.0 )
	self.data:SetInt("resource", 0.0 )
	EffectService:DestroyEffectsByGroup(self.entity, "working")	
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 0 )
end

function building_addon:OnAnimationMarkerReached(evt)
	EffectService:AttachEffects(self.entity, evt:GetMarkerName())
end



return building_addon
