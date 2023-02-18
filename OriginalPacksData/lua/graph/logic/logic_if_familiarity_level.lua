class 'logic_if_familiarity_level' ( LuaGraphNodeSelector )

function logic_if_familiarity_level:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_familiarity_level:init()
	self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { execute="OnExecuteWait", inverval=1 } )
end

function logic_if_familiarity_level:Activated()    

    self.comparisonType = self.data:GetString("comparison_type")     
    self.comparisonFamiliarityName = self.data:GetString("comparison_familiarity_name")     
    self.comparisonSubspeciesName = self.data:GetString("comparison_subspecies_name")     
    self.comparisonFamiliarityLevel = self.data:GetInt("comparison_familiarity_level")
	self.waitUntilTime = self.data:GetString("wait_until_time")      	
	
	--LogService:Log("WAIT UNTIL TIME = " .. self.waitUntilTime )
    if self.waitUntilTime == "true" then
		--LogService:Log("LET'S WAIT UNTIL THE TIME" )
		self.fsm:ChangeState( "wait" )
	else 
		LogService:Log("DO NOT WAIT UNTIL THE TIME" )		
		if self:CompareTime() == false then
			--LogService:Log("TIME IS NOT ON MY SIDE")
			self:SetFinished("false")
		else
			--LogService:Log("TIME IS ON MY SIDE")
			self:SetFinished("true")
		end
	end
end

function logic_if_familiarity_level:OnExecuteWait( state )	
	if self:CompareTime() == true then
		--LogService:Log("TIME IS ON MY SIDE")
		self:SetFinished("true")		
    end    
end

function logic_if_familiarity_level:CompareTime()	 
	local familiarityLevel = PlayerService:GetFamiliarityLevel( self.comparisonFamiliarityName,self.comparisonSubspeciesName ) 

	if self.comparisonType == "equal" and ( familiarityLevel == self.comparisonFamiliarityLevel ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        return true
    elseif self.comparisonType == "not_equal" and ( familiarityLevel ~= self.comparisonFamiliarityLevel ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        return true
    elseif self.comparisonType == "greater" and ( familiarityLevel > self.comparisonFamiliarityLevel ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        return true
    elseif self.comparisonType == "greater_or_equal" and ( familiarityLevel >= self.comparisonFamiliarityLevel ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        return true
    elseif self.comparisonType == "less" and ( familiarityLevel < self.comparisonFamiliarityLevel ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        return true
    elseif self.comparisonType == "less_or_equal" and ( familiarityLevel <= self.comparisonFamiliarityLevel ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        return true  
	else
		return false
    end    
end

return logic_if_familiarity_level