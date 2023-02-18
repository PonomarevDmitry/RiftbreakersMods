require("lua/utils/find_utils.lua")
require("lua/utils/enumerables.lua")

class 'entity_make_loot_container' ( LuaGraphNode )

function entity_make_loot_container:__init()
    LuaGraphNode.__init(self, self)
end

function entity_make_loot_container:init()	
	self.searchTargetType = self.data:GetString("search_target_type")
	self.searchTargetValue = self.data:GetString("search_target_value")
	self.targetFindType = self.data:GetString("find_type") 
	self.targetFindValue = self.data:GetString("find_value") 
	self.searchRadius = self.data:GetFloatOrDefault("search_radius", 0)
    
    self.rarity = StringToItemRarity(self.data:GetString("rarity"))
end

function entity_make_loot_container:Activated()	
    self.entities = FindEntitiesByTarget(self.targetFindType, self.targetFindValue, self.searchRadius, self.searchTargetType, self.searchTargetValue);
    
	if ( #self.entities == 0 ) then
		Assert( self.entities ~= 0, "ERROR: Change name block failed to find a target - skipping block" )
		self:SetFinished()
		return
	end
	for entity in Iter(self.entities) do
		EntityService:MarkEntityAsLootContainer( entity, self.rarity  )
	end	
	
	self:SetFinished()
end

return entity_make_loot_container