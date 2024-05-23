require("lua/utils/find_utils.lua")

class 'entity_change_name' ( LuaGraphNode )

function entity_change_name:__init()
    LuaGraphNode.__init(self, self)
end

function entity_change_name:init()	
	self.searchTargetType = self.data:GetString("search_target_type")
	self.searchTargetValue = self.data:GetString("search_target_value")
	self.targetFindType = self.data:GetString("find_type") 
	self.targetFindValue = self.data:GetString("find_value") 
	self.searchRadius = self.data:GetFloatOrDefault("search_radius", 0)
	self.singleTarget = self.data:GetIntOrDefault("target_single", 0)
    
    self.newName = self.data:GetStringOrDefault("new_name", "")
	if self.data:GetIntOrDefault("name_is_global", 1) == 0 then
		self.newName = self.parent:CreateGraphUniqueString(self.newName)
	end

	if self.searchTargetType == "LocalName" then
		self.searchTargetType = "Name"
		self.searchTargetValue = self.parent:CreateGraphUniqueString(self.searchTargetValue)
	end

    if self.targetFindType == "LocalName" then
		self.targetFindType = "Name"
		self.targetFindValue = self.parent:CreateGraphUniqueString(self.targetFindValue)
	end
end

function entity_change_name:Activated()	
    self.entities = FindEntitiesByTarget(self.targetFindType, self.targetFindValue, 0.0, self.searchRadius, self.searchTargetType, self.searchTargetValue)
    --LogService:Log("Activate change name: " .. self.targetFindType .. ":" .. self.targetFindValue .. ":" .. tostring(self.searchRadius) .. ":" .. self.searchTargetType .. ":" .. self.searchTargetValue .. ":" .. tostring(#self.entities))

	if ( #self.entities == 0 ) then
		Assert( #self.entities ~= 0, "ERROR: Change name block failed to find a target - skipping block" )
		self:SetFinished()
		return
	end	
	
	for entity in Iter(self.entities) do
		EntityService:SetName( entity, self.newName  )
		--LogService:Log( "Changed name to: " .. self.newName )
		if self.singleTarget == 1 then
			self:SetFinished()
			return
		end
		
	end		
	self:SetFinished()
end

return entity_change_name