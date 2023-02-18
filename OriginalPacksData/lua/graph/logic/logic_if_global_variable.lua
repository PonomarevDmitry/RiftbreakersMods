class 'logic_if_global_variable' ( LuaGraphNodeSelector )

function logic_if_global_variable:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_global_variable:init()
end

function logic_if_global_variable:init()
    
    self.comparisonType = self.data:GetString("comparison_type")
    self.floatValue = self.data:GetFloatOrDefault("float_value", 0.0 )    
    self.waitUntilTrue = self.data:GetString("wait_until_true")
    self.stringValue = self.data:GetStringOrDefault("string_value","")
    self.emptyStringValue = self.data:GetIntOrDefault("empty_string_value",0)
    self.keyValue = self.data:GetString("variable_name")
    self.campaignDataSource = self.data:GetIntOrDefault("campaign_data_source",1) == 1

    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", execute="OnExecuteWait" } )
end

function logic_if_global_variable:Activated()
    self.nodeEnabled = true
    --self:RegisterHandler( "OnDisablenodes" )
    --self:RegisterHandler( "OnDisableNamednode" )

    -- LogService:Log( self.comparisonType )
    -- LogService:Log( self.waitUntilTrue )
    -- LogService:Log( self.stringValue )
    -- LogService:Log( self.keyValue )
    -- LogService:Log( tostring(self.floatValue ) )

    self.fsm:ChangeState( "wait" )
end

function logic_if_global_variable:OnExecuteWait( state )
    if self.nodeEnabled == false then
        state:Exit()
        return
    end
    local campaignData = nil
    if ( self.campaignDataSource == true ) then
        campaignData = CampaignService:GetCampaignData()
    else
        campaignData = self.parent:GetDatabase()
    end

    if ( self.stringValue ~= "" or self.emptyStringValue == 1) then
        local value = campaignData:GetStringOrDefault(self.keyValue, "" )
        --LogService:Log( "String comparison for key : " .. self.keyValue .. " values: " .. self.stringValue .. " == " .. value  )

        if ( value == self.stringValue ) then
            self:SetFinished("true")
        elseif self.waitUntilTrue == "false" then
            self:SetFinished("false")
        end
    else
        local value = campaignData:GetFloatOrDefault(self.keyValue, 0 )
        --LogService:Log( "Float comparison for key : " .. self.keyValue .. " values: " .. tostring(self.floatValue) .. " " .. self.comparisonType .. " " .. tostring(value)  )

        if self.comparisonType == "equal" and ( self.floatValue == value ) then
            --LogService:Log("IF STATEMENT POSITIVE")
            self:SetFinished("true")
        elseif self.comparisonType == "not_equal" and ( self.floatValue ~= value ) then
            --LogService:Log("IF STATEMENT POSITIVE")
            self:SetFinished("true")
        elseif self.comparisonType == "greater" and ( self.floatValue > value ) then
            --LogService:Log("IF STATEMENT POSITIVE")
            self:SetFinished("true")
        elseif self.comparisonType == "greater_or_equal" and ( self.floatValue >= value ) then
            --LogService:Log("IF STATEMENT POSITIVE")
            self:SetFinished("true")
        elseif self.comparisonType == "less" and ( self.floatValue < value ) then
            --LogService:Log("IF STATEMENT POSITIVE")
            self:SetFinished("true")
        elseif self.comparisonType == "less_or_equal" and ( self.floatValue <= value ) then
            --LogService:Log("IF STATEMENT POSITIVE")
            self:SetFinished("true")
        elseif self.waitUntilTrue == "false" then
            self:SetFinished("false")
            --LogService:Log("IF STATEMENT NEGATIVE")
        end    
    
    end
   -- LogService:Log("WAIT UNTIL TRUE = " .. self.waitUntilTrue )
    
    if self.waitUntilTrue == "false" then
        state:Exit()
    end
    
end

function logic_if_global_variable:OnDisablenodes( event )
    
    self.nodeEnabled = false
end

function logic_if_global_variable:OnDisableNamednode( event )
    if self.data:GetString( "self_id" ) == event:GetObject() then
        self.nodeEnabled = false
    end
end

function logic_if_global_variable:OnLoad(  )
    if ( self.campaignDataSource == nil ) then
        self.campaignDataSource = self.data:GetIntOrDefault("campaign_data_source",1) == 1
    end

    if ( self.emptyStringValue == nil ) then
        self.emptyStringValue = self.data:GetIntOrDefault("empty_string_value",0)
    end
end


return logic_if_global_variable