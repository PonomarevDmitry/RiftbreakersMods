require("lua/utils/table_utils.lua")

class 'alien_tower_plasma_spawner' ( LuaEntityObject )

function alien_tower_plasma_spawner:__init()
    LuaEntityObject.__init(self,self)
end

function alien_tower_plasma_spawner:init()
    self:RegisterHandler(self.entity, "TargetHasChangedEvent", "OnTargetHasChangedEvent")
    self:RegisterHandler(self.entity, "LuaGlobalEvent", "OnAlienTowerActivateEvent")
end

function alien_tower_plasma_spawner:SpawnTower()   
    local database = EntityService:GetDatabase( self.entity )
    EntityService:SpawnEntity( database:GetString( "blueprint" ) , self.entity, EntityService:GetTeam( self.entity ) )
    EntityService:RemoveEntity( self.entity )
end

function alien_tower_plasma_spawner:OnTargetHasChangedEvent( evt )
    local database = EntityService:GetDatabase( self.entity )
    local objects = FindService:FindEntitiesByNameInRadius( self.entity, "_alien_tower_spawner_", database:GetFloat( "radius" ) )
    for i = 1, #objects do   
        QueueEvent( "LuaGlobalEvent", objects[i], "AlienTowerActivateEvent", {} )
    end     
end

function alien_tower_plasma_spawner:OnAlienTowerActivateEvent( evt )
    if evt:GetEvent() == "AlienTowerActivateEvent" then
        self:SpawnTower()
    end
end

return alien_tower_plasma_spawner
