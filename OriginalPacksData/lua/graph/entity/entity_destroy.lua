require("lua/utils/find_utils.lua")

class 'entity_destroy' ( LuaGraphNode )

function entity_destroy:__init()
    LuaGraphNode.__init(self, self)
end

function entity_destroy:init()	
	self.searchTargetType = self.data:GetString("search_target_type")
	self.searchTargetValue = self.data:GetString("search_target_value")
	self.targetFindType = self.data:GetString("find_type") 
	self.targetFindValue = self.data:GetString("find_value") 
	self.searchRadius = self.data:GetFloatOrDefault("search_radius", 0)
    
    self.destroyPattern = self.data:GetStringOrDefault("destroy_pattern", "")
    
	self.remove = self.data:GetIntOrDefault("remove", 0 )	
	self.dissolveState = self.data:GetStringOrDefault("dissolve_state", "false")
	self.dissolveDuration = self.data:GetFloatOrDefault("dissolve_duration", 1 )
	
	if self.searchTargetType == "LocalName" then
		self.searchTargetType = "Name"
		self.searchTargetValue = self.parent:CreateGraphUniqueString(self.searchTargetValue)
	end

    if self.targetFindType == "LocalName" then
		self.targetFindType = "Name"
		self.targetFindValue = self.parent:CreateGraphUniqueString(self.targetFindValue)
	end
end

function entity_destroy:Activated()	
    self.entities = FindEntitiesByTarget(self.targetFindType, self.targetFindValue, 0.0, self.searchRadius, self.searchTargetType, self.searchTargetValue);
    
	if ( #self.entities == 0 ) then
		Assert( self.entities ~= 0, "ERROR: Change name block failed to find a target - skipping block" )
		self:SetFinished()
		return
	end
	
	if ( self.remove == 1 ) then
		for entity in Iter(self.entities) do
			self:RemoveEntity(entity)
		end	
		self:SetFinished()
		return
	end
	
	for entity in Iter(self.entities) do
        EntityService:DestroyEntity(entity, self.destroyPattern)
	end	
	
	self:SetFinished()
end

function entity_destroy:RemoveEntity( entityId )
	--LogService:Log("Hello from Remove Entity")
	if self.dissolveState == "true" then
		--LogService:Log("Remove Entity with dissolve")
		EntityService:DissolveEntity( entityId, self.dissolveDuration )
	else
		--LogService:Log("Remove Entity without dissolve")
		EntityService:RemoveEntity( entityId )
	end
end

return entity_destroy