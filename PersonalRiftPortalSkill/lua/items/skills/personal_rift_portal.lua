local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")

class 'personal_rift_portal' ( item )

function personal_rift_portal:__init()
    item.__init(self,self)
end

function personal_rift_portal:OnActivate()

    local blueprintName = "misc/personal_rift"

    local entities = FindService:FindEntitiesByBlueprint( blueprintName )

    for i=1,#entities do
        QueueEvent( "DissolveEntityRequest", entities[i], 0.5, 0 )
    end

    local team = EntityService:GetTeam( self.entity )

    local playerPosition = EntityService:GetPosition( self.owner )

    local newPortal = EntityService:SpawnEntity( blueprintName, playerPosition, team )
end

return personal_rift_portal