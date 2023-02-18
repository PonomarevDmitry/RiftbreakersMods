class 'logic_if_alive' ( LuaGraphNodeSelector )

function logic_if_alive:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_alive:init()
	self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", execute="OnExecuteWait" } )
end

function logic_if_alive:Activated()
    self.nodeEnabled = true
    --self:RegisterHandler( "OnDisablenodes" )
    --self:RegisterHandler( "OnDisableNamednode" )

    --self.comparisonType = self.data:GetString("comparison_type")
    --self.count = self.data:GetInt("count")    
    self.waitUntilDead = self.data:GetString("wait_until_dead")
    self.searchRadius = self.data:GetFloat("search_radius")
    self.searchTarget = self.data:GetString("search_target")
    
    if self.searchTarget ~= "" then
        self.searchTarget = FindService:FindEntityByName( self.searchTarget )
    end
    
    self.targetName = ""
    self.targetGroup = ""
    self.targetType = ""
    self.targetBlueprint = ""    
    if self.data:HasString( "target_name" ) then
        self.targetName = self.data:GetString("target_name")
    end
    if self.data:HasString( "target_group" ) then
        self.targetGroup = self.data:GetString("target_group")
    end
    if self.data:HasString( "target_type" ) then
        self.targetType = self.data:GetString("target_type")
    end
    if self.data:HasString( "target_blueprint" ) then
        self.targetBlueprint = self.data:GetString("target_blueprint")
    end        
    
   -- LogService:Log("comparison_type " ..    self.data:GetString("comparison_type") );
    --LogService:Log("count " ..              tostring(self.data:GetInt("count"))    );
    --LogService:Log("search_radius " ..      tostring(self.data:GetFloat("search_radius")) );
    --LogService:Log("wait_until_dead " ..    self.data:GetString("wait_until_dead") );
    --LogService:Log("search_target " ..      self.data:GetString("search_target") );
    --LogService:Log("target_name " ..        self.data:GetString("target_name") );
    --LogService:Log("target_group " ..       self.data:GetString("target_group") );
    --LogService:Log("target_type " ..        self.data:GetString("target_type") );
    --LogService:Log("target_blueprint " ..   self.data:GetString("target_blueprint") );
	
	--LogService:Log("WAIT UNTIL DEAD = " .. self.waitUntilDead )
    if self.waitUntilDead == "true" then
		--LogService:Log("LET'S WAIT UNTIL THE TARGET DIES" )
		self.fsm:ChangeState( "wait" )
	else 
		LogService:Log("DO NOT WAIT UNTIL THE TARGET DIES" )
		local entityId = self:Find()
		local isAlive = entityId ~= INVALID_ID and HealthService:IsAlive( entityId )
		if isAlive == false then
			--LogService:Log("TARGET IS DEAD OR DOES NOT EXIST")
			self:SetFinished("false")
		else
			--LogService:Log("TARGET IS ALIVE")
			self:SetFinished("true")
		end
	end
end

function logic_if_alive:OnExecuteWait( state )
   -- if self.nodeEnabled == false then
   --     state:Exit()
   --     return
   -- end
    
    local entityId = self:Find()
	local isAlive = entityId ~= INVALID_ID and HealthService:IsAlive( entityId )
    
    --if self.comparisonType == "equal" and ( #entitiesFound == self.count ) then
    --    --LogService:Log("IF STATEMENT POSITIVE")
    --    self:SetFinished("true")
    --elseif self.comparisonType == "not_equal" and ( #entitiesFound ~= self.count ) then
    --    --LogService:Log("IF STATEMENT POSITIVE")
    --    self:SetFinished("true")
    --elseif self.comparisonType == "greater" and ( #entitiesFound > self.count ) then
    --    --LogService:Log("IF STATEMENT POSITIVE")
    --    self:SetFinished("true")
    --elseif self.comparisonType == "greater_or_equal" and ( #entitiesFound >= self.count ) then
    --    --LogService:Log("IF STATEMENT POSITIVE")
    --    self:SetFinished("true")
    --elseif self.comparisonType == "less" and ( #entitiesFound < self.count ) then
    --    --LogService:Log("IF STATEMENT POSITIVE")
    --    self:SetFinished("true")
    --elseif self.comparisonType == "less_or_equal" and ( #entitiesFound <= self.count ) then
    --    --LogService:Log("IF STATEMENT POSITIVE")
    --    self:SetFinished("true")
    --elseif self.waitUntilDead == "false" then
    --    self:SetFinished("false")
    --    --LogService:Log("IF STATEMENT NEGATIVE")
    --end    
	
	
	if isAlive == false then
		--LogService:Log("TARGET IS DEAD OR DOES NOT EXIST")
		self:SetFinished("false")	
	else
		--LogService:Log("TARGET IS ALIVE")
    end    
end

function logic_if_alive:Find()    
    -- Search anywhere on the map
    if self.searchRadius == 0 then
        if self.targetName ~= "" then        
            return FindService:FindEntityByName( self.targetName )
        elseif self.targetGroup ~= "" then        
            return FindService:FindEntityByGroup( self.targetGroup )
        elseif self.targetType ~= "" then        
            return FindService:FindEntityByType( self.targetType )    
        elseif self.targetBlueprint ~= "" then
            return FindService:FindEntityByBlueprint( self.targetBlueprint )
        end
    -- Search in radius
    else 
        if self.targetName ~= "" then        
            return FindService:FindEntityByNameInDistance( self.searchTarget, self.targetName, self.searchRadius )
        elseif self.targetGroup ~= "" then        
            local entities = FindService:FindEntitiesByGroupInRadius( self.searchTarget, self.targetGroup, self.searchRadius )
            if #entities >= 1 then
                return entities[1]
            end 
        elseif self.targetType ~= "" then                
            local entities = FindService:FindEntitiesByTypeInRadius( self.searchTarget, self.targetType, self.searchRadius )
            if #entities >= 1 then
                return entities[1]
            end    
        elseif self.targetBlueprint ~= "" then
            local entities = FindService:FindEntitiesByBlueprintInRadius( self.searchTarget, self.targetBlueprint, self.searchRadius )
            if #entities >= 1 then
                return entities[1]
            end
        end
    end

    return INVALID_ID;
end

function logic_if_alive:OnDisablenodes( event )
    self.nodeEnabled = false
end

function logic_if_alive:OnDisableNamednode( event )
    if self.data:GetString( "self_id" ) == event:GetObject() then
        self.nodeEnabled = false
    end
end

return logic_if_alive