require( "lua/utils/find_utils.lua")

class 'logic_if_building_power' ( LuaGraphNodeSelector )

function logic_if_building_power:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_building_power:init()
    self.waitUntilTrue = self.data:GetString("wait_until_true")
    self.searchRadius = self.data:GetFloat("search_radius")

	self.searchTargetType = self.data:GetString("search_target_type")
	self.searchTargetValue = self.data:GetString("search_target_value")
	self.targetFindType = self.data:GetString("find_type") 
	self.targetFindValue = self.data:GetString("find_value") 

    self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "wait", { from="*", execute="OnExecuteWait" } )
	
end


function logic_if_building_power:Activated()
    self.nodeEnabled = true

    self.fsm:ChangeState( "wait" )
end

function logic_if_building_power:OnExecuteWait( state )
    if self.nodeEnabled == false then
        state:Exit()
        return
    end
    
    local entitiesFound = FindBuilding(self.targetFindType, self.targetFindValue, self.searchRadius, self.searchTargetType, self.searchTargetValue);
	if self:CheckPower( entitiesFound ) == true then
		self:SetFinished("true")
	elseif self.waitUntilTrue == "false" then    
		self:SetFinished("false")
	end
    
end

function logic_if_building_power:CheckPower( buildingId )
	if #buildingId > 0 then								
		for i = 1, #buildingId do				
			if BuildingService:IsBuildingPowered( buildingId[i] ) == false then
				return false
			end
		end
		return true
	end		    
end

function logic_if_building_power:OnDisablenodes( event )
    self.nodeEnabled = false
end

function logic_if_building_power:OnDisableNamednode( event )
    if self.data:GetString( "self_id" ) == event:GetObject() then
        self.nodeEnabled = false
    end
end

return logic_if_building_power