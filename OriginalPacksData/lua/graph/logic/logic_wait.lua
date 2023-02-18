class 'logic_wait' ( LuaGraphNode )

function logic_wait:__init()
    LuaGraphNode.__init(self, self)
end

function logic_wait:init()
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", enter="OnEnterWait", exit= "OnExitWait" } )
end

function logic_wait:Activated()
    self.fsm:ChangeState("wait")
end

function logic_wait:OnEnterWait( state )
    local duration = self.data:GetFloat("duration")
    state:SetDurationLimit( duration )
end

function logic_wait:OnExitWait( state )
    self:SetFinished()
end

return logic_wait