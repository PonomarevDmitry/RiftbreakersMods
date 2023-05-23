local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

class 'rift_jump_to_nearest_portal' ( item )

function rift_jump_to_nearest_portal:__init()
    item.__init(self,self)
end

function rift_jump_to_nearest_portal:OnEquipped()
end

function rift_jump_to_nearest_portal:OnActivate()

    local playable_min = MissionService:GetPlayableRegionMin()
    local playable_max = MissionService:GetPlayableRegionMax()

    local predicate = {

        signature="RiftPointComponent",

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

    local entities = FindService:FindEntitiesByPredicateInBox( playable_min, playable_max, predicate )

    if ( #entities == 1 ) then

        self:JumpToEntity( entities[1] )
        
    elseif ( #entities > 1 ) then

        local nearestPortal = self:FindNearest( entities )

        self:JumpToEntity( nearestPortal )
    end
end

function rift_jump_to_nearest_portal:FindNearest(entities)

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

function rift_jump_to_nearest_portal:JumpToEntity(entity)

    local portalPosition = EntityService:GetPosition( entity )

    self:SpawnPortal( "misc/rift" )

    PlayerService:TeleportPlayer( self.owner, portalPosition , 0.2, 0.1, 0.2 )
end

function rift_jump_to_nearest_portal:SpawnPortal(blueprintName)

    local entities = FindService:FindEntitiesByBlueprint( blueprintName )

    for i=1,#entities do
        QueueEvent( "DissolveEntityRequest", entities[i], 0.5, 0 )
    end

    local team = EntityService:GetTeam( self.entity )

    local playerPosition = EntityService:GetPosition( self.owner )

    local newPortal = EntityService:SpawnEntity( blueprintName, playerPosition, team )
end

return rift_jump_to_nearest_portal