require("lua/utils/table_utils.lua")
require("lua/units/units_utils.lua")

class 'crystal_blocker_timer' ( LuaEntityObject )

function crystal_blocker_timer:__init()
	LuaEntityObject.__init(self, self)
end

function crystal_blocker_timer:init()
	
	self.timer = self.data:GetFloatOrDefault("crystal_lifespan", 6 )
	SetupUnitScale( self.entity, self.data )
	
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "Timer", { enter="OnTimerEnter", exit="OnTimerExit"} )
	self.fsm:ChangeState( "Timer" )
end

function crystal_blocker_timer:OnTimerEnter( state )
	state:SetDurationLimit( self.timer )
end

function crystal_blocker_timer:OnTimerExit( state )
	EntityService:RequestDestroyPattern( self.entity, "default", true )
end

return crystal_blocker_timer