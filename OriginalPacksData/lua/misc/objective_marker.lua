class 'objective_marker' ( LuaEntityObject )

function objective_marker:__init()
	LuaEntityObject.__init(self,self)
end

function objective_marker:init()

	self.arrowEffect = INVALID_ID
	self.circleEffect = INVALID_ID
	self.coreEffect = INVALID_ID
	self.isRemoved = false

	local displayArrowEffect = self.data:GetIntOrDefault( "display_marker_arrow", 1 )
	local displayCircleEffect = self.data:GetIntOrDefault( "display_marker_circle", 1 )
	local displayCoreEffect = self.data:GetIntOrDefault( "display_marker_core", 1 )

	local scaleFactor = self.data:GetFloatOrDefault( "circle_width_factor", 1.0 )
	local extraHeight = self.data:GetFloatOrDefault( "arrow_extra_height", 0.0 )

	local parent = EntityService:GetParent( self.entity )
	if parent ~= INVALID_ID then
		self:RegisterHandler( parent, "DestroyRequest", "OnParentDestroyRequest" )
		if EntityService:HasComponent( parent, "PhysicsComponent" ) then
			local parentAabb = EntityService:GetPhysicsWorldAabb( parent, 0 )
			local parentPos = EntityService:GetPosition( parent )
			self.arrowHeight = parentAabb.max.y - parentPos.y + 1.0 + extraHeight
			self.circleWidth = math.max( parentAabb.max.x - parentAabb.min.x, parentAabb.max.z - parentAabb.min.z ) * scaleFactor
		elseif EntityService:HasComponent( parent, "BoundsComponent" ) then
			local parentAabb = EntityService:GetWorldAabb( parent )
			local parentPos = EntityService:GetPosition( parent )
			self.arrowHeight = parentAabb.max.y - parentPos.y + 1.0 + extraHeight
			self.circleWidth = math.max( parentAabb.max.x - parentAabb.min.x, parentAabb.max.z - parentAabb.min.z ) * scaleFactor
		else
			LogService:Log("Error : No parent bounds or physics bounds!")
		end
	else 
		self:RegisterHandler( self.entity, "DissolveEntityRequest", "OnDissolveEntityRequest" )
		self.arrowHeight = 6.0 + extraHeight
		self.circleWidth = 4.0 * scaleFactor
	end

	if displayArrowEffect == 1 then
		local arrowEffectBp = self.data:GetStringOrDefault( "arrow_effect", "" )
		if arrowEffectBp ~= "" then 
	    	self.arrowEffect = EntityService:SpawnAndAttachEntity( arrowEffectBp, self.entity )
	    	EntityService:SetPosition( self.arrowEffect, 0, self.arrowHeight, 0 )
		end 
	end

	if displayCircleEffect == 1 then
		local circleEffectBp = self.data:GetStringOrDefault( "circle_effect", "" )
		if circleEffectBp ~= "" then 
	    	self.circleEffect = EntityService:SpawnAndAttachEntity( circleEffectBp, self.entity )
	    	EntityService:SetScale( self.circleEffect, self.circleWidth, 3, self.circleWidth )
		end 
	end

	if displayCoreEffect == 1 then
		local coreEffectBp = self.data:GetStringOrDefault( "core_effect", "" )
		if coreEffectBp ~= "" then 
	    	self.coreEffect = EntityService:SpawnAndAttachEntity( coreEffectBp, self.entity )
	    	EntityService:SetScale( self.coreEffect, self.circleWidth, self.circleWidth, self.circleWidth )
		end 
	end

	if self.arrowEffect ~= INVALID_ID or self.circleEffect ~= INVALID_ID then
		self.sm = self:CreateStateMachine()
		self.sm:AddState( "update", { execute="OnUpdate" } )
		self.sm:ChangeState("update")
	end
end

function objective_marker:OnUpdate( state )
	local currentTime = state:GetDuration()

	if self.arrowEffect ~= INVALID_ID and EntityService:IsAlive( self.arrowEffect ) then 
		EntityService:SetPosition( self.arrowEffect, 0, self.arrowHeight + 0.5 * math.cos( 3.14 * currentTime ), 0 )
	end

	if self.circleEffect ~= INVALID_ID and EntityService:IsAlive( self.circleEffect ) then 
		EntityService:Rotate( self.circleEffect, 0, 1, 0, 1 )
		local scale = self.circleWidth + ( 0.2 * self.circleWidth ) + ( self.circleWidth * 0.05 * math.cos( 3.14 * currentTime ) )
		EntityService:SetScale( self.circleEffect, scale, 3, scale )
	end
end

function objective_marker:OnDissolveEntityRequest( evt )
	if 	self.isRemoved == true then
		return
	end
	
	if self.arrowEffect ~= INVALID_ID and EntityService:IsAlive( self.arrowEffect ) then 
		EntityService:DissolveEntity( self.arrowEffect, evt:GetDuration(), evt:GetDelay() )
	end

	if self.circleEffect ~= INVALID_ID and EntityService:IsAlive( self.circleEffect ) then 
		EntityService:DissolveEntity( self.circleEffect, evt:GetDuration(), evt:GetDelay() )
	end

	if self.coreEffect ~= INVALID_ID and EntityService:IsAlive( self.coreEffect ) then 
		EntityService:DissolveEntity( self.coreEffect, evt:GetDuration(), evt:GetDelay() )
	end

	self.isRemoved = true
end

function objective_marker:OnParentDestroyRequest( evt )
	if 	self.isRemoved == true then
		return
	end

	EntityService:DetachEntity( self.entity )
	EntityService:DissolveEntity( self.entity, 1.0 )

	if self.arrowEffect ~= INVALID_ID and EntityService:IsAlive( self.arrowEffect ) then 
		EntityService:DissolveEntity( self.arrowEffect, 1.0 )
	end

	if self.circleEffect ~= INVALID_ID and EntityService:IsAlive( self.circleEffect ) then 
		EntityService:DissolveEntity( self.circleEffect, 1.0 )
	end

	if self.coreEffect ~= INVALID_ID and EntityService:IsAlive( self.coreEffect ) then 
		EntityService:DissolveEntity( self.coreEffect, 1.0 )
	end	

	self.isRemoved = true
end

return objective_marker
