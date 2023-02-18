class 'logic_wait_random' ( LuaGraphNode )

function logic_wait_random:__init()
    LuaGraphNode.__init(self, self)
end

function logic_wait_random:init()
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", enter="OnEnterWait", exit= "OnExitWait" } )
end

function logic_wait_random:Activated()
    self.fsm:ChangeState("wait")
end

function logic_wait_random:OnEnterWait( state )
    local min_duration = self.data:GetFloat("min_duration")
    local max_duration = self.data:GetFloat("max_duration")
    local duration = RandFloat( min_duration, max_duration)

    --LogService:Log("Logic wait random, from: " .. tostring(min_duration) .. " to: " .. tostring(max_duration) .. ", waiting for: " .. tostring(duration))
    state:SetDurationLimit( duration )
end

function logic_wait_random:OnExitWait( state )
    self:SetFinished()
end

return logic_wait_random