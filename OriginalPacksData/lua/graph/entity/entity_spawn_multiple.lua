class 'entity_spawn_multiple' ( LuaGraphNode )

function entity_spawn_multiple:__init()
    LuaGraphNode.__init(self, self)
end

function entity_spawn_multiple:init()		
end

function entity_spawn_multiple:Activated()
	self.blueprint = self.data:GetString( "blueprint" )
	self.target = self.data:GetString( "target_group" )
	self.entityGroup = self.data:GetString( "entity_group" )
	self.team = self.data:GetString( "team" )

	if self.entityGroup ~= "" then
		EntityService:SpawnEntities( self.blueprint, self.target, self.team, self.entityGroup )
	else
		EntityService:SpawnEntities( self.blueprint, self.target, self.team )
	end		
	
	self:SetFinished()
end

return entity_spawn_multiple