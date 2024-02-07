local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'eraser_flora_tool' ( tool )

function eraser_flora_tool:__init()
    tool.__init(self,self)
end

function eraser_flora_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_eraser_flora_tool", self.entity)
end

function eraser_flora_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function eraser_flora_tool:FindEntitiesToSelect( selectorComponent )

    local predicate = {

        signature="TypeComponent",

        filter = function(entity)

            if ( EntityService:CompareType( entity, "flora" ) ) then
                return true
            end

            return false
        end
    };

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

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

        if ( not EntityService:CompareType( entity, "flora" ) ) then
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

function eraser_flora_tool:AddedToSelection( entity )
end

function eraser_flora_tool:RemovedFromSelection( entity )
end

function eraser_flora_tool:OnRotate()
end

function eraser_flora_tool:OnActivateEntity( entity )

    EntityService:RemoveComponent( entity, "VegetationLifecycleEnablerComponent" )

    EntityService:RequestDestroyPattern( entity, "default" )

    QueueEvent( "DissolveEntityRequest", entity, 2.0, 0 )
end

return eraser_flora_tool
