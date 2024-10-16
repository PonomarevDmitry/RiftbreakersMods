class 'lift_object' ( LuaEntityObject )

function lift_object:__init()
	LuaEntityObject.__init(self,self)
end

function lift_object:init()	
	self:RegisterHandler( self.entity, "InteractWithEntityRequest",  "OnInteractWithEntityRequest" )
	self:RegisterHandler( self.entity, "PhysicsSleepEvent", "OnPhysicsSleepEvent" )

	self.sm = self:CreateStateMachine()
	self.sm:AddState( "timeout", { enter="OnTimeoutEnter", exit="OnTimeoutExit" } )
	self.sm:AddState( "dummy", {} )
end

function lift_object:OnLoad()
	if EntityService:HasComponent(self.entity, "InteractiveComponent" ) then
		return
	end

	EntityService:PhysicsSleepNotify( self.entity, true )
	EntityService:PhysicsWakeUp( self.entity )
end

function lift_object:OnInteractWithEntityRequest( evt )
	BuildingService:RemoveGuiTimer( self.entity )
	EntityService:RemoveComponent( self.entity, "LifeTimeComponent" )
end

function lift_object:OnPhysicsSleepEvent( evt )
	if ( UnitService:IsOnNavigationFreeSpace( self.entity ) == false ) then
		EntityService:DissolveEntity( self.entity, 0.3 )
	else
		EntityService:RemoveComponent( self.entity, "PhysicsComponent" )

		QueueEvent("RecreateComponentFromBlueprintRequest", self.entity, "InteractiveComponent" )
		QueueEvent("RecreateComponentFromBlueprintRequest", self.entity, "PhysicsComponent" )
		QueueEvent("RecreateComponentFromBlueprintRequest", self.entity, "TypeComponent" )

		HealthService:SetImmortality( self.entity, false )

		self.sm:ChangeState("timeout")
	end
end

function lift_object:OnTimeoutEnter( state )
    self.lifetime = self.data:GetFloatOrDefault( "lifetime", 60.0 )	
	self.lifetime_countdown_start = self.data:GetFloatOrDefault( "lifetime_countdown_start", 30.0 )
	state:SetDurationLimit( self.lifetime - self.lifetime_countdown_start )
end

function lift_object:OnTimeoutExit( state )
	EntityService:DissolveEntity( self.entity, 0.25, self.lifetime_countdown_start )
	local timerEnt = BuildingService:CreateGuiTimer( self.entity, self.lifetime_countdown_start, true, false )
	local timerPos = EntityService:GetPosition( timerEnt )
	timerPos.y = timerPos.y + 2.5;
	EntityService:SetWorldPosition( timerEnt, timerPos )
end

return lift_object
