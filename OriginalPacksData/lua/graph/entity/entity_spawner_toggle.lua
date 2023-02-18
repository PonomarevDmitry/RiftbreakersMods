class 'entity_spawner_toggle' ( LuaGraphNode )

function entity_spawner_toggle:__init()
    LuaGraphNode.__init(self, self)
end

function entity_spawner_toggle:init()		
end

function entity_spawner_toggle:Activated()
	local state = self.data:GetString( "state" )
	
	self.spawnerId = FindService:FindEntitiesByType( "spawner" )
	
	if state == "enable" then
		self:EnableSpawners()
	elseif state == "disable" then
		self:DisableSpawners()
	end	
end

function entity_spawner_toggle:EnableSpawners()
	if #self.spawnerId > 0 then								
		for i = 1, #self.spawnerId do	
			UnitSpawnerService:EnableUnitSpawner( self.spawnerId[i] )										
		end
	end	
	self:SetFinished()
end

function entity_spawner_toggle:DisableSpawners()
	if #self.spawnerId > 0 then								
		for i = 1, #self.spawnerId do	
			UnitSpawnerService:DisableUnitSpawner( self.spawnerId[i] )										
		end
	end	
	self:SetFinished()
end

return entity_spawner_toggle