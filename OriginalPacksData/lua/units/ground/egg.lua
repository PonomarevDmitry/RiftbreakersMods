require("lua/units/units_utils.lua")

class 'egg' ( LuaEntityObject )

function egg:__init()
	LuaEntityObject.__init(self, self)
end

function egg:init()
	
	local grow = self.data:GetIntOrDefault( "grow", 0 )

	SetupUnitScale( self.entity, self.data )

	EntityService:Rotate( self.entity, 0, 1, 0, RandFloat( 0, 360) )
	self:RegisterHandler( self.entity, "HatchedEvent",  "OnHatchedEvent" )

	if ( grow == 1 ) then 
		EntityService:SetVisible( self.entity, true );
		self.fsm = self:CreateStateMachine()
		self.fsm:AddState( "grow", { execute="OnExecuteGrowEgg" } )
		self.fsm:ChangeState( "grow" )

		self.growScale = 0.01
		self.growScaleTo = EntityService:GetScale( self.entity )
		self.growSpeed = self.data:GetFloatOrDefault( "grow_speed", 2.0 )

		EntityService:SetScale( self.entity, self.growScale, self.growScale, self.growScale )
	end
end

function egg:OnExecuteGrowEgg( state, dt )
	if ( self.growScale >= self.growScaleTo.x ) then	
		state:Exit()
	else
		self.growScale = self.growScale + ( ( 1.0 / self.growSpeed ) * dt )
		EntityService:SetScale( self.entity, self.growScale, self.growScale, self.growScale )
	end
end

function egg:OnHatchedEvent( evt )	
	EntityService:RequestDestroyPattern( self.entity, "spawn" )
end

return egg
