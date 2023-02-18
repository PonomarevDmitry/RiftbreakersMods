class 'event_end' ( LuaGraphNode )

function event_end:__init()
	LuaGraphNode.__init(self,self)
end

function event_end:init()
    self.fsm = self.event_end:CreateStateMachine()
    self.fsm:AddState( "default", { from="*", enter="OnEnterDefault", exit= "OnExitDefault" } )
end

function event_end:Activated()    
    self.fsm:ChangeState( "default" )
end

function event_end:OnEnterDefault(state)
    LogService:Log("!!!!  Enter Win")
    --GuiService:Show( "common.black_fullscreen", "" )
    state:SetDurationLimit( 1 )    
end

function event_end:OnExitDefault(state)
    LogService:Log("!!!!Exit Win")
    self:SetFinished()
end

return event_end