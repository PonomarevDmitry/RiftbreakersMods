require("lua/utils/find_utils.lua")
require("lua/utils/string_utils.lua")

class 'logic_if_exist_entity_new' ( LuaGraphNodeSelector )

function logic_if_exist_entity_new:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_exist_entity_new:init()
    self.comparisonType = self.data:GetString("comparison_type")
    self.count = self.data:GetInt("count")    
    self.waitUntilTrue = self.data:GetString("wait_until_true")
    self.searchRadius = self.data:GetFloat("search_radius")
    self.searchTargetType = self.data:GetString("search_target_type")

    self.targetFindType = self.data:GetString("find_type") 
    self.targetFindValue = self.data:GetString("find_value") 
    self.searchTargetValue = self.data:GetString("search_target_value")
    self.targetRelationship = self.data:GetStringOrDefault("find_relationship", "")

    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", execute="OnExecuteWait" } )
end


function logic_if_exist_entity_new:Activated()
    self.nodeEnabled = true
    self.fsm:ChangeState( "wait" )
end

function logic_if_exist_entity_new:OnExecuteWait( state )
    if self.nodeEnabled == false then
        state:Exit()
        return
    end

    local allEntities, searchTarget = FindEntitiesByTarget(self.targetFindType, self.targetFindValue, 0.0, self.searchRadius, self.searchTargetType, self.searchTargetValue);

    local entitiesFound = {}
    for i,entity in ipairs(allEntities) do
        local isValidRelationship = true

        if not IsNullOrEmpty( self.targetRelationship ) then
            isValidRelationship = false
            for target in Iter(searchTarget) do
                isValidRelationship = isValidRelationship or EntityService:IsInTeamRelation(entity, target,self.targetRelationship, "player" )
            end
        end

        if isValidRelationship then 
            Insert(entitiesFound, entity)
        end
    end
    
    if self.comparisonType == "equal" and ( #entitiesFound == self.count ) then
        self:SetFinished("true")
    elseif self.comparisonType == "not_equal" and ( #entitiesFound ~= self.count ) then
        self:SetFinished("true")
    elseif self.comparisonType == "greater" and ( #entitiesFound > self.count ) then
        self:SetFinished("true")
    elseif self.comparisonType == "greater_or_equal" and ( #entitiesFound >= self.count ) then
        self:SetFinished("true")
    elseif self.comparisonType == "less" and ( #entitiesFound < self.count ) then
        self:SetFinished("true")
    elseif self.comparisonType == "less_or_equal" and ( #entitiesFound <= self.count ) then
        self:SetFinished("true")
    elseif self.waitUntilTrue == "false" then
        self:SetFinished("false")
    end  

    if self.waitUntilTrue == "false" then
        state:Exit()
    end  
    
end

function logic_if_exist_entity_new:OnDisablenodes( event )
    self.nodeEnabled = false
end

function logic_if_exist_entity_new:OnDisableNamednode( event )
    if self.data:GetString( "self_id" ) == event:GetObject() then
        self.nodeEnabled = false
    end
end

return logic_if_exist_entity_new