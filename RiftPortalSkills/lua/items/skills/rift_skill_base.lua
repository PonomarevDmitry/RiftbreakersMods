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

    local entities = FindService:FindEntitiesByBlueprint( blueprintName )

    for i=1,#entities do
        QueueEvent( "DissolveEntityRequest", entities[i], 0.2, 0 )
    end

    local team = EntityService:GetTeam( self.entity )

    local playerPosition = EntityService:GetPosition( self.owner )

    local newPortal = EntityService:SpawnEntity( blueprintName, playerPosition, team )
end

return rift_skill_base