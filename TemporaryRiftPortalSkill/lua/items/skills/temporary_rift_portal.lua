local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")

class 'temporary_rift_portal' ( item )

function temporary_rift_portal:__init()
    item.__init(self,self)
end

function temporary_rift_portal:OnActivate()

    local blueprintName = "misc/rift"

    local playerId = self:GetOwnerPlayerId()
    if ( playerId == -1 ) then
        return
    end

    self:DissolveRirtPortalEntities(blueprintName, playerId)

    local entities = FindService:FindEntitiesByBlueprint( blueprintName )

    local team = EntityService:GetTeam( self.entity )

    local playerPosition = EntityService:GetPosition( self.owner )

    local newPortal = EntityService:SpawnEntity( blueprintName, playerPosition, team )

    local playerReferenceComponentRef = reflection_helper(EntityService:CreateComponent(newPortal, "PlayerReferenceComponent"))
    playerReferenceComponentRef.player_id = playerId
    playerReferenceComponentRef.reference_type.internal_enum = 3
end

function temporary_rift_portal:DissolveRirtPortalEntities(blueprintName, playerId)

    local entities = FindService:FindEntitiesByBlueprint( blueprintName )

    for entity in Iter( entities ) do

        local playerReferenceComponent = EntityService:GetComponent( entity, "PlayerReferenceComponent" )
        if (playerReferenceComponent) then

            local playerReferenceComponentRef = reflection_helper(playerReferenceComponent)

            if (playerReferenceComponentRef and playerReferenceComponentRef.player_id == playerId) then

                QueueEvent( "DissolveEntityRequest", entity, 0.5, 0 )
            end
        end
    end
end

function temporary_rift_portal:GetOwnerPlayerId()

    local playerId = -1

    local playerReferenceComponent = EntityService:GetComponent( self.owner, "PlayerReferenceComponent" )
    if (playerReferenceComponent) then

        local playerReferenceComponentRef = reflection_helper(playerReferenceComponent)
        playerId = playerReferenceComponentRef.player_id
    end

    return playerId
end

return temporary_rift_portal