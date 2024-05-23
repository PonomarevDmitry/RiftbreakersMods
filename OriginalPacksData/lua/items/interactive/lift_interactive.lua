class 'lift_interactive' ( LuaEntityObject )

function lift_interactive:__init()
	LuaEntityObject.__init(self,self)
end

function lift_interactive:init()	
	self:RegisterHandler( self.entity, "InteractWithEntityRequest",  "OnInteractWithEntityRequest" )

	if ( EntityService:HasComponent( self.entity, "VegetationComponent" ) ) then
		self:RegisterHandler( self.entity, "DamageEvent",  "OnDamageEvent" )
	end
end

function lift_interactive:OnInteractWithEntityRequest( evt )
	local destroyEntity = self.data:GetIntOrDefault( "destroy_entity", 0 )
	if destroyEntity ~= 0 then
		QueueEvent( "DestroyRequest", self.entity, "interact", 100 )
	end

	local emitEventName = self.data:GetStringOrDefault( "emit_event", "" )
	if emitEventName ~= "" then
		QueueEvent( "LuaGlobalEvent", event_sink, emitEventName, {} )
	end

	--local disableGlow = self.data:GetIntOrDefault( "disable_glow", 1 )
	--if disableGlow == 1 then
	--	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 0.0 )
	--end
end 

function lift_interactive:OnDamageEvent( event )
	if event:GetDamageType() == "fire" then
		EntityService:RemoveComponent( self.entity, "TypeComponent" )
		EntityService:RemoveComponent( self.entity, "InteractiveComponent" )
	end
end

return lift_interactive