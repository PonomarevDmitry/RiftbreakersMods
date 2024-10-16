class 'objective_marker' ( LuaEntityObject )

function objective_marker:__init()
	LuaEntityObject.__init(self,self)
end

function objective_marker:init()

	self.arrowEffect = INVALID_ID
	self.circleEffect = INVALID_ID
	self.coreEffect = INVALID_ID

	local displayArrowEffect = self.data:GetIntOrDefault( "display_marker_arrow", 1 )
	local displayCircleEffect = self.data:GetIntOrDefault( "display_marker_circle", 1 )
	local displayCoreEffect = self.data:GetIntOrDefault( "display_marker_core", 1 )

	local parent = EntityService:GetParent( self.entity )
	if parent ~= INVALID_ID then
		local parentAabb = EntityService:GetPhysicsWorldAabb( parent, 0 )
		local parentPos = EntityService:GetPosition( parent )
		self.arrowHeight = parentAabb.max.y - parentPos.y + 1.0
		self.circleWidth = math.max( parentAabb.max.x - parentAabb.min.x, parentAabb.max.z - parentAabb.min.z )
	else 
		self.arrowHeight = 6.0
		self.circleWidth = 4.0
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

return objective_marker
