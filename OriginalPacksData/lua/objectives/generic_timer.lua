class 'generic_timer' ( LuaObjectiveScript )

function generic_timer:__init()
	LuaObjectiveScript.__init(self,self)
end

function generic_timer:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="onUpdate" } )
	self.fsm:AddState( "idle", { from="*", execute="onIdle" } )
	self.fsm:ChangeState( "update" )
	
	self.currentTime = self.data:GetFloat( "time_max" )
	self.data:SetFloat( "timer_deadline", GetLogicTime() + self.currentTime )

	self.stringToObjectiveState =
	{
		["objective_success"] 	= OBJECTIVE_SUCCESS,
		["objective_failed"] 	= OBJECTIVE_FAILED,
		["silent_remove"] 		= OBJECTIVE_SILENT_REMOVE,
	}

	self.objectiveState = self.stringToObjectiveState[ self.data:GetString( "objective_state" ) ];
end

function generic_timer:OnLoad()
	self.data:SetFloat( "timer_deadline", GetLogicTime() + self.currentTime )
end

function generic_timer:onUpdate( state, dt )
	self.currentTime = self.currentTime - dt
	if ( self.currentTime < 0 ) then
		self.currentTime = 0
	end

    if ( self.currentTime == 0 ) then   
		ObjectiveService:FinishObjectiveByObjectiveId( self.objective_id, self.objectiveState )
		self.fsm:ChangeState( "idle" )
    end
end

function generic_timer:onIdle()

end

return generic_timer
