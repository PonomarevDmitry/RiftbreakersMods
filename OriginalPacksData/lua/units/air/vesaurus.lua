require("lua/utils/table_utils.lua")
require("lua/units/units_utils.lua")

class 'vesaurus' ( LuaEntityObject )

function vesaurus:__init()
	LuaEntityObject.__init(self, self)
end

function vesaurus:init()
	SetupUnitScale( self.entity, self.data )

	self:RegisterHandler( self.entity, "DestroyRequest",  "OnDestroyRequest" )
	
	self.stateTimer = 0.0
	self.soundFSM = self:CreateStateMachine()
	self.soundFSM:AddState( "silence", {interval=0.5} )
	self.soundFSM:AddState( "idle", {enter="_OnIdleEnter", execute="_OnIdleExecute", interval=0.5} )
	self.soundFSM:ChangeState("idle")
end

function vesaurus:OnDestroyRequest( evt )
	if ( EntityService:GetUnitCurrentSpeed( self.entity ) > 5.0 ) then
		EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(), "wreck_air", 0 )
	else
		EntityService:RequestDestroyPattern( self.entity, "wreck" )
	end
	self.soundFSM:ChangeState("silence")
end


function vesaurus:_OnIdleEnter( state )
	self.stateTimer = -math.random(0.0,10.0)
end
function vesaurus:_OnIdleExecute( state, dt )
	self.stateTimer = self.stateTimer + dt
	
	if ( self.stateTimer > 8.0 ) then
		EffectService:AttachEffects( self.entity, "idle_random" )
		self.stateTimer = -math.random(0.0,8.0)
	end	
end


return vesaurus