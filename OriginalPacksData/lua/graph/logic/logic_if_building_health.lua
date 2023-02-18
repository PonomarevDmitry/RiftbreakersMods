class 'logic_if_building_health' ( LuaGraphNodeSelector )

function logic_if_building_health:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_building_health:init()
	self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", execute="OnExecuteWait" } )
end

function logic_if_building_health:Activated()
    self.fsm:ChangeState( "wait" )
	
	self.hpThreshold = self.data:GetFloatOrDefault("hp", 0.5 )
	self.hqId = FindService:FindEntityByType( "headquarters" )		
	self.hqHP = HealthService:GetHealthInPercentage( self.hqId )
	self.hpThreshold = self.hqHP * self.hpThreshold
end

function logic_if_building_health:OnExecuteWait( state )
	self.hqHP = HealthService:GetHealthInPercentage( self.hqId )
	--LogService:Log("HQ HEALTH = " .. tostring(self.hqHP))
	if self.hqHP < self.hpThreshold then
		self:SetFinished("true")
	end
end

return logic_if_building_health