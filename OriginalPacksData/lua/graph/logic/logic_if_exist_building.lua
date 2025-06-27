class 'logic_if_exist_building' ( LuaGraphNodeSelector )

function logic_if_exist_building:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_exist_building:init()
    self.count = self.data:GetInt("count")    	
    self.targetName = self.data:GetStringOrDefault("target_name", "")
    self.targetBp = self.data:GetStringOrDefault("target_bp", "")
    self.targetGlobalName = self.data:GetStringOrDefault("target_global_name", "")
    self.comparisonType = self.data:GetString("comparison_type")
	self.waitUntilTrue = self.data:GetString("wait_until_true")

    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", execute="OnExecuteWait" } )
end

function logic_if_exist_building:Activated()
    self.nodeEnabled = true

    self.fsm:ChangeState( "wait" )
end

function logic_if_exist_building:OnExecuteWait( state )
    if self.nodeEnabled == false then
        state:Exit()
        return
    end
    
    local foundCount = self:Find()
    --LogService:Log( "Found: " .. tostring(foundCount))
    if self.comparisonType == "equal" and ( foundCount == self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished("true")
    elseif self.comparisonType == "not_equal" and ( foundCount ~= self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished("true")
    elseif self.comparisonType == "greater" and ( foundCount > self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished("true")
    elseif self.comparisonType == "greater_or_equal" and ( foundCount >= self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished("true")
    elseif self.comparisonType == "less" and ( foundCount < self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished("true")
    elseif self.comparisonType == "less_or_equal" and ( foundCount <= self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished( "true")
    elseif self.waitUntilTrue == "false" then
        self:SetFinished("false")
        --LogService:Log("IF STATEMENT NEGATIVE")
    end    

    --LogService:Log("WAIT UNTIL TRUE = " .. self.waitUntilTrue )
    
    if self.waitUntilTrue == "false" then
        state:Exit()
    end
    
end

function logic_if_exist_building:Find()    
    -- Search anywhere on the map
   if self.targetName ~= "" then        
       --LogService:Log("TARGET NAME = " .. self.targetName)
       return BuildingService:GetBuildingByNameCount( self.targetName )         
   elseif self.targetBp ~= "" then        
       --LogService:Log("TARGET GROUP = " .. self.targetGroup)
       return BuildingService:GetBuildingByBpCount( self.targetBp )     
   elseif self.targetGlobalName ~= "" then
       return BuildingService:GetGlobalBuildingByNameCount( self.targetGlobalName )     
          
   else
        Assert(false, "ERROR: No target name or target blueprint specified in " .. self.self_id )
    
       return 0
   end
end

function logic_if_exist_building:OnDisablenodes( event )
    self.nodeEnabled = false
end

function logic_if_exist_building:OnDisableNamednode( event )
    if self.data:GetString( "self_id" ) == event:GetObject() then
        self.nodeEnabled = false
    end
end

return logic_if_exist_building