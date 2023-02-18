class 'generic_progress' ( LuaObjectiveScript )

function generic_progress:__init()
	LuaObjectiveScript.__init(self,self)
end

function generic_progress:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="onUpdate" } )
	self.fsm:AddState( "idle", { from="*", execute="onIdle" } )
	self.fsm:ChangeState( "update" )
	
	self.data:SetInt( "progress_current", 0 )

end

function generic_progress:onUpdate()
    local progressMax = self.data:GetInt( "progress_max" )
	local progressCurrent = self.data:GetInt( "progress_current" )

    if ( progressCurrent >= progressMax ) then
		ObjectiveService:FinishObjectiveByObjectiveId( self.objective_id, OBJECTIVE_SUCCESS )
	   self.fsm:ChangeState( "idle" )
    end

end

function generic_progress:onIdle()

end

return generic_progress
