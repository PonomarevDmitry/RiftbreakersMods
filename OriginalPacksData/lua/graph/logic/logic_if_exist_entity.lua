class 'logic_if_exist_entity' ( LuaGraphNode )

function logic_if_exist_entity:__init()
    LuaGraphNode.__init(self, self)
end

function logic_if_exist_entity:init()
    
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", execute="OnExecuteWait" } )
end

function logic_if_exist_entity:Activated()
    self.nodeEnabled = true
    --self:RegisterHandler( "OnDisablenodes" )
    --self:RegisterHandler( "OnDisableNamednode" )

    self.comparisonType = self.data:GetString("comparison_type")
    self.count = self.data:GetInt("count")    
    self.waitUntilTrue = self.data:GetString("wait_until_true")
    self.searchRadius = self.data:GetFloat("search_radius")
    self.searchTargetName = self.data:GetString("search_target")
    self.searchTarget = INVALID_ID
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
    
    --LogService:Log("comparison_type " ..    self.data:GetString("comparison_type") );
    --LogService:Log("count " ..              tostring(self.data:GetInt("count"))    );
    --LogService:Log("search_radius " ..      tostring(self.data:GetFloat("search_radius")) );
    --LogService:Log("wait_until_true " ..    self.data:GetString("wait_until_true") );
    --LogService:Log("search_target " ..      self.data:GetString("search_target") );
    --LogService:Log("target_name " ..        self.data:GetString("target_name") );
    --LogService:Log("target_group " ..       self.data:GetString("target_group") );
    --LogService:Log("target_type " ..        self.data:GetString("target_type") );
    --LogService:Log("target_blueprint " ..   self.data:GetString("target_blueprint") );

    self.fsm:ChangeState( "wait" )
end

function logic_if_exist_entity:OnExecuteWait( state )
    if self.nodeEnabled == false then
        state:Exit()
        return
    end
    
    -- CUSTOM PATCH for acid_scout.logic, we have removed `player_trigger` child entity from mech
    if self.searchTargetName == "player_trigger" then
        self.searchTarget = PlayerService:GetPlayerControlledEnt(0)
    elseif self.searchTargetName ~= "" then
        self.searchTarget = FindService:FindEntityByName( self.searchTargetName )
    end

    if self.searchTargetName ~= "" and not EntityService:IsAlive( self.searchTarget ) then
        return
    end
    
    local entitiesFound = self:Find()
    if self.comparisonType == "equal" and ( #entitiesFound == self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished()
    elseif self.comparisonType == "not_equal" and ( #entitiesFound ~= self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished()
    elseif self.comparisonType == "greater" and ( #entitiesFound > self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished()
    elseif self.comparisonType == "greater_or_equal" and ( #entitiesFound >= self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished()
    elseif self.comparisonType == "less" and ( #entitiesFound < self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished()
    elseif self.comparisonType == "less_or_equal" and ( #entitiesFound <= self.count ) then
        --LogService:Log("IF STATEMENT POSITIVE")
        self:SetFinished()
    else
        --LogService:Log("IF STATEMENT NEGATIVE")
    end    

    --LogService:Log("WAIT UNTIL TRUE = " .. self.waitUntilTrue )
    
    if self.waitUntilTrue == "false" then
        --LogService:Log("EXITING" )
        state:Exit()
    end
    
end

function logic_if_exist_entity:Find()    
    -- Search anywhere on the map
    if self.searchRadius == 0 then
        if self.targetName ~= "" then        
            --LogService:Log("TARGET NAME = " .. self.targetName)
            local objectId = FindService:FindEntitiesByName( self.targetName )
            return objectId        
        elseif self.targetGroup ~= "" then        
            --LogService:Log("TARGET GROUP = " .. self.targetGroup)
            local objectId = FindService:FindEntitiesByGroup( self.targetGroup )
            return objectId        
        elseif self.targetType ~= "" then        
            --LogService:Log("TARGET TYPE = " .. self.targetType)            
            if self.targetType == "core" then                
                if EntityService:IsAlive( MissionService:GetCoreId() ) == true then
                    return {1}
                else
                    return {}
                end
            else
                local objectId = FindService:FindEntitiesByType( self.targetType )    
                --LogService:Log("NUMBER OF ENTITIES FOUND = " .. tostring(#objectId))
                return objectId
            end                
        elseif self.targetBlueprint ~= "" then
            --LogService:Log("TARGET BLUEPRINT = " .. self.targetBlueprint)
            local objectId = FindService:FindEntitiesByBlueprint( self.targetBlueprint )
            return objectId        
        else
            return {}
        end
    -- Search in radius
    else 
        if self.targetName ~= "" then        
            --LogService:Log("TARGET NAME = " .. self.targetName)
            local objectId = {}
            objectId[1] = FindService:FindEntityByNameInDistance( self.searchTarget, self.targetName, self.searchRadius )
            if ( objectId[1] ~= INVALID_ID ) then
                return objectId
            else
                return {}
            end     
        elseif self.targetGroup ~= "" then        
            --LogService:Log("TARGET GROUP = " .. self.targetGroup)
            local objectId = FindService:FindEntitiesByGroupInRadius( self.searchTarget, self.targetGroup, self.searchRadius )
            return objectId        
        elseif self.targetType ~= "" then                
            --LogService:Log("TARGET TYPE = " .. self.targetType)
            local objectId = FindService:FindEntitiesByTypeInRadius( self.searchTarget, self.targetType, self.searchRadius )
            --LogService:Log("NUMBER OF ENTITIES FOUND = " .. tostring(#objectId))
            return objectId        
        elseif self.targetBlueprint ~= "" then
            --LogService:Log("TARGET BLUEPRINT = " .. self.targetBlueprint)
            local objectId = FindService:FindEntitiesByBlueprintInRadius( self.searchTarget, self.targetBlueprint, self.searchRadius )
            return objectId        
        else
            return {}
        end
    end
end

function logic_if_exist_entity:OnDisablenodes( event )
    self.nodeEnabled = false
end

function logic_if_exist_entity:OnDisableNamednode( event )
    if self.data:GetString( "self_id" ) == event:GetObject() then
        self.nodeEnabled = false
    end
end

return logic_if_exist_entity