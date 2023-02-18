class 'logic_if_resource' ( LuaGraphNodeSelector )

function logic_if_resource:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_resource:init()
    
    self.comparisonType = self.data:GetString("comparison_type")
    self.count = self.data:GetInt("quantity")    
    self.waitUntilTrue = self.data:GetString("wait_until_true")    
    self.resourceName = self.data:GetStringOrDefault("resource_name", "")
	Assert( self.resourceName ~= "", "ERROR: empty resource name" )
    
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", execute="OnExecuteWait" } )
end

function logic_if_resource:Activated()    

    -- LogService:Log("comparison_type " ..    self.data:GetString("comparison_type") );
    -- LogService:Log("quantity " ..              tostring(self.data:GetInt("quantity"))    );    
    -- LogService:Log("wait_until_true " ..    self.data:GetString("wait_until_true") );    
    -- LogService:Log("resource_name " ..        self.data:GetString("resource_name") );
    
    self.fsm:ChangeState( "wait" )
end

function logic_if_resource:OnExecuteWait( state )    
    
    --local entitiesFound = self:Find()
	local resourceCount = PlayerService:GetResourceAmount( self.resourceName )
    
    if self.comparisonType == "equal" and ( resourceCount == self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished("true")
    elseif self.comparisonType == "not_equal" and ( resourceCount ~= self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished("true")
    elseif self.comparisonType == "greater" and ( resourceCount > self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished("true")
    elseif self.comparisonType == "greater_or_equal" and ( resourceCount >= self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished("true")
    elseif self.comparisonType == "less" and ( resourceCount < self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished("true")
    elseif self.comparisonType == "less_or_equal" and ( resourceCount <= self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished("true")
    elseif self.waitUntilTrue == "false" then
        self:SetFinished("false")
        --LogService:Log("IF STATEMENT NEGATIVE")
    end    

    --LogService:Log("WAIT UNTIL TRUE = " .. self.waitUntilTrue )
    
    if self.waitUntilTrue == "false" then
        state:Exit()
    end
    
end

return logic_if_resource