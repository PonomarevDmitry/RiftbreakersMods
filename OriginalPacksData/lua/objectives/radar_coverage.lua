class 'radar_coverage' ( LuaObjectiveScript )

function radar_coverage:__init()
	LuaObjectiveScript.__init(self,self)
end

function radar_coverage:init()

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="onUpdate" } )
	self.fsm:AddState( "idle", {} )
	self.fsm:ChangeState( "update" )

    self.progressMax = self.data:GetInt( "progress_max" );
	self.data:SetInt( "progress_current", 0 )
end

function radar_coverage:onUpdate()

	local progressCurrent = EnvironmentService:GetRadarCoveragePercentage() * 100

    if ( progressCurrent >= self.progressMax ) then
	   ObjectiveService:FinishObjectiveByObjectiveId( self.objective_id, OBJECTIVE_SUCCESS )
	   progressCurrent = self.progressMax
	   self.fsm:ChangeState( "idle" )
    end

	self.data:SetInt( "progress_current", progressCurrent )

end


return radar_coverage