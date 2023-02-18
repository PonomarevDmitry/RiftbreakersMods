class 'reveal_map' ( LuaObjectiveScript )

function reveal_map:__init()
	LuaObjectiveScript.__init(self,self)
end

function reveal_map:init()

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="onUpdate" } )
	self.fsm:AddState( "idle", {} )
	self.fsm:ChangeState( "update" )

    self.progressMax = self.data:GetInt( "progress_max" );
	self.data:SetInt( "progress_current", 0 )
end

function reveal_map:onUpdate()

	local progressCurrent = EnvironmentService:GetMapRevealPercentage() * 100

    if ( progressCurrent >= self.progressMax ) then
	   ObjectiveService:FinishObjectiveByObjectiveId( self.objective_id, OBJECTIVE_SUCCESS )
	   progressCurrent = self.progressMax
	   self.fsm:ChangeState( "idle" )
    end

	self.data:SetInt( "progress_current", progressCurrent )

end


return reveal_map