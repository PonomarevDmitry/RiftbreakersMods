class 'danger_marker' ( LuaEntityObject )

function danger_marker:__init()
	LuaEntityObject.__init(self,self)
end

function danger_marker:init()
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "update", { from="*", enter="OnEnter", execute="OnExecute", exit="OnExit" } )
	self.sm:ChangeState( "update" )

	local database = EntityService:GetDatabase( self.entity )

	if database:HasFloat( "override_time" ) then
		self.lifeTime = database:GetFloat( "override_time" )
   		EntityService:CreateOrSetLifetime( self.entity, self.lifeTime, "" )
	else 
		local lifeTimeComponent = EntityService:GetConstComponent( self.entity, "LifeTimeComponent" )
	    if lifeTimeComponent ~= nil then
	        local component = reflection_helper( lifeTimeComponent )
	        self.lifeTime = component.time.timeLimit
	    else 
	    	self.lifeTime = 1
	    	EntityService:CreateLifeTime( self.entity, self.lifeTime, "" )
	    end
	end

	if database:HasFloat( "override_radius" ) then
		local radius = database:GetFloat( "override_radius" )
    	EntityService:SetScale( self.entity, 2 * radius, 7.0, 2 * radius )		
	else 
    	local scale = EntityService:GetScale( self.entity )
    	EntityService:SetScale( self.entity, scale.x, 7.0, scale.z )		
	end
end

function danger_marker:OnEnter( state )
	state:SetDurationLimit( self.lifeTime )
end

function danger_marker:OnExecute( state )
	local currentProgress = ( state:GetDuration() / self.lifeTime )
	EntityService:SetGraphicsUniform( self.entity, "cProgress", currentProgress )
end

function danger_marker:OnExit( state )

end

return danger_marker
 