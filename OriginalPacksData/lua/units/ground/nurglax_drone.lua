class 'nurglax_drone' ( LuaEntityObject )
require("lua/units/units_utils.lua")

function nurglax_drone:__init()
	LuaEntityObject.__init(self, self)
end

function nurglax_drone:init()
	SetupUnitScale( self.entity, self.data )

	self:RegisterHandler( self.entity, "DestroyRequest",  "OnDestroyRequest" )
	self:RegisterHandler( self.entity, "PrepareSuecideEvent",  "OnPrepareSuecideEvent" )
	self:RegisterHandler( self.entity, "TargetNotFoundEvent",  "OnTargetNotFoundEvent" )

	self.lifeTimeFSM = self:CreateStateMachine()
	self.lifeTimeFSM:AddState( "life_time", { execute="OnLifeTimeExecute" } )

	self.lifeTime = 0.0
end

function nurglax_drone:OnLifeTimeExecute( state, dt )
	self.lifeTime = self.lifeTime - dt
	if ( self.lifeTime <= 0 ) then
		EntityService:RequestDestroyPattern( self.entity, "default" )
	end

	if ( UnitService:GetStateMachineParamInt( self.entity, "move_target_valid" ) == 0 ) then
		EntityService:RequestDestroyPattern( self.entity, "default" )
	end
end

function nurglax_drone:OnPrepareSuecideEvent( evt )
	self.lifeTime = evt:GetTime()
	self.lifeTimeFSM:ChangeState( "life_time" )
end

function nurglax_drone:OnTargetNotFoundEvent( evt )
	EntityService:RequestDestroyPattern( self.entity, "default" )
end

function nurglax_drone:OnDestroyRequest( evt )
	EntityService:RequestDestroyPattern( self.entity, "default" )
end


return nurglax_drone