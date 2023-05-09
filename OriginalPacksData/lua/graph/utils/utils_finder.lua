require("lua/utils/find_utils.lua")

class 'utils_finder' ( LuaGraphNodeSelector )

function utils_finder:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function utils_finder:init()
    self.searchRadius = self.data:GetFloat("search_radius")
    self.searchTargetType = self.data:GetString("search_target_type")
    self.searchTargetValue = self.data:GetString("search_target_value")
    self.targetFindType = self.data:GetString("find_type") 
    self.targetFindValue = self.data:GetString("find_value") 
end

function utils_finder:Update( state )
    self.foundEntities = FindEntitiesByTarget(self.targetFindType, self.targetFindValue, 0.0, self.searchRadius, self.searchTargetType, self.searchTargetValue);
    self:OnEntitiesFound( self.foundEntities )
end

function utils_finder:OnEntitiesFound( entities )
end

return utils_finder