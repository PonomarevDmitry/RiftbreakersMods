require("lua/utils/find_utils.lua")

class 'entity_highlight' ( LuaGraphNode )

function entity_highlight:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function entity_highlight:init()

	self.highlightTime = self.data:GetFloat("highlight_time")
    
    self.searchRadius = self.data:GetFloat("search_radius")
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
end

function entity_highlight:Activated()
    local entitiesFound = FindEntitiesByTarget(self.targetFindType, self.targetFindValue, 0.0, self.searchRadius, self.searchTargetType, self.searchTargetValue)	
	
	for entity in Iter(entitiesFound) do
		LogService:Log("Highlighting target " ..   "id: " .. tostring(entity).. " HighlightTime: " .. tostring(self.highlightTime) )
		EntityService:HighlightEntity( entity, self.highlightTime )
	end		
	
    self:SetFinished()
end

return entity_highlight