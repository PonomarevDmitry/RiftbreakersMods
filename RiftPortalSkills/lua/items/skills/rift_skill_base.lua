local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

class 'rift_skill_base' ( item )

function rift_skill_base:__init()
    item.__init(self,self)
end

function rift_skill_base:FindNearest(entities)

    if ( #entities == 0 ) then
        return nil
    end

    local distances = {}

    for entity in Iter( entities ) do
        distances[entity] = EntityService:GetDistanceBetween( self.owner, entity )
    end

    local sorter = function( lh, rh )
        return distances[lh] < distances[rh]
    end

    table.sort(entities, sorter)

    return entities[1]
end

function rift_skill_base:JumpToEntity(entity)

    local portalPosition = EntityService:GetPosition( entity )

    self:SpawnTemporaryPortalIfNeeded()

    PlayerService:TeleportPlayer( self.owner, portalPosition , 0.2, 0.1, 0.2 )
end

function rift_skill_base:SpawnTemporaryPortalIfNeeded()

    local buildingDesc = BuildingService:GetBuildingDesc( "buildings/defense/portal" )

    local buildingDescRef = reflection_helper( buildingDesc )

    local radius = buildingDescRef.min_radius

    local predicate = {

        signature = "RiftPointComponent",

        filter = function(entity)

            local riftPointComponent = EntityService:GetComponent(entity, "RiftPointComponent")
            if ( riftPointComponent == nil ) then
                return false
            end

            local riftPointComponentRef = reflection_helper( riftPointComponent )

            if ( riftPointComponentRef.active == false ) then
                return false;
            end

            if ( riftPointComponentRef.name == "rift" or riftPointComponentRef.name == "headquarters" ) then
                return true;
            end

            return false
        end
    };

    local entities = FindService:FindEntitiesByPredicateInRadius( self.owner, radius, predicate )

    if ( #entities == 0) then

        self:SpawnPortal( "misc/rift" )
    end
end

function rift_skill_base:SpawnPortal(blueprintName)

    local playerId = self:GetOwnerPlayerId()
    if ( playerId == -1 ) then
        return
    end

    self:DissolveRirtPortalEntities(blueprintName, playerId)

    local team = EntityService:GetTeam( self.entity )

    local playerPosition = EntityService:GetPosition( self.owner )

    local newPortal = EntityService:SpawnEntity( blueprintName, playerPosition, team )

    local playerReferenceComponentRef = reflection_helper(EntityService:CreateComponent(newPortal, "PlayerReferenceComponent"))
    playerReferenceComponentRef.player_id = playerId
    playerReferenceComponentRef.reference_type.internal_enum = 3
end

function rift_skill_base:DissolveRirtPortalEntities(blueprintName, playerId)

    local entities = FindService:FindEntitiesByBlueprint( blueprintName )

    for entity in Iter( entities ) do

        local playerReferenceComponent = EntityService:GetComponent( entity, "PlayerReferenceComponent" )
        if (playerReferenceComponent) then

            local playerReferenceComponentRef = reflection_helper(playerReferenceComponent)

            if (playerReferenceComponentRef and playerReferenceComponentRef.player_id == playerId) then

                QueueEvent( "DissolveEntityRequest", entity, 0.2, 0 )
            end
        end
    end
end

function rift_skill_base:GetOwnerPlayerId()

    local playerId = -1

    local playerReferenceComponent = EntityService:GetComponent( self.owner, "PlayerReferenceComponent" )
    if (playerReferenceComponent) then

        local playerReferenceComponentRef = reflection_helper(playerReferenceComponent)
        playerId = playerReferenceComponentRef.player_id
    end

    return playerId
end

return rift_skill_base