class 'connect_local_resource_to_building' ( LuaObjectiveScript )
require("lua/utils/find_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/campaign_patcher.lua")

function connect_local_resource_to_building:__init()
	LuaObjectiveScript.__init(self,self)
end

function connect_local_resource_to_building:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="onUpdate" } )
	self.fsm:ChangeState( "update" )
	self.entities = {}
	
	self:FillInitialParams()
	self.entities = FindBuilding(self.targetFindType, self.targetFindValue, self.searchRadius, self.searchTargetType, self.searchTargetValue)
end

function connect_local_resource_to_building:FillInitialParams()
	self.resourceName = self.data:GetString( "resource_name" )
	self.resourceAmount = self.data:GetInt( "progress_max" )
	
    self.searchRadius = self.data:GetFloatOrDefault("search_radius", 0)
    self.searchTargetType = self.data:GetString("search_target_type")
    self.searchTargetValue = self.data:GetString("search_target_value")

    self.targetFindType = self.data:GetString("find_type") 
    self.targetFindValue = self.data:GetString("find_value") 
end

function connect_local_resource_to_building:OnLoad()
	PatchJungleFindRareResources( self )
	self:FillInitialParams()
end


function connect_local_resource_to_building:onUpdate()
	if ( #self.entities == 0 ) then
		ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_IN_PROGRESS )
		self.data:SetInt( "progress_current", 0 )
		self.entities = FindBuilding(self.targetFindType, self.targetFindValue, self.searchRadius, self.searchTargetType, self.searchTargetValue)
		return
	end
	
	local maxAmount = 0;
	for entity in Iter(self.entities) do
		if ( EntityService:IsAlive( entity ) == false ) then
			Remove(self.entities, entity );
			break;
		end
		local connected = BuildingService:GetResourceConnected(entity, self.resourceName )
		if ( connected > maxAmount ) then
			maxAmount = connected;
		end
	end
	self.data:SetInt( "progress_current", maxAmount )
	if ( maxAmount >= self.resourceAmount ) then
	   ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_SUCCESS )
	else
	   ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_IN_PROGRESS )
    end
	
end


return connect_local_resource_to_building
