require("lua/utils/find_utils.lua")

class 'enemies_change_ai_groups_to_aggressive' ( LuaGraphNode )

function enemies_change_ai_groups_to_aggressive:__init()
    LuaGraphNode.__init(self, self)
end

function enemies_change_ai_groups_to_aggressive:init()

	self.aggressiveRadius = self.data:GetFloatOrDefault("aggressive_radius", 128)
	
	self.searchRadius = self.data:GetFloatOrDefault("search_radius", 0)
    self.searchTarget = self.data:GetStringOrDefault("search_target", "")
	
	self.entityName = self.data:GetStringOrDefault("entity_name", "")
    self.entityGroup = self.data:GetStringOrDefault("entity_group", "")
    self.entityType = self.data:GetStringOrDefault("entity_type", "")
    self.entityBlueprint = self.data:GetStringOrDefault("entity_bp", "")  
	self.disbandGroup = false
	
	if ( self.data:GetStringOrDefault("disband_group", "false") == "true" ) then
		self.disbandGroup = true
	end

end

function enemies_change_ai_groups_to_aggressive:Activated()
	self.entities = FindEntity( self.searchRadius, self.searchTarget, self.entityName, self.entityGroup, self.entityType, self.entityBlueprint )
	
	if ( #self.entities == 0 ) then
		Assert( self.entities ~= 0, "ERROR: AI groups to aggressive - target missing, skipping logic block" )
		self:SetFinished()
		return
	end
	for entity in Iter(self.entities) do
		EntityService:ChangeAIGroupsToAggressive( entity, self.aggressiveRadius, true )
	end	
	self:SetFinished()
end


return enemies_change_ai_groups_to_aggressive