class 'poogret_food' ( LuaEntityObject )

function poogret_food:__init()
	LuaEntityObject.__init(self,self)
end

function poogret_food:init()	
	self:RegisterHandler( self.entity, "InteractWithEntityRequest",  "OnInteractWithEntityRequest" )
	self:RegisterHandler( self.entity, "PhysicsSleepEvent", "OnPhysicsSleepEvent" )

	self.sm = self:CreateStateMachine()
	self.sm:AddState( "timeout", { enter="OnTimeoutEnter", exit="OnTimeoutExit" } )
	self.sm:AddState( "dummy", {} )
end

function poogret_food:OnInteractWithEntityRequest( evt )
	local parentId = EntityService:GetParent( self.entity )
	if parentId ~= INVALID_ID and evt:GetOwner() ~= INVALID_ID then
		QueueEvent( "LuaGlobalEvent", parentId, "FruitHarvestedEvent", {} )
	end
	EntityService:DetachEntity( self.entity )
	BuildingService:RemoveGuiTimer( self.entity )
	EntityService:RemoveComponent( self.entity, "LifeTimeComponent" )
end

function poogret_food:OnPhysicsSleepEvent( evt )
	if ( UnitService:IsOnNavigationFreeSpace( self.entity ) == false ) then
		EntityService:DissolveEntity( self.entity, 0.3 )
	else
		EntityService:RemoveComponent( self.entity, "PhysicsComponent" )
		EntityService:ChangeType( self.entity, "food" )
		HealthService:SetHealth( self.entity, 100 )
		QueueEvent("RecreateComponentFromBlueprintRequest", self.entity, "InteractiveComponent" )
		QueueEvent("RecreateComponentFromBlueprintRequest", self.entity, "PhysicsComponent" )

		self.sm:ChangeState("timeout")
	end
end

function poogret_food:OnTimeoutEnter( state )
	state:SetDurationLimit( 30.0 )
end

function poogret_food:OnTimeoutExit( state )
	EntityService:DissolveEntity( self.entity, 0.2, 30.0 )
	local timerEnt = BuildingService:CreateGuiTimer( self.entity, 30.0, true, false )
	local timerPos = EntityService:GetPosition( timerEnt )
	timerPos.y = timerPos.y + 2.5;
	EntityService:SetWorldPosition( timerEnt, timerPos )
end

return poogret_food
