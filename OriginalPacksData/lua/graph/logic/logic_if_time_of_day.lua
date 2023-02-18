class 'logic_if_time_of_day' ( LuaGraphNodeSelector )

function logic_if_time_of_day:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_time_of_day:init()
	self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { execute="OnExecuteWait", inverval=1 } )
end

function logic_if_time_of_day:Activated()    

    self.comparisonType = self.data:GetString("comparison_type")     
    self.comparisonTime = self.data:GetInt("comparison_time")
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

function logic_if_time_of_day:OnExecuteWait( state )	
	if self:CompareTime() == true then
		--LogService:Log("TIME IS ON MY SIDE")
		self:SetFinished("true")		
    end    
end

function logic_if_time_of_day:CompareTime()    
	local hour = EnvironmentService:GetTimeOfDayHour() 

	if self.comparisonType == "equal" and ( hour == self.comparisonTime ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        return true
    elseif self.comparisonType == "not_equal" and ( hour ~= self.comparisonTime ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        return true
    elseif self.comparisonType == "greater" and ( hour > self.comparisonTime ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        return true
    elseif self.comparisonType == "greater_or_equal" and ( hour >= self.comparisonTime ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        return true
    elseif self.comparisonType == "less" and ( hour < self.comparisonTime ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        return true
    elseif self.comparisonType == "less_or_equal" and ( hour <= self.comparisonTime ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        return true  
	else
		return false
    end    
end

return logic_if_time_of_day