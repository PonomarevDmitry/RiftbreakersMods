local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'eraser_rocks_tool' ( tool )

function eraser_rocks_tool:__init()
    tool.__init(self,self)
end

function eraser_rocks_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_eraser_rocks_tool", self.entity)
end

function eraser_rocks_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function eraser_rocks_tool:FindEntitiesToSelect( selectorComponent )

    local predicate = {

        filter = function( entity )

            local blueprintName = EntityService:GetBlueprintName( entity )
            if ( blueprintName == "" or blueprintName == nil ) then
                return false
            end
        
            local stringIndex = string.find( blueprintName, "props/rocks/" )
        
            if ( stringIndex == nil ) then
                return false
            end
        
            if ( stringIndex ~= 1 ) then
                return false
            end

            if ( EntityService:GetComponent( entity, "PhysicsComponent") ~= nil ) then

                local groupId = EntityService:GetPhysicsGroupId( entity )

                if ( groupId == "destructible" ) then

                    return true
                else
                    return false
                end
            end

            return true
        end
    };

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=1000.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local minVector = VectorSub(position, scaleVector)
    local maxVector = VectorAdd(position, scaleVector)

    local tempCollection = FindService:FindEntitiesByPredicateInBox( minVector, maxVector, predicate )

    local possibleSelectedEnts = {}

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto continue
        end

        if ( IndexOf( possibleSelectedEnts, entity ) ~= nil ) then
            goto continue
        end

        Insert( possibleSelectedEnts, entity )

        ::continue::
    end

    local selectorPosition = selectorComponent.position

    local sorter = function( t, lhs, rhs )
        local p1 = EntityService:GetPosition( lhs )
        local p2 = EntityService:GetPosition( rhs )
        local d1 = Distance( selectorPosition, p1 )
        local d2 = Distance( selectorPosition, p2 )
        return d1 < d2
    end

    table.sort(possibleSelectedEnts, function(a,b)
        return sorter(possibleSelectedEnts, a, b)
    end)

    return possibleSelectedEnts
end

function eraser_rocks_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function eraser_rocks_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function eraser_rocks_tool:OnRotate()
end

function eraser_rocks_tool:OnActivateEntity( entity )

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    --ConsoleService:ExecuteCommand("dump_entity " .. tostring(entity))

    if ( is_server and is_client ) then

        if ( EntityService:GetComponent( entity, "PhysicsComponent") ~= nil ) then

            EntityService:DisableCollisions( entity )

            BuildingService:DisablePhysics( entity )

            EntityService:RequestDestroyPattern( entity, "default" )
        end

        EntityService:DissolveEntity( entity, 0.5 )

    else

        QueueEvent("OperateActionMapperRequest", entity, "RocksEraserRequest", false )
    end



    --EntityService:ChangePhysicsGroupId( entity, "destructible" )

    --local cellIndexes = FindService:GetEntityCellIndexes(entity)
    --
    --EntityService:RemoveComponent( entity, "PhysicsComponent" )
    --EntityService:RemoveComponent( entity, "WorldBlockerLayerComponent" )
    --EntityService:RemoveComponent( entity, "BuildingBlockerLayerComponent" )
    --
    --EntityService:SetNavMeshScale( entity, 0.1, 0.1, 0.1 )
    --
    --for cellId in Iter( cellIndexes ) do
    --
    --    EntityService:DisableCollisions( cellId )
    --    BuildingService:DisablePhysics( cellId )
    --    
    --    EntityService:RemoveComponent( cellId, "PhysicsComponent" )
    --    EntityService:RemoveComponent( cellId, "WorldBlockerLayerComponent" )
    --    EntityService:RemoveComponent( cellId, "BuildingBlockerLayerComponent" )
    --
    --    ConsoleService:ExecuteCommand("dump_entity " .. tostring(cellId))
    --end
    --
    ----QueueEvent( "DissolveEntityRequest", entity, 0.5, 0 )
end

return eraser_rocks_tool
