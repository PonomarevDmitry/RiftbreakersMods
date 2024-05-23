class 'gather_optional_resource' ( LuaObjectiveScript )
require("lua/utils/find_utils.lua")
require("lua/utils/table_utils.lua")

function gather_optional_resource:__init()
	LuaObjectiveScript.__init(self,self)
end

function gather_optional_resource:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="onUpdate" } )
	self.fsm:ChangeState( "update" )
		
	--self.resourceName = self.data:GetString( "resource_name" )
	--self.resourceAmount = self.data:GetInt( "progress_max" )
    self.resources = self.data:GetStringKeys()

    self.searchRadius = self.data:GetFloatOrDefault("search_radius", 0)
    self.searchTargetType = self.data:GetString("search_target_type")
    self.searchTargetValue = self.data:GetString("search_target_value")

    self.targetFindType = self.data:GetString("find_type") 
    self.targetFindValue = self.data:GetString("find_value") 
	
	if self.searchTargetType == "LocalName" then
		self.searchTargetType = "Name"
		self.searchTargetValue = self.parent:CreateGraphUniqueString(self.searchTargetValue)
	end

    if self.targetFindType == "LocalName" then
		self.targetFindType = "Name"
		self.targetFindValue = self.parent:CreateGraphUniqueString(self.targetFindValue)
	end
	
	for resource in Iter(self.resources) do 
		if ( resource ~= "parent_objective_id" and tonumber(self.data:GetString( resource )) ~= nil  ) then
			if ( self.resourceAmount == nil ) then
				self.resourceAmount = tonumber(self.data:GetString(resource))
				self.data:SetInt( "progress_max", self.resourceAmount )
				self.data:SetString("resource", resource )
			end	
		end
	end

	self.entities = FindEntitiesByTarget(self.targetFindType, self.targetFindValue, 0.0, self.searchRadius, self.searchTargetType, self.searchTargetValue);
    
end

function gather_optional_resource:onUpdate()
	if ( #self.entities == 0 ) then
		ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_IN_PROGRESS )
		self.data:SetInt( "progress_current", 0 )
		self.entities = FindEntitiesByTarget(self.targetFindType, self.targetFindValue, 0.0, self.searchRadius, self.searchTargetType, self.searchTargetValue);
		return
	end
	
	local maxAmount = 0;
	
	for entity in Iter(self.entities) do
		if ( EntityService:IsAlive( entity ) == false ) then
			Remove(self.entities, entity );
			break;
		end

        for resource in Iter(self.resources) do 
			if ( resource ~= "parent_objective_id" and tonumber(self.data:GetString( resource )) ~= nil  ) then
                local connected = BuildingService:GetResourceConnected(entity, resource )
				if ( self.resourceAmount == nil ) then
                    self.resourceAmount = tonumber(self.data:GetString(resource))
					self.data:SetInt( "progress_max", self.resourceAmount )
					self.data:SetString("resource", resource )
				end	

		        if ( connected > maxAmount ) then
		        	maxAmount = connected;
                    self.resourceAmount = tonumber(self.data:GetString(resource))
					self.data:SetInt( "progress_max", self.resourceAmount )
					self.data:SetString("resource", resource )
		        end
            end
        end
	end
	self.data:SetInt( "progress_current", maxAmount )
	if ( maxAmount >= self.resourceAmount ) then
	   ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_SUCCESS )
	else
	   ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_IN_PROGRESS )
    end
	
end


return gather_optional_resource
