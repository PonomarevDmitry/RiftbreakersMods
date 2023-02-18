class 'objective_if_progress_status' ( LuaGraphNodeSelector )

function objective_if_progress_status:__init()
	LuaGraphNodeSelector.__init(self,self)
end

function objective_if_progress_status:init()
	self.objectiveName =  self.data:GetString( "unique_name_id" )
	if self.data:GetIntOrDefault("is_objective_local", 1) == 1 then
		self.objectiveName = self.parent:CreateGraphUniqueString( self.objectiveName )
	end

	self.data:SetString("unique_name_id", self.objectiveName )
    self.comparisonType = self.data:GetString("comparison_type")
    self.waitUntilTrue = self.data:GetString("wait_until_true")

	self.progressAmount = self.data:GetInt( "progress" )
    
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", execute="OnExecuteWait" } )
end

function objective_if_progress_status:Activated()
    self.nodeEnabled = true
    self.fsm:ChangeState( "wait" )
end

function objective_if_progress_status:OnExecuteWait( state )
    if self.nodeEnabled == false then
        state:Exit()
        return
    end

    local objectiveId = ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( self.objectiveName )
    local database = ObjectiveService:GetObjectiveDatabase( objectiveId )
    if database ~= nil then
        local progressCurrent = database:GetInt( "progress_current" )
        if self.comparisonType == "equal" and ( progressCurrent == self.progressAmount ) then
            self:SetFinished("true")
        elseif self.comparisonType == "not_equal" and ( progressCurrent ~= self.progressAmount ) then
            self:SetFinished("true")
        elseif self.comparisonType == "greater" and ( progressCurrent > self.progressAmount ) then
            self:SetFinished("true")
        elseif self.comparisonType == "greater_or_equal" and ( progressCurrent >= self.progressAmount ) then
            self:SetFinished("true")
        elseif self.comparisonType == "less" and ( progressCurrent < self.progressAmount ) then
            self:SetFinished("true")
        elseif self.comparisonType == "less_or_equal" and ( progressCurrent <= self.progressAmount ) then
            self:SetFinished("true")
        elseif self.waitUntilTrue == "false" then
            self:SetFinished("false")
        end
    elseif self.waitUntilTrue == "false" then
        self:SetFinished("false")
    end

    if self.waitUntilTrue == "false" then
        state:Exit()
    end  
    
end

function objective_if_progress_status:OnDisablenodes( event )
    self.nodeEnabled = false
end

function objective_if_progress_status:OnDisableNamednode( event )
    if self.data:GetString( "self_id" ) == event:GetObject() then
        self.nodeEnabled = false
    end
end

return objective_if_progress_status