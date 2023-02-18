
class 'loot_container_delayer' ( LuaEntityObject )

function loot_container_delayer:__init()
	LuaEntityObject.__init(self,self)
end

function loot_container_delayer:init()	
    self.aggressiveRadius = self.data:GetFloatOrDefault( "aggressive_radius", 20 )
	self.delay = self.data:GetFloatOrDefault( "delay", 1);
    self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "wait", { enter="OnEnterWait", exit="OnExitWait" } )
    self.fsm:ChangeState("wait")
end

function loot_container_delayer:OnEnterWait(state)
    state:SetDurationLimit( self.delay )
end

function loot_container_delayer:OnExitWait( dt )
    EntityService:ChangeAIGroupsToAggressive( self.entity, self.aggressiveRadius, false )
    EntityService:RemoveEntity( self.entity, 0.5 )
end

return loot_container_delayer