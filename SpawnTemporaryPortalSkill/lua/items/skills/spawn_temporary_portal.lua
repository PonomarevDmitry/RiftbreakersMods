local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")

class 'spawn_temporary_portal' ( item )

function spawn_temporary_portal:__init()
    item.__init(self,self)
end

function spawn_temporary_portal:OnInit()
end

function spawn_temporary_portal:OnEquipped()
end

function spawn_temporary_portal:OnActivate()

    local blueprintName = "misc/rift"

    local entities = FindService:FindEntitiesByBlueprint( blueprintName )

    for i=1,#entities do
        QueueEvent( "DissolveEntityRequest", entities[i], 0.5, 0 )
    end

    local team = EntityService:GetTeam( self.entity )

    local playerPosition = EntityService:GetPosition( self.owner )

    local newPortal = EntityService:SpawnEntity( blueprintName, playerPosition, team )
end

return spawn_temporary_portal