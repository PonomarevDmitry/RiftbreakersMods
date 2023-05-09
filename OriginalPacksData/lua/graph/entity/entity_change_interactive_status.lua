require("lua/utils/find_utils.lua")

class 'entity_change_interactive_status' ( LuaGraphNode )

function entity_change_interactive_status:__init()
    LuaGraphNode.__init(self, self)
end

function entity_change_interactive_status:init()	
	self.searchTargetType = self.data:GetString("search_target_type")
	self.searchTargetValue = self.data:GetString("search_target_value")
	self.targetFindType = self.data:GetString("find_type") 
	self.targetFindValue = self.data:GetString("find_value") 
	self.searchRadius = self.data:GetFloatOrDefault("search_radius", 0)
    
    self.status = self.data:GetIntOrDefault("status", 0) == 1
end

function entity_change_interactive_status:Activated()	
    self.entities = FindEntitiesByTarget(self.targetFindType, self.targetFindValue, 0.0, self.searchRadius, self.searchTargetType, self.searchTargetValue);
    
	if ( #self.entities == 0 ) then
		Assert( self.entities ~= 0, "ERROR: Change interactive status block failed to find a target - skipping block" )
		self:SetFinished()
		return
	end
	for entity in Iter(self.entities) do
        EntityService:ChangeInteractiveEntityStatus(entity, self.status )
	end	
	
	self:SetFinished()
end

return entity_change_interactive_status