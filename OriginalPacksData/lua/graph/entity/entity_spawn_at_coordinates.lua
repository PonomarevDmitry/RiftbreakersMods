require("lua/utils/find_utils.lua")

class 'entity_spawn_at_coordinates' ( LuaGraphNode )

function entity_spawn_at_coordinates:__init()
    LuaGraphNode.__init(self, self)
end

function entity_spawn_at_coordinates:init()	
	self.blueprint = self.data:GetString( "blueprint" )	
	self.team = self.data:GetString( "team" )		
	
	self.entityName = self.data:GetString( "entity_name" )
	self.entityGroup = self.data:GetString( "entity_group" )		

	self.coordX = self.data:GetIntOrDefault("coord_x", 0)
	self.coordY = self.data:GetIntOrDefault("coord_y", 0)
	self.coordZ = self.data:GetIntOrDefault("coord_z", 0)
end

function entity_spawn_at_coordinates:Activated()	    		
	self.entityId = EntityService:SpawnEntity( self.blueprint, self.coordX, self.coordY, self.coordZ, self.team )
	
	-- Name the entity
	if entityName ~= "" then
		EntityService:SetName( self.entityId, self.entityName )
		LogService:Log("Setting Entity Name " .. self.entityName .. " to entityID " .. tostring(self.entityId) )		
	end
	
	if entityGroup ~= "" then
		EntityService:SetGroup( self.entityId, self.entityGroup )		
	end				
	
	self:SetFinished()
end

return entity_spawn_at_coordinates