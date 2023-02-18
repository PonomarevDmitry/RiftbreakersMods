class 'rule_hq_survive' ( LuaGraphNode )

function rule_hq_survive:__init()
	LuaGraphNode.__init(self,self)
end

function rule_hq_survive:init()
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "rule", { from="*", enter="OnEnterRule", execute="OnExecuteRule", exit= "OnExitRule" } )
end

function rule_hq_survive:Activated()
	self:RegisterHandler( event_sink, "RespawnFailedEvent", "OnRespawnFailedEvent" )
end

function rule_hq_survive:OnRespawnFailedEvent()
	LogService:Log( "Mission failed" )
	self.fsm:ChangeState( "rule" )
end

function rule_hq_survive:OnEnterRule( state )
    LogService:Log( "OnEnterRule" )	
    state:SetDurationLimit( 5 )    
end

function rule_hq_survive:OnExecuteRule( state )
end

function rule_hq_survive:OnExitRule( state )
    LogService:Log( "OnExitRule" )
    LampService:ReportGameFailed()
	MissionService:ShowEndGameHud( 0.0, false )
    self:SetFinished()
end

return rule_hq_survive